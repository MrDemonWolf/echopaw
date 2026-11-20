import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {
    let session: PreviewSession
    @SceneStorage("showsPreviewSetup") private var showsSetup = true
    @State private var choosingCharacter = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            MascotStage(session: session)
            transport
        }
        .padding(20)
        .frame(minWidth: 390, minHeight: 414)
        .inspector(isPresented: $showsSetup) {
            PreviewSetup(session: session) { choosingCharacter = true }
                .inspectorColumnWidth(min: 252, ideal: 286, max: 360)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(session.captureActionTitle, systemImage: "rectangle.on.rectangle",
                       action: session.toggleCapture)
                    .labelStyle(.iconOnly)
                    .help("\(session.captureActionTitle) (⇧⌘O)")
                    .disabled(session.character == nil)

                Button(session.isStopped ? "Resume preview" : "Emergency stop",
                       systemImage: session.isStopped ? "play" : "stop.circle") {
                    if session.isStopped { session.resume() } else { session.emergencyStop() }
                }
                .labelStyle(.titleAndIcon)
                .help(session.isStopped ? "Restore preview controls" : "Emergency stop (⇧⌘K)")

                Button(showsSetup ? "Hide setup inspector" : "Show setup inspector", systemImage: "sidebar.trailing") {
                    showsSetup.toggle()
                }
                .labelStyle(.iconOnly)
                .help(showsSetup ? "Hide setup inspector" : "Show setup inspector")
            }
        }
        .fileImporter(isPresented: $choosingCharacter, allowedContentTypes: [.folder]) {
            session.importCharacter($0)
        }
        .onChange(of: session.isStopped) { _, stopped in
            if stopped {
                AccessibilityNotification.Announcement("Stopped. Resume preview when ready.").post()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Mascot preview")
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text(session.character?.name ?? "No character loaded")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Label("Offline preview", systemImage: "circle.dotted")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize()
        }
    }

    private var transport: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                playbackButtons
                Spacer(minLength: 0)
                playbackStatus
            }
            VStack(alignment: .leading, spacing: 8) {
                playbackButtons
                playbackStatus
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var playbackButtons: some View {
        HStack(spacing: 8) {
            Button(session.testOutputActionTitle,
                   systemImage: session.audio.isPlaying ? "stop.fill" : "play.fill",
                   action: session.toggleTestOutput)
                .buttonStyle(.borderedProminent)
                .disabled(!session.canControlTestOutput)

            Button(session.isMuted ? "Unmute speech" : "Mute speech",
                   systemImage: session.isMuted ? "speaker.slash" : "speaker.wave.2",
                   action: session.toggleMute)
                .disabled(session.isStopped)
        }
    }

    private var playbackStatus: some View {
        HStack(spacing: 8) {
            Label(session.playbackLabel, systemImage: playbackSymbol)
                .font(.callout)
                .foregroundStyle(.secondary)
            if !showsSetup && (!session.audio.isSelectedOutputAvailable || session.audio.lastError != nil) {
                Button("Choose output") { showsSetup = true }
            }
        }
    }

    private var playbackSymbol: String {
        if session.isStopped { return "stop.circle.fill" }
        if !session.audio.isSelectedOutputAvailable { return "exclamationmark.circle" }
        if session.isMuted { return "speaker.slash.fill" }
        return session.audio.isPlaying ? "waveform" : "waveform.path"
    }
}

private struct MascotStage: View {
    let session: PreviewSession
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            RadialGradient(colors: backdrop, center: .init(x: 0.5, y: 0.42), startRadius: 8, endRadius: 385)
                .accessibilityHidden(true)
            if let image = session.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.30 : 0.16), radius: 18, y: 12)
                    .accessibilityLabel(session.audio.isPlaying ? "Talking mascot" : "Idle mascot")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(.rect(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(.quaternary) }
    }

    private var backdrop: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 13.0 / 255, green: 77.0 / 255, blue: 140.0 / 255),
                Color(red: 10.0 / 255, green: 22.0 / 255, blue: 51.0 / 255),
            ]
        }
        return [
            Color(red: 237.0 / 255, green: 244.0 / 255, blue: 251.0 / 255),
            Color(red: 172.0 / 255, green: 203.0 / 255, blue: 232.0 / 255),
        ]
    }
}

private struct PreviewSetup: View {
    @Bindable var session: PreviewSession
    let importCharacter: () -> Void

    var body: some View {
        @Bindable var audio = session.audio
        Form {
            Section("Character") {
                HStack {
                    Button("Import character…", action: importCharacter)
                    Button("Use sample", action: session.useSample)
                }
                if session.hasBlinkFrames {
                    Toggle("Auto-blink", isOn: $session.blinksAutomatically)
                        .disabled(session.reducesMotion)
                    if session.reducesMotion {
                        Text("Paused by Reduce Motion.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                if let error = session.characterError {
                    errorMessage(error)
                }
            }

            Section("Audio output") {
                Picker("Device", selection: Binding(
                    get: { audio.selectedDeviceUID },
                    set: { audio.selectOutput($0) }
                )) {
                    Text("System Default").tag(nil as String?)
                    ForEach(audio.devices) { device in
                        Text(device.name).tag(Optional(device.uid))
                    }
                    if let selected = audio.selectedDeviceUID,
                       !audio.devices.contains(where: { $0.uid == selected }) {
                        Text("Unavailable device").tag(Optional(selected))
                    }
                }
                Slider(value: $audio.volume, in: 0...1) { Text("Volume") }
                if let error = audio.lastError {
                    errorMessage(error)
                }
            }

            Section("OBS capture") {
                Toggle("Use green screen", isOn: $session.usesChromaKey)
                if session.isCaptureVisible {
                    Text("In OBS Window Capture, choose EchoPaw Mascot.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func errorMessage(_ error: String) -> some View {
        Label(error, systemImage: "exclamationmark.circle")
            .font(.callout)
            .foregroundStyle(.red)
            .fixedSize(horizontal: false, vertical: true)
    }
}
