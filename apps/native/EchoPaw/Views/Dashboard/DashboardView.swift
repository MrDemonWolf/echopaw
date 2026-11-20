import SwiftUI

private enum Destination: String, CaseIterable {
    case dashboard = "Dashboard"
    case character = "Character"
    var symbol: String { self == .dashboard ? "rectangle.grid.2x2" : "pawprint" }
}

struct DashboardView: View {
    let session: PreviewSession
    let mic: LocalMicrophone
    @SceneStorage("workspaceDestination") private var destination = Destination.dashboard
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
                List(Destination.allCases, id: \.self, selection: $destination) { page in
                    Label(page.rawValue, systemImage: page.symbol).tag(page)
                }
                .listStyle(.sidebar)
                Divider()
                SettingsLink { Label("Settings", systemImage: "gearshape") }
                    .padding(EP.space4)
            }
            .navigationSplitViewColumnWidth(min: 158, ideal: EP.sidebarWidth, max: 230)
        } detail: {
            Group {
                switch destination {
                case .dashboard: SessionDashboard(session: session, mic: mic)
                case .character: CharacterView(session: session, inspector: $inspector)
                }
            }
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
}

private struct SessionDashboard: View {
    let session: PreviewSession
    let mic: LocalMicrophone

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: EP.space4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(session.character?.name ?? "Mascot preview")
                            .font(BrandType.heading)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Label("Offline preview", systemImage: "circle.dotted")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    PreviewSurface(session: session)
                        .frame(height: max(EP.stageMinHeight, min(geometry.size.height * 0.46, 470)))
                    SessionControls(session: session)
                    Divider()
                    AudioDestination(session: session)
                    Divider()
                    if !session.recentActivity.isEmpty && geometry.size.width > 590 {
                        HStack(alignment: .top, spacing: EP.space6) {
                            ConnectionsView()
                            Divider()
                            activity
                        }
                    } else {
                        ConnectionsView()
                        if !session.recentActivity.isEmpty { Divider(); activity }
                    }
                }
                .padding(EP.space6)
                .frame(maxWidth: 1040)
                .frame(maxWidth: .infinity)
            }
        }
    }
    private var activity: some View {
        VStack(alignment: .leading, spacing: EP.space2) {
            Text("Recent activity").font(.headline).accessibilityAddTraits(.isHeader)
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
        ViewThatFits(in: .horizontal) {
            HStack(spacing: EP.space3) {
                actions
                Spacer()
                state
            }
            VStack(alignment: .leading, spacing: EP.space2) {
                actions
                state
            }
        }
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: EP.space2) {
                playback
                ai
            }
            .fixedSize(horizontal: true, vertical: false)
            VStack(alignment: .leading, spacing: EP.space2) {
                playback
                ai
            }
        }
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

    private var ai: some View {
        Button(session.isAIPaused ? "Resume AI" : "Pause AI",
               systemImage: session.isAIPaused ? "sparkles" : "pause.circle", action: session.toggleAIPause)
            .disabled(session.isStopped)
            .help("Allow or pause automatic responses when live reactions are available.")
    }

    private var state: some View {
        Label(session.playbackLabel, systemImage: session.isStopped ? "stop.circle" : "waveform")
            .font(.callout).fixedSize(horizontal: true, vertical: false)
    }
}

private struct AudioDestination: View {
    @Environment(\.openSettings) private var openSettings
    @AppStorage("preferencesTab") private var preferencesTab = "audio"
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
            Spacer()
            Button("Choose output…") { preferencesTab = "audio"; openSettings() }
                .accessibilityLabel("Open audio settings")
        }
    }
}

struct ConnectionsView: View {
    @Environment(ProviderKeys.self) private var keys
    @Environment(TwitchConnections.self) private var twitch
    @Environment(\.openSettings) private var openSettings
    @AppStorage("preferencesTab") private var preferencesTab = "audio"

    var body: some View {
        VStack(alignment: .leading, spacing: EP.space2) {
            HStack {
                Text("Connections").font(.headline).accessibilityAddTraits(.isHeader)
                Spacer()
                Menu("Set up") {
                    Button("API keys…") { showSettings("privacy") }
                    Button("Twitch accounts…") { showSettings("twitch") }
                }
                .fixedSize()
                .accessibilityLabel("Set up connections")
            }
            ForEach(TwitchRole.allCases, id: \.self) { role in
                StatusRow(title: "Twitch " + role.rawValue, symbol: "bubble.left.and.bubble.right", value: twitch.state(for: role).summary)
            }
            ForEach(KeyProvider.allCases, id: \.self) { provider in
                StatusRow(title: provider.title, symbol: provider == .openAI ? "sparkles" : "waveform", value: keys.status(for: provider))
            }
        }
    }

    private func showSettings(_ tab: String) {
        preferencesTab = tab
        openSettings()
    }
}
