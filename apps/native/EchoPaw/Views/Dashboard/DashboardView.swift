import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {
    @Bindable var session: PreviewSession
    @State private var choosingCharacter = false

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 740
            let layout = wide
                ? AnyLayout(HStackLayout(alignment: .top, spacing: 20))
                : AnyLayout(VStackLayout(alignment: .leading, spacing: 20))
            let stageHeight = min(390, max(270, geometry.size.height - 200))
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    layout {
                        stageGroup(height: stageHeight)
                            .frame(maxWidth: .infinity)
                        inspector
                            .frame(maxWidth: wide ? 294 : .infinity)
                    }
                }
                .padding(24)
                .frame(maxWidth: 1120)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 520, minHeight: 470)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if session.isStopped {
                    Button("Resume preview", systemImage: "play", action: session.resume)
                        .labelStyle(.titleAndIcon)
                        .help("Restore preview controls")
                } else {
                    Button("Emergency stop", systemImage: "stop.circle", action: session.emergencyStop)
                        .labelStyle(.titleAndIcon)
                        .help("Emergency stop (⇧⌘K)")
                }
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
        VStack(alignment: .leading, spacing: 4) {
            Text("Mascot preview")
                .font(.system(size: 34, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text("Rehearse your character and audio before going live.")
                .foregroundStyle(.secondary)
        }
    }

    private func stageGroup(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ZStack {
                RadialGradient(
                    colors: [
                        Color(red: 13.0 / 255, green: 77.0 / 255, blue: 140.0 / 255),
                        Color(red: 10.0 / 255, green: 22.0 / 255, blue: 51.0 / 255),
                    ],
                    center: .init(x: 0.5, y: 0.45),
                    startRadius: 18,
                    endRadius: 245
                )
                if let image = session.image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(.vertical, 20)
                        .padding(.horizontal, 18)
                        .accessibilityLabel(session.audio.isPlaying ? "Talking mascot" : "Idle mascot")
                }
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topLeading) {
                Text("Offline preview")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color(red: 220.0 / 255, green: 233.0 / 255, blue: 247.0 / 255))
                    .padding(14)
            }

            HStack(spacing: 12) {
                Button("Test output", systemImage: "waveform", action: session.testOutput)
                    .buttonStyle(.borderedProminent)
                    .disabled(!session.canTestOutput)

                Button(session.isMuted ? "Unmute speech" : "Mute speech",
                       systemImage: session.isMuted ? "speaker.slash" : "speaker.wave.2",
                       action: session.toggleMute)
                    .disabled(session.isStopped)

                Spacer(minLength: 4)

                Label(session.playbackLabel, systemImage: playbackSymbol)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
            .padding(14)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(.rect(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(.quaternary) }
    }

    private var playbackSymbol: String {
        if session.isStopped { return "stop.circle.fill" }
        if !session.audio.isSelectedOutputAvailable { return "exclamationmark.circle" }
        if session.isMuted { return "speaker.slash.fill" }
        if session.audio.isPlaying { return "waveform" }
        return "waveform.path"
    }

    private var inspector: some View {
        VStack(alignment: .leading, spacing: 15) {
            characterControls
            Divider()
            audioControls
            Divider()
            captureControls
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(.quaternary) }
    }

    private var characterControls: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Character")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(session.character?.name ?? "No character loaded")
                .foregroundStyle(.secondary)
            HStack {
                Button("Import character…") { choosingCharacter = true }
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
    }

    private var audioControls: some View {
        @Bindable var audio = session.audio
        return VStack(alignment: .leading, spacing: 9) {
            Text("Audio output")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Picker("Output device", selection: Binding(
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
            .labelsHidden()
            .accessibilityLabel("Output device")
            Slider(value: $audio.volume, in: 0...1) { Text("Volume") }
            if let error = audio.lastError {
                errorMessage(error)
            }
        }
    }

    private var captureControls: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("OBS capture")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Button(session.isCaptureVisible ? "Hide mascot window" : "Show mascot window",
                   systemImage: session.isCaptureVisible ? "rectangle.slash" : "rectangle.on.rectangle",
                   action: session.toggleCapture)
                .disabled(session.character == nil)
            Toggle("Use green screen", isOn: $session.usesChromaKey)
            if session.isCaptureVisible {
                Text("Choose EchoPaw Mascot in OBS Window Capture.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func errorMessage(_ error: String) -> some View {
        Label(error, systemImage: "exclamationmark.circle")
            .font(.callout)
            .foregroundStyle(.red)
            .fixedSize(horizontal: false, vertical: true)
    }
}
