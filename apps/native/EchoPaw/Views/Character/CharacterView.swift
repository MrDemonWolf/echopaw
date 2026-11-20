import SwiftUI
import UniformTypeIdentifiers

struct CharacterView: View {
    @Bindable var session: PreviewSession
    @Binding var inspector: Bool
    @State private var choosingFolder = false

    var body: some View {
        VStack(alignment: .leading, spacing: EP.space4) {
            Text(session.character?.name ?? "Choose a character")
                .font(BrandType.heading).accessibilityAddTraits(.isHeader)
            PreviewSurface(session: session).frame(maxHeight: .infinity)
            if session.isMuted || !session.audio.isSelectedOutputAvailable {
                Label(session.playbackLabel, systemImage: session.isStopped ? "stop.circle" : "speaker.slash")
                    .font(.callout)
            }
            HStack {
                TalkingButton(session: session)
                if session.hasBlinkFrames {
                    Button("Preview blink", systemImage: "eye", action: session.previewBlink)
                        .disabled(!session.canPreviewBlink)
                }
            }
        }
        .padding(EP.space4)
        .inspector(isPresented: $inspector) {
            Form {
                Section("Character pack") {
                    Button("Import folder…") { choosingFolder = true }
                    Button("Use starter wolf", action: session.useSample)
                    Text("Use matching idle.png and talking.png images.")
                        .font(.callout).foregroundStyle(.secondary)
                    if let error = session.characterError {
                        Label(error, systemImage: "exclamationmark.triangle")
                    }
                }
                Section("Eyes") {
                    if session.hasBlinkFrames {
                        Toggle("Auto-blink", isOn: $session.blinksAutomatically)
                            .disabled(session.reducesMotion)
                        if session.reducesMotion { Text("Reduce Motion pauses automatic blinking.") }
                    } else {
                        Label("No blink artwork supplied", systemImage: "eye.slash")
                    }
                }
            }
            .formStyle(.grouped)
            .inspectorColumnWidth(min: 220, ideal: EP.inspectorWidth, max: 340)
        }
        .toolbar {
            Button("Character inspector", systemImage: "sidebar.trailing") { inspector.toggle() }
                .help("Show or hide the character inspector (⌃⌘I)")
        }
        .fileImporter(isPresented: $choosingFolder, allowedContentTypes: [.folder]) { result in
            if case .failure(let error) = result, (error as NSError).code == NSUserCancelledError { return }
            session.importCharacter(result)
        }
    }
}
