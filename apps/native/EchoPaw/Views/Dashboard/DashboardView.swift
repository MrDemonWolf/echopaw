import SwiftUI

enum WorkspacePage: String {
    case dashboard = "Dashboard"
    case character = "Character"
    case audio = "Audio & capture"
    case microphone = "Microphone"
    case apiKeys = "API Keys"
    case twitch = "Twitch"
    case general = "General"

    static let settings: [Self] = [.audio, .microphone, .apiKeys, .twitch, .general]

    var symbol: String {
        switch self {
        case .dashboard: "rectangle.grid.2x2"
        case .character: "pawprint"
        case .audio: "speaker.wave.2"
        case .microphone: "mic"
        case .apiKeys: "key"
        case .twitch: "bubble.left.and.bubble.right"
        case .general: "gearshape"
        }
    }
}

struct DashboardView: View {
    static let windowID = "dashboard"

    let session: PreviewSession
    let mic: LocalMicrophone
    @Binding var destination: WorkspacePage
    @Environment(\.openWindow) private var openWindow
    @SceneStorage("characterInspector") private var inspector = true

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                Label {
                    Text("EchoPaw").font(.custom(EP.headingFamily, size: EP.brandSize, relativeTo: .headline).weight(.semibold)).lineLimit(1)
                } icon: {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable().frame(width: 26, height: 26).accessibilityHidden(true)
                }
                .padding(EP.space4)
                List(selection: $destination) {
                    pageLink(.dashboard)
                    pageLink(.character)
                    Section("Settings") {
                        ForEach(WorkspacePage.settings, id: \.self) { page in
                            pageLink(page)
                        }
                    }
                }
                .listStyle(.sidebar)
                Divider()
                Button("Setup Guide", systemImage: "checklist") { openWindow(id: SetupGuide.windowID) }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EP.space4)
            }
            .navigationSplitViewColumnWidth(min: 158, ideal: EP.sidebarWidth, max: 230)
        } detail: {
            Group {
                switch destination {
                case .dashboard:
                    SessionDashboard(session: session) { destination = .audio }
                case .character: CharacterView(session: session, inspector: $inspector)
                case .audio: AudioPreferences(session: session)
                case .microphone:
                    Form { MicrophonePreferences(mic: mic, stopped: session.isStopped) }
                case .apiKeys: ProviderPreferences()
                case .twitch: TwitchPreferences()
                case .general: GeneralPreferences()
                }
            }
            .formStyle(.grouped)
            .navigationTitle(destination.rawValue)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if mic.state != .off {
                        Button(mic.state == .starting ? "Cancel listening" : "Stop listening",
                               systemImage: "mic.fill", action: mic.stop)
                            .labelStyle(.titleAndIcon)
                    }
                    Button(session.captureActionTitle, systemImage: "macwindow.on.rectangle", action: session.toggleCapture)
                        .help(session.captureActionTitle + " (⇧⌘O)")
                        .disabled(session.character == nil || session.isStopped)
                    Button(session.isStopped ? "Resume preview" : "Emergency stop",
                           systemImage: session.isStopped ? "play.circle" : "stop.circle") {
                        if session.isStopped { session.resume() } else { session.emergencyStop() }
                    }
                    .labelStyle(.titleAndIcon)
                    .help(session.isStopped ? "Restore controls and keep speech muted" : "Stop the session immediately (⇧⌘K)")
                }
            }
        }
        .frame(minWidth: EP.workspaceMinWidth, minHeight: EP.workspaceMinHeight)
        .onAppear { session.setPreviewVisible(true) }
        .onDisappear { session.setPreviewVisible(false) }
        .onChange(of: session.isStopped) { _, stopped in
            if stopped { AccessibilityNotification.Announcement("Stopped. Resume preview when ready.").post() }
        }
    }

    private func pageLink(_ page: WorkspacePage) -> some View {
        Label(page.rawValue, systemImage: page.symbol).tag(page)
    }
}

private struct SessionDashboard: View {
    let session: PreviewSession
    let chooseOutput: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: EP.space1) {
                    Text(session.character?.name ?? "Mascot preview")
                        .font(BrandType.heading)
                        .accessibilityAddTraits(.isHeader)
                    Label(session.isStopped ? "Rehearsal stopped" : "Offline rehearsal",
                          systemImage: session.isStopped ? "stop.circle" : "headphones")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Spacer(minLength: EP.space2)
                Button("Choose output…", action: chooseOutput)
                    .accessibilityLabel("Open audio settings")
            }
            .padding(.horizontal, EP.space4)
            .padding(.vertical, EP.space2)

            PreviewSurface(session: session)

            Divider()
            ViewThatFits(in: .horizontal) {
                HStack(spacing: EP.space4) {
                    SessionControls(session: session).fixedSize()
                    Divider()
                    AudioDestination(session: session)
                }
                VStack(spacing: EP.space2) {
                    SessionControls(session: session)
                    AudioDestination(session: session)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(EP.space3)
            if !session.recentActivity.isEmpty {
                DisclosureGroup("Recent activity") {
                    activity
                }
                .padding(.horizontal, EP.space4)
                .padding(.bottom, EP.space2)
            }
        }
    }

    private var activity: some View {
        VStack(alignment: .leading, spacing: EP.space2) {
            ForEach(Array(session.recentActivity.prefix(3).enumerated()), id: \.offset) { _, event in
                Label(event, systemImage: "clock").font(.callout).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

}

struct SessionControls: View {
    let session: PreviewSession

    var body: some View {
        VStack(spacing: EP.space2) {
            playback
                .controlSize(.large)
            state
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var playback: some View {
        HStack(spacing: EP.space2) {
            TalkingButton(session: session)
            Button(session.isMuted ? "Unmute speech" : "Mute speech",
                   systemImage: session.isMuted ? "speaker.slash" : "speaker.wave.2",
                   action: session.toggleMute)
                .disabled(session.isStopped)
        }
    }

    private var state: some View {
        Label(session.playbackLabel, systemImage: session.isStopped ? "stop.circle" : "waveform")
            .font(.callout).fixedSize(horizontal: true, vertical: false)
    }
}

private struct AudioDestination: View {
    let session: PreviewSession

    var body: some View {
        HStack(spacing: EP.space3) {
            Image(systemName: "hifispeaker").font(.title2).foregroundStyle(.secondary).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Audio output").font(.headline)
                Text(session.audio.devices.first { $0.uid == session.audio.selectedDeviceUID }?.name
                     ?? (session.audio.selectedDeviceUID == nil ? "System Default" : "Device unavailable"))
                    .font(BrandType.body).foregroundStyle(.secondary)
                if let error = session.audio.lastError {
                    Label(error, systemImage: "exclamationmark.triangle").font(.callout)
                }
            }
            Spacer(minLength: 0)
        }
    }
}
