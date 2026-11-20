import SwiftUI

struct PreferencesView: View {
    @Bindable var session: PreviewSession

    var body: some View {
        TabView {
            Form {
                Section("Playback") {
                    DevicePicker(audio: session.audio)
                    Slider(value: Binding(get: { session.audio.volume }, set: { session.audio.volume = $0 }), in: 0...1) {
                        Text("Volume")
                    }
                    if let error = session.audio.lastError {
                        Label(error, systemImage: "exclamationmark.triangle")
                    }
                }
                Section("OBS mascot window") {
                    Toggle("Use green screen", isOn: $session.usesChromaKey)
                    Text("Choose EchoPaw Mascot in OBS Window Capture.")
                        .font(.callout).foregroundStyle(.secondary)
                }
            }
            .tabItem { Label("Audio & capture", systemImage: "speaker.wave.2") }

            Form {
                Section("Accounts") { ConnectionsView() }
                Section("Privacy") {
                    Text("Preview audio and character images stay on this Mac. No account is needed.")
                }
            }
            .tabItem { Label("Privacy & accounts", systemImage: "hand.raised") }
        }
        .formStyle(.grouped)
        .frame(width: 490, height: 360)
    }
}

struct DevicePicker: View {
    let audio: PreviewAudio

    var body: some View {
        Picker("Output device", selection: Binding(
            get: { audio.selectedDeviceUID }, set: { audio.selectOutput($0) }
        )) {
            Text("System Default").tag(nil as String?)
            ForEach(audio.devices) { device in
                Text(device.name).tag(Optional(device.uid))
            }
            if let selected = audio.selectedDeviceUID, !audio.devices.contains(where: { $0.uid == selected }) {
                Text("Unavailable device").tag(Optional(selected))
            }
        }
    }
}

#if DEBUG
struct ComponentGallery: View {
    let session: PreviewSession

    var body: some View {
        Form {
            Section("Current character") { PreviewSurface(session: session).frame(height: EP.stageMinHeight) }
            Section("Session controls") { SessionControls(session: session) }
            Section("Output device") { DevicePicker(audio: session.audio) }
            Section("Status row examples") {
                StatusRow(title: "Connection", symbol: "bolt.slash", value: "Not connected")
                StatusRow(title: "Speech", symbol: "speaker.slash", value: "Muted")
                StatusRow(title: "Session", symbol: "stop.circle", value: "Stopped")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 440, minHeight: 450)
    }
}
#endif
