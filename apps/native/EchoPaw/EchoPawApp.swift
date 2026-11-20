import AppKit
import SwiftUI

@main
struct EchoPawApp: App {
    @AppStorage("windowAppearance") private var appearance = "system"
    private var scheme: ColorScheme? {
        switch appearance { case "light": .light; case "dark": .dark; default: nil }
    }
    @State private var session: PreviewSession
    @State private var mic: LocalMicrophone
    @State private var providerKeys: ProviderKeys
    @State private var twitch: TwitchConnections

    init() {
        BrandType.registerFonts()
        let session = PreviewSession()
        let mic = LocalMicrophone { [weak session] in session?.setMicrophoneActivity($0) }
        session.onEmergencyStop = { [weak mic] in mic?.stop() }
        session.onPlaybackChange = { [weak mic] in mic?.setPlaying($0) }
        _session = State(initialValue: session)
        _mic = State(initialValue: mic)
        var service: String?
        var defaults = UserDefaults.standard
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        let testID = environment["ECHOPAW_CONNECTION_TEST_ID"].flatMap(UUID.init(uuidString:))
            ?? (environment["XCTestConfigurationFilePath"] == nil ? nil : UUID())
        if let testID {
            let suite = "com.mrdemonwolf.echopaw.tests." + testID.uuidString
            service = suite
            defaults = UserDefaults(suiteName: suite)!
        }
        #endif
        let store = KeychainSecretStore(service: service)
        #if DEBUG
        let verification = service == nil
            ? ProviderKeyVerification()
            : ProviderKeyVerification { request in
                request.value(forHTTPHeaderField: "Authorization") == "Bearer ep-test-rejected" ? 401 : 200
            }
        #else
        let verification = ProviderKeyVerification()
        #endif
        let keys = ProviderKeys(store: store, verification: verification)
        let twitch = TwitchConnections(store: store, defaults: defaults)
        _providerKeys = State(initialValue: keys)
        _twitch = State(initialValue: twitch)
        twitch.restore()
        Task { await keys.reload() }
    }

    var body: some Scene {
        Window("EchoPaw", id: "dashboard") {
            DashboardView(session: session, mic: mic).preferredColorScheme(scheme)
                .modifier(OfferSetupGuide())
                .windowFullScreenBehavior(.disabled)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 940, height: 710)
        .defaultLaunchBehavior(.presented)
        .commands {
            CommandGroup(after: .help) {
                OpenSetupGuideButton()
            }
            CommandGroup(after: .windowList) {
                Button(session.captureActionTitle, action: session.toggleCapture)
                    .keyboardShortcut("o", modifiers: [.command, .shift])
                    .disabled(session.character == nil || session.isStopped)
                #if DEBUG
                OpenGalleryButton()
                #endif
            }
            CommandMenu("Character") {
                Button(session.testOutputActionTitle, action: session.toggleTestOutput)
                    .keyboardShortcut("t", modifiers: [.command, .shift])
                    .disabled(!session.canControlTestOutput)
                Button("Preview blink", action: session.previewBlink)
                    .keyboardShortcut("b", modifiers: [.command, .shift])
                    .disabled(!session.canPreviewBlink)
            }
            CommandMenu("Session") {
                Button(session.isMuted ? "Unmute speech" : "Mute speech", action: session.toggleMute)
                    .keyboardShortcut("m", modifiers: [.command, .shift])
                    .disabled(session.isStopped)
                Divider()
                Button("Emergency stop", action: session.emergencyStop)
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                    .disabled(session.isStopped)
                Button("Resume preview", action: session.resume)
                    .disabled(!session.isStopped)
            }
        }

        Window("Setup Guide", id: SetupGuide.windowID) {
            SetupGuide(session: session)
                .preferredColorScheme(scheme)
                .windowFullScreenBehavior(.disabled)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 560, height: 420)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Settings {
            PreferencesView(session: session, mic: mic).preferredColorScheme(scheme)
                .environment(providerKeys)
                .environment(twitch)
                .windowFullScreenBehavior(.disabled)
        }

        #if DEBUG
        Window("Component Gallery", id: "component-gallery") {
            ComponentGallery(session: session).preferredColorScheme(scheme)
                .windowFullScreenBehavior(.disabled)
        }
        .windowResizability(.contentMinSize)
        .defaultLaunchBehavior(.suppressed)
        #endif

        MenuBarExtra("EchoPaw", systemImage: session.isStopped ? "stop.circle" : (mic.state == .off ? "waveform" : "mic.fill")) {
            if mic.state != .off { Button("Stop microphone listening", action: mic.stop) }
            PreviewMenu(session: session)
        }
    }
}

private struct PreviewMenu: View {
    @Environment(\.openWindow) private var openWindow
    let session: PreviewSession

    var body: some View {
        Button("Open EchoPaw") {
            openWindow(id: "dashboard")
            NSApp.activate()
        }
        OpenSetupGuideButton()
        Button(session.captureActionTitle, action: session.toggleCapture)
            .disabled(session.character == nil || session.isStopped)
        Divider()
        Button(session.testOutputActionTitle, action: session.toggleTestOutput)
            .disabled(!session.canControlTestOutput)
        Button(session.isMuted ? "Unmute speech" : "Mute speech", action: session.toggleMute)
            .disabled(session.isStopped)
        if session.isStopped {
            Button("Resume preview", action: session.resume)
        } else {
            Button("Emergency stop", action: session.emergencyStop)
        }
        Divider()
        Button("Quit EchoPaw") { NSApp.terminate(nil) }
    }
}

#if DEBUG
private struct OpenGalleryButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View { Button("Show component gallery") { openWindow(id: "component-gallery") } }
}
#endif
