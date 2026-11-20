import SwiftUI

struct MicrophonePreferences: View {
    let mic: LocalMicrophone
    let stopped: Bool
    @AppStorage("micInput") private var input = ""
    @AppStorage("micFollowsVoice") private var followsVoice = true
    @AppStorage("micUsesPhrase") private var usesPhrase = false
    @AppStorage("micWakePhrase") private var phrase = "Hey EchoPaw"

    var body: some View {
        Section("Local microphone") {
            Picker("Input device", selection: $input) {
                Text("System Default").tag("")
                ForEach(mic.inputs, id: \.uniqueID) { Text($0.localizedName).tag($0.uniqueID) }
                if !input.isEmpty && !mic.inputs.contains(where: { $0.uniqueID == input }) {
                    Text("Saved input").tag(input)
                }
            }
            Toggle("React to my voice", isOn: $followsVoice)
            Toggle("Detect a wake phrase on this Mac", isOn: $usesPhrase)
            if usesPhrase {
                TextField("Wake phrase", text: $phrase)
                Text("Hearing the phrase shows a local confirmation.").font(.callout)
            }
        }
        .disabled(mic.state != .off || stopped)
        Section {
            LabeledContent("Microphone", value: mic.state.rawValue)
            Button(mic.state == .off ? "Start listening" : "Stop listening") {
                if mic.state != .off { mic.stop(); return }
                mic.start(deviceID: input, followsVoice: followsVoice,
                          phrase: usesPhrase ? phrase.trimmingCharacters(in: .whitespacesAndNewlines) : nil)
            }
            .disabled(stopped || (mic.state == .off && ((!followsVoice && !usesPhrase)
                       || (usesPhrase && !phrase.contains(where: { $0.isLetter || $0.isNumber })))))
            if let message = mic.message { Text(message).font(.callout) }
        }
        .onAppear { mic.refreshInputs() }
    }
}
