import SwiftUI
import UniformTypeIdentifiers

struct CharacterView: View {
    @Bindable var session: PreviewSession
    @Binding var inspector: Bool
    @State private var choosingFolder = false
    @State private var choosingImage = false
    @State private var choosingSpeaking = false
    @State private var idleImage: URL?
    @State private var speakingImage: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(session.character?.name ?? "Choose a character")
                .font(BrandType.heading).accessibilityAddTraits(.isHeader)
                .lineLimit(2)
                .padding(.horizontal, EP.space4)
                .padding(.vertical, EP.space2)
            PreviewSurface(session: session).frame(maxHeight: .infinity)
            Divider()
            if session.isMuted || !session.audio.isSelectedOutputAvailable {
                Label(session.playbackLabel, systemImage: session.isStopped ? "stop.circle" : "speaker.slash")
                    .font(.callout)
                    .padding(.horizontal, EP.space3)
            }
            ViewThatFits(in: .horizontal) {
                HStack { previewButtons }
                VStack { previewButtons }
            }
            .frame(maxWidth: .infinity)
            .padding(EP.space2)
        }
        .inspector(isPresented: $inspector) {
            Form {
                Section("Character pack") {
                    imagePicker("Choose idle image", selection: idleImage) { choosingSpeaking = false }
                    imagePicker("Choose speaking image", selection: speakingImage) { choosingSpeaking = true }
                    Button("Use these images") {
                        if let idleImage, let speakingImage {
                            session.importCharacterImages(idle: idleImage, speaking: speakingImage)
                        }
                    }
                    .disabled(idleImage == nil || speakingImage == nil)
                    Button("Import folder…") { choosingFolder = true }
                    Button("Use starter wolf", action: session.useSample)
                    Text("Choose two matching PNGs, or import a folder with idle.png and talking.png.")
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
            .fileImporter(isPresented: $choosingImage, allowedContentTypes: [.png]) { result in
                switch result {
                case .success(let url):
                    if choosingSpeaking { speakingImage = url } else { idleImage = url }
                case .failure(let error):
                    if (error as NSError).code != NSUserCancelledError { session.importCharacter(.failure(error)) }
                }
            }
            .inspectorColumnWidth(min: 220, ideal: EP.inspectorWidth, max: 340)
        }
        .toolbar {
            Button("Character inspector", systemImage: "sidebar.trailing") { inspector.toggle() }
                .keyboardShortcut("i", modifiers: [.control, .command])
                .help("Show or hide the character inspector (⌃⌘I)")
        }
        .fileImporter(isPresented: $choosingFolder, allowedContentTypes: [.folder]) { result in
            if case .failure(let error) = result, (error as NSError).code == NSUserCancelledError { return }
            session.importCharacter(result)
        }
    }

    @ViewBuilder private var previewButtons: some View {
        TalkingButton(session: session)
        if session.hasBlinkFrames {
            Button("Preview blink", systemImage: "eye", action: session.previewBlink)
                .disabled(!session.canPreviewBlink)
        }
    }

    private func imagePicker(_ title: String, selection: URL?, prepare: @escaping () -> Void) -> some View {
        Button(selection?.lastPathComponent ?? title + "…") {
            prepare()
            choosingImage = true
        }
        .lineLimit(1)
        .truncationMode(.middle)
        .help(selection?.lastPathComponent ?? title)
        .accessibilityLabel(title)
        .accessibilityValue(selection?.lastPathComponent ?? "None selected")
    }
}
