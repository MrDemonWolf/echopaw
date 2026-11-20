import AppKit
import SwiftUI

struct SetupGuide: View {
    static let windowID = "setup-guide"

    private enum Step: Int, CaseIterable {
        case rehearsal, obs, accounts

        var title: String {
            switch self {
            case .rehearsal: "Try your mascot"
            case .obs: "Check your OBS output"
            case .accounts: "Set up voice providers"
            }
        }

        var nextTitle: String {
            switch self {
            case .rehearsal: "Continue"
            case .obs: "I can see and hear it"
            case .accounts: "Done"
            }
        }
    }

    let session: PreviewSession
    @AppStorage("setupGuideStep") private var step = Step.rehearsal
    @AppStorage("preferencesTab") private var preferencesTab = "audio"
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openSettings) private var openSettings

    private var progressLabel: String { "Step \(step.rawValue + 1) of \(Step.allCases.count)" }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: EP.space4) {
                    Text(progressLabel)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(step.title)
                        .font(BrandType.heading)
                        .accessibilityAddTraits(.isHeader)
                    switch step {
                    case .rehearsal: rehearsal
                    case .obs: obs
                    case .accounts: accounts
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EP.space6)
            }
            .scrollBounceBehavior(.basedOnSize)

            Divider()
            HStack(spacing: EP.space3) {
                if step != .accounts {
                    Button("Set up later", action: closeGuide)
                }
                Spacer()
                if let previous = Step(rawValue: step.rawValue - 1) {
                    Button("Back") { step = previous }
                }
                if step == .obs {
                    Button("Skip OBS") { step = .accounts }
                }
                Button(step.nextTitle) {
                    if let next = Step(rawValue: step.rawValue + 1) {
                        step = next
                    } else {
                        step = .rehearsal
                        closeGuide()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(EP.space4)
        }
        .frame(minWidth: 500, minHeight: 370)
        .onChange(of: step) { _, _ in
            AccessibilityNotification.Announcement("\(progressLabel). \(step.title)").post()
        }
    }

    private var rehearsal: some View {
        VStack(alignment: .leading, spacing: EP.space4) {
            Text("Choose your audio output, then hear the wolf’s short sample line. Your mascot moves as it speaks. This step works offline.")
                .font(BrandType.body)
            HStack(spacing: EP.space6) {
                PreviewSurface(session: session)
                    .frame(width: 132, height: 152)
                VStack(alignment: .leading, spacing: EP.space3) {
                    DevicePicker(audio: session.audio)
                    testSoundButton
                    playbackHelp
                    if session.character == nil {
                        Button("Use starter wolf", action: session.useSample)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text("Use a local OBS test scene if EchoPaw is already being captured.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var obs: some View {
        VStack(alignment: .leading, spacing: EP.space4) {
            Text("Use a local OBS test scene. In macOS Screen Capture, choose Window Capture and select EchoPaw Mascot.")
                .font(BrandType.body)
            Button(session.captureActionTitle, systemImage: "macwindow.on.rectangle", action: session.toggleCapture)
                .disabled(session.character == nil || session.isStopped)
            Text("Add a macOS Audio Capture source for EchoPaw. Use a single source for the mascot’s audio to avoid doubling it.")
                .font(BrandType.body)
            Text("Record a short test. Check that you see the mascot, its mixer meter moves, and you hear the sample line once.")
                .font(BrandType.body)
            testSoundButton
            playbackHelp
            Link("OBS audio capture guide", destination: URL(string: "https://obsproject.com/kb/macos-desktop-audio-capture-guide")!)
        }
    }

    private var accounts: some View {
        VStack(alignment: .leading, spacing: EP.space4) {
            Text("You can keep rehearsing offline. Add provider keys when you’re ready to test conversation features as they become available.")
                .font(BrandType.body)
            VStack(alignment: .leading, spacing: EP.space2) {
                Text("API keys").font(.headline)
                Text("Test your OpenAI or ElevenLabs key before saving it to this Mac’s Keychain.")
                    .foregroundStyle(.secondary)
                Button("Open API Keys settings") { showSettings("privacy") }
            }
        }
    }

    private var testSoundButton: some View {
        Button(session.audio.isPlaying ? "Stop test" : "Play sample line",
               systemImage: session.audio.isPlaying ? "stop.fill" : "play.fill",
               action: session.toggleTestOutput)
            .disabled(!session.canControlTestOutput)
    }

    @ViewBuilder
    private var playbackHelp: some View {
        if session.isStopped {
            Button("Resume preview", action: session.resume)
        } else if session.isMuted {
            Button("Unmute speech", action: session.toggleMute)
        } else if let error = session.audio.lastError {
            Label(error, systemImage: "exclamationmark.triangle").font(.callout)
        } else if !session.audio.isSelectedOutputAvailable {
            Label("Output unavailable", systemImage: "speaker.slash").font(.callout)
            if step == .obs {
                Button("Choose audio output") { showSettings("audio") }
            }
        }
    }

    private func showSettings(_ tab: String) {
        preferencesTab = tab
        openSettings()
    }

    private func closeGuide() {
        dismissWindow(id: Self.windowID)
    }
}

struct OfferSetupGuide: ViewModifier {
    @AppStorage("setupGuideOffered") private var offered = false
    @Environment(\.openWindow) private var openWindow

    func body(content: Content) -> some View {
        content.task {
            guard !offered else { return }
            #if DEBUG
            let environment = ProcessInfo.processInfo.environment
            guard environment["ECHOPAW_CONNECTION_TEST_ID"] == nil,
                  environment["XCTestConfigurationFilePath"] == nil else { return }
            #endif
            offered = true
            openWindow(id: SetupGuide.windowID)
        }
    }
}

struct OpenSetupGuideButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Setup Guide") {
            openWindow(id: SetupGuide.windowID)
            NSApp.activate()
        }
    }
}
