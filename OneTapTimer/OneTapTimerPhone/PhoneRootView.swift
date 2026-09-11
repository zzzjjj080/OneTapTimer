import SwiftUI
import OneTapTimerCore
import OneTapTimerUI

struct PhoneRootView: View {
    @Environment(Runner.self) private var runner

    var body: some View {
        ZStack(alignment: .top) {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: runner.engine.isFinished)) { t in
                DrainFace(engine: runner.engine, now: t.date, theme: runner.themeHex, metrics: .phone)
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { runner.startAgain() }
            .accessibilityIdentifier("face")

            SettingButton(skin: Skin.of(runner.engine, at: .now, theme: runner.themeHex), size: 56) {
                runner.openSettings()
            }
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
