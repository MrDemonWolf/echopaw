import SwiftUI

struct ProviderPreferences: View {
    @Environment(ProviderKeys.self) private var keys

    var body: some View {
        Form {
            Section {
                ForEach(KeyProvider.allCases, id: \.self) { provider in
                    ProviderKeyRow(provider: provider, keys: keys)
                }
            } header: {
                Text("Provider keys")
            } footer: {
                Text("Keys stay in this Mac’s Keychain. Saving a key makes no provider request. The mascot preview works offline.")
            }
        }
        .task { await keys.reload() }
    }
}

private struct ProviderKeyRow: View {
    let provider: KeyProvider
    let keys: ProviderKeys
    @State private var editing = false
    @State private var confirmingRemoval = false
    @State private var removing = false
    @State private var error: String?

    var body: some View {
        LabeledContent {
            switch keys.state(for: provider) {
            case .saved:
                Button("Replace…") { editing = true }
                    .accessibilityLabel("Replace " + provider.title + " key")
                Button("Remove…", role: .destructive) { confirmingRemoval = true }
                    .accessibilityLabel("Remove " + provider.title + " key")
            case .absent:
                Button("Add key…") { editing = true }
                    .accessibilityLabel("Add " + provider.title + " key")
            case .unavailable:
                Button("Try again") { Task { await keys.reload() } }
            case .checking, .saving, .removing:
                ProgressView().controlSize(.small)
            }
        } label: {
            Text(provider.title)
            Text(keys.status(for: provider))
        }
        .disabled(removing)
        .sheet(isPresented: $editing) { KeyEditor(provider: provider, keys: keys) }
        .confirmationDialog("Remove the " + provider.title + " key from this Mac?", isPresented: $confirmingRemoval) {
            Button("Remove key", role: .destructive) {
                removing = true
                Task {
                    defer { removing = false }
                    do { try await keys.remove(provider); error = nil }
                    catch { self.error = error.localizedDescription }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        if let error { Label(error, systemImage: "exclamationmark.triangle") }
    }
}

private struct KeyEditor: View {
    let provider: KeyProvider
    let keys: ProviderKeys
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    @State private var error: String?
    @State private var saving = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: EP.space4) {
            Text(provider.title + " API key").font(.headline)
            SecureField("Paste API key", text: $input)
                .focused($focused)
                .disabled(saving)
            Link("Manage keys at " + provider.title, destination: provider == .openAI
                 ? URL(string: "https://platform.openai.com/api-keys")!
                 : URL(string: "https://elevenlabs.io/app/api/api-keys")!)
            if let error { Label(error, systemImage: "exclamationmark.triangle") }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                    .disabled(saving)
                Button(saving ? "Saving…" : "Save key") {
                    saving = true
                    Task {
                        defer { saving = false }
                        do {
                            try await keys.save(input, for: provider)
                            input = ""
                            dismiss()
                        } catch { self.error = error.localizedDescription }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || saving)
            }
        }
        .padding(EP.space6)
        .frame(width: 380)
        .interactiveDismissDisabled(saving)
        .onAppear { focused = true }
        .onDisappear { input = "" }
    }
}
