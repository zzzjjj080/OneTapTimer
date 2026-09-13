import SwiftUI
import OneTapTimerCore
import OneTapTimerUI

struct PhoneRootView: View {
    @Environment(Runner.self) private var runner

    var body: some View {
        ZStack(alignment: .top) {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: runner.engine.isFinished || runner.engine.isPaused)) { t in
                DrainFace(engine: runner.engine, now: t.date, theme: runner.themeHex, metrics: .phone)
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { runner.startAgain() }
            .accessibilityIdentifier("face")

            // 押せる余白（12pt）ぶん外へ寄せて置き、見た目の位置は変えない
            SettingButton(skin: Skin.of(runner.engine, at: .now, theme: runner.themeHex),
                          size: 66, hitPadding: 12) {
                runner.openSettings()
            }
            .padding(.top, 8 - 12)

            if !runner.engine.isFinished {
                PauseButton(skin: Skin.of(runner.engine, at: .now, theme: runner.themeHex),
                            isPaused: runner.engine.isPaused, size: 60, hitPadding: 12) {
                    runner.togglePause()
                }
                .padding(.leading, 20 - 12)
                .padding(.top, 8 + (66 - 60) / 2 - 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sheet(isPresented: Binding(get: { runner.screen == .settings },
                                    set: { if !$0 { runner.closeSettings() } })) {
            PhoneSettingsSheet()
                .environment(runner)
                .presentationDetents([.medium, .large])
                .presentationBackground(Color(hex: PaletteHex.ground))
        }
        .task {
            if !skipsPermissionForChecking {
                UNUserNotificationCenter.current().delegate = runner.gate
                await runner.notifier.requestPermission()
            }
            #if DEBUG
            // activate() より後に効かせる（先に入れても新しいタイマーで上書きされる）
            if let spec = ProcessInfo.processInfo.environment["OTT_STATE"] {
                try? await Task.sleep(for: .milliseconds(400))
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
