import SwiftUI

extension TwitchConnectionState {
    var summary: String {
        switch self {
        case .disconnected: "Not connected"
        case .checking: "Checking account…"
        case .requestingCode: "Requesting code…"
        case .waiting: "Awaiting approval"
        case .connected(let login): "Connected as " + login
        case .problem: "Needs attention"
        }
    }
}

struct TwitchPreferences: View {
    @Environment(TwitchConnections.self) private var twitch
    @State private var clientID = ""
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Public client ID", text: $clientID, prompt: Text("Paste client ID"))
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Public client ID")
                        .autocorrectionDisabled()
                        .disabled(!twitch.canEditClientID)
                    Button("Save") {
                        do {
                            try twitch.saveClientID(clientID)
                            clientID = twitch.clientID
                            error = nil
                        } catch { self.error = error.localizedDescription }
                    }
                    .disabled(clientID == twitch.clientID || !twitch.canEditClientID)
                    .accessibilityLabel("Save Twitch client ID")
                }
                if let error { Label(error, systemImage: "exclamationmark.triangle") }
                Link("Twitch developer console", destination: URL(string: "https://dev.twitch.tv/console/apps")!)
            } header: {
                Text("Twitch application")
            } footer: {
                Text(twitch.canEditClientID
                     ? "Use the client ID from a Twitch application registered as Public. Both accounts use the same ID."
                     : "Cancel sign-in and disconnect saved accounts before changing the client ID.")
            }
            ForEach(TwitchRole.allCases, id: \.self) { role in
                TwitchAccountSection(role: role, twitch: twitch, hasUnsavedID: clientID != twitch.clientID)
            }
        }
        .onAppear { clientID = twitch.clientID }
    }
}

private struct TwitchAccountSection: View {
    let role: TwitchRole
    let twitch: TwitchConnections
    let hasUnsavedID: Bool
    @State private var confirmingRemoval = false

    var body: some View {
        let state = twitch.state(for: role)
        Section {
            LabeledContent(role.rawValue.capitalized, value: state.summary)
            switch state {
            case .waiting(let code, let url, let expiry):
                HStack {
                    Text(code).font(.system(.title3, design: .monospaced)).textSelection(.enabled)
                    Button("Copy code") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(code, forType: .string)
                    }
                    Spacer()
                    Link("Open Twitch", destination: url)
                }
                Text("Approve in your browser by \(expiry.formatted(date: .omitted, time: .shortened)). Check which Twitch account is signed in.")
                    .font(.callout)
                cancel
            case .requestingCode:
                cancel
            case .checking:
                ProgressView().controlSize(.small).accessibilityLabel("Checking " + role.rawValue)
            case .connected:
                disconnect
            case .problem(let message):
                Label(message, systemImage: "exclamationmark.triangle").font(.callout)
                if twitch.hasSavedAccount(role) {
                    HStack {
                        Button("Check again") { twitch.retryValidation(role) }
                        disconnect
                    }
                } else { connect }
            case .disconnected:
                connect
            }
        } footer: {
            Text(role == .broadcaster
                 ? "Sign in as the channel owner to identify your channel."
                 : "Sign in as a different Twitch user for your bot. EchoPaw requests read-only chat access. Live chat is off.")
        }
        .confirmationDialog("Disconnect the Twitch " + role.rawValue + "?", isPresented: $confirmingRemoval) {
            Button("Disconnect", role: .destructive) { twitch.disconnect(role) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var connect: some View {
        Button("Connect " + role.rawValue) { twitch.connect(role) }
            .disabled(hasUnsavedID || !twitch.canConnect(role))
    }

    private var cancel: some View {
        Button("Cancel sign-in") { twitch.cancel(role) }
    }

    private var disconnect: some View {
        Button("Disconnect…", role: .destructive) { confirmingRemoval = true }
    }
}
