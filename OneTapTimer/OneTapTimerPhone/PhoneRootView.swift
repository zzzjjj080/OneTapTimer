import SwiftUI
import OneTapTimerCore
import OneTapTimerUI

struct PhoneRootView: View {
    @Environment(Runner.self) private var runner

    var body: some View {
        ZStack(alignment: .topLeading) {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: runner.engine.isFinished)) { t in
                DrainFace(engine: runner.engine, now: t.date, metrics: .phone)
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { runner.restart() }
            .onLongPressGesture(minimumDuration: 0.7) { runner.cancel() }
            .accessibilityIdentifier("face")

            GearButton(skin: Skin.of(runner.engine, at: .now), size: 48) {
                runner.openSettings()
            }
            .padding(.leading, 20)
            .padding(.top, 8)
        }
        .sheet(isPresented: Binding(get: { runner.screen == .settings },
                                    set: { if !$0 { runner.closeSettings() } })) {
            PhoneSettingsSheet()
                .environment(runner)
                .presentationDetents([.medium, .large])
                .presentationBackground(Color(hex: PaletteHex.ground))
        }
        .task {
            UNUserNotificationCenter.current().delegate = runner.gate
            // シミュレータで画面を撮るときは、許可ダイアログを出させない（合成タップが届かない。引き継ぎ書 4-24）
            if !skipsPermissionForChecking { await runner.notifier.requestPermission() }
            #if DEBUG
            if let spec = ProcessInfo.processInfo.environment["OTT_STATE"] {
                runner.applyDebugState(spec)
            }
            #endif
        }
        .statusBarHidden(false)
        .preferredColorScheme(.dark)
    }

    private var skipsPermissionForChecking: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["OTT_SKIP_PERMISSION"] == "1"
        #else
        false
        #endif
    }
}

import UserNotifications
