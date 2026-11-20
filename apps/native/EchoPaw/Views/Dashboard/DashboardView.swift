import SwiftUI

private enum Destination: String, CaseIterable {
    case dashboard = "Dashboard"
    case character = "Character"
    var symbol: String { self == .dashboard ? "rectangle.grid.2x2" : "pawprint" }
}

struct DashboardView: View {
    let session: PreviewSession
    @SceneStorage("workspaceDestination") private var destination = Destination.dashboard
    @SceneStorage("characterInspector") private var inspector = true

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                Label {
                    Text("EchoPaw").font(.custom("Montserrat", size: 17, relativeTo: .headline).weight(.semibold)).lineLimit(1)
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
                case .dashboard: SessionDashboard(session: session)
                case .character: CharacterView(session: session, inspector: $inspector)
                }
            }
            .navigationTitle(destination.rawValue)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(session.captureActionTitle, systemImage: "macwindow.on.rectangle", action: session.toggleCapture)
                        .help(session.captureActionTitle + " (⇧⌘O)")
                        .disabled(session.character == nil)
                    Button(session.isStopped ? "Resume preview" : "Emergency stop",
                           systemImage: session.isStopped ? "play.circle" : "stop.circle") {
                        if session.isStopped { session.resume() } else { session.emergencyStop() }
                    }
                    .labelStyle(.titleAndIcon)
                    .help(session.isStopped ? "Restore controls and keep speech muted" : "Stop the session immediately (⇧⌘K)")
                }
            }
        }
        .frame(minWidth: 570, minHeight: 440)
        .onChange(of: session.isStopped) { _, stopped in
            if stopped { AccessibilityNotification.Announcement("Stopped. Resume preview when ready.").post() }
        }
    }
}

private struct SessionDashboard: View {
    let session: PreviewSession

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
                    ConnectionsView()
                }
                .padding(EP.space6)
                .frame(maxWidth: 1040)
                .frame(maxWidth: .infinity)
            }
        }
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
            Image(systemName: "hifispeaker").font(.title2).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Audio output").font(.headline)
                Text(session.audio.devices.first { $0.uid == session.audio.selectedDeviceUID }?.name
                     ?? (session.audio.selectedDeviceUID == nil ? "System Default" : "Device unavailable"))
                    .font(BrandType.body).foregroundStyle(.secondary).textSelection(.enabled)
                if let error = session.audio.lastError {
                    Label(error, systemImage: "exclamationmark.triangle").font(.callout)
                }
            }
            Spacer()
            SettingsLink { Text("Settings…") }
                .accessibilityLabel("Open audio settings")
        }
    }
}

struct ConnectionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: EP.space2) {
            Text("Connections").font(.headline).accessibilityAddTraits(.isHeader)
            StatusRow(title: "Twitch", symbol: "bubble.left.and.bubble.right", value: "Not connected")
            StatusRow(title: "OpenAI", symbol: "sparkles", value: "Not connected")
            StatusRow(title: "ElevenLabs", symbol: "waveform", value: "Not connected")
        }
    }
}
