import Foundation
import Observation
import StoreKit

/// 「コーヒーを奢る」ボタンの窓口。
///
/// 消耗型（Consumable）なので何度でも送れる。送ってもアプリの機能は変わらない。
/// 累計の杯数だけ端末内に残す。**StoreKitは消耗型を復元しないので、
/// 機種変更や再インストールで杯数は0に戻る。** UIには「この端末で」と書くこと。
///
/// 正本は `~/Claude/shared/TipJar/TipJar.swift`。ここでは**公開の印を付け、
/// 失敗の文言を画面側に渡す形**に変えてある（16言語なので、文字列は画面側のカタログで訳す）。
///
/// 使い方:
/// ```swift
/// @State private var tipJar = TipJar(productID: TipJar.oneTapTimer)
/// ```
@MainActor
@Observable
public final class TipJar {
    public enum State: Equatable {
        case idle
        case loading
        /// 製品が取れなかった。App Store Connect側が未登録か、通信できていない
        case unavailable
        case purchasing
        case thanks
        case failed(String)
    }

    /// このアプリの製品ID。App Store Connect 側と1文字でも違うと `unavailable` になる
    public static let oneTapTimer = "com.zzzjjj080.OneTapTimer.coffee"

    /// App Store Connect で作る製品ID。向こうと1文字でも違うと `unavailable` になる
    public let productID: String

    public private(set) var product: Product?
    public private(set) var state: State = .idle

    /// この端末での累計杯数
    public private(set) var cups: Int

    private let defaults: UserDefaults
    private let cupsKey = "tipjar.cups"
    private var updates: Task<Void, Never>?

    public init(productID: String, defaults: UserDefaults = .standard) {
        self.productID = productID
        self.defaults = defaults
        self.cups = defaults.integer(forKey: cupsKey)
    }

    /// 表示する金額はStoreKitが返すものをそのまま使う。
    /// 国によって価格も通貨も変わるため、アプリ側で「¥200」と決め打ちしてはいけない
    public var displayPrice: String? { product?.displayPrice }

    /// 画面が出るタイミングで呼ぶ。2回目以降は何もしない
    public func load() async {
        startListening()
        await finishUnfinished()

        guard product == nil, state != .loading else { return }
        state = .loading
        do {
            product = try await Product.products(for: [productID]).first
            state = product == nil ? .unavailable : .idle
        } catch {
            state = .unavailable
        }
    }

    public func tip() async {
        guard let product else { return }
        state = .purchasing
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    state = .failed("unverified")
                    return
                }
                await record(transaction)
                state = .thanks
            case .userCancelled:
                state = .idle
            case .pending:
                // ファミリー共有の購入承認待ちなど。完了は Transaction.updates から後で届く
                state = .idle
            @unknown default:
                state = .idle
            }
        } catch {
            state = .failed("failed")
        }
    }

    public func dismissThanks() {
        state = .idle
    }

    /// 画面を閉じるときなどに呼ぶ。呼ばなくても害はない
    public func stopListening() {
        updates?.cancel()
        updates = nil
    }

    // MARK: - 取引の後始末

    /// 承認待ちだった購入や、アプリが落ちて finish できなかった分がここに届く
    private func startListening() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await self?.record(transaction)
            }
        }
    }

    /// 前回 finish しそこねた取引を拾う。放置すると毎回 updates に流れ続ける
    private func finishUnfinished() async {
        for await result in Transaction.unfinished {
            guard case .verified(let transaction) = result else { continue }
            await record(transaction)
        }
    }

    /// 消耗型は finish を呼ばないと未処理の取引として残り続ける
    private func record(_ transaction: Transaction) async {
        if transaction.productID == productID, transaction.revocationDate == nil {
            cups += 1
            defaults.set(cups, forKey: cupsKey)
        }
        await transaction.finish()
    }
}
