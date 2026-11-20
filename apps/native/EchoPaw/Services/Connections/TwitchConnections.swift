import Foundation
import Observation

enum TwitchConnectionState: Equatable {
    case disconnected
    case checking
    case requestingCode
    case waiting(code: String, url: URL, expiresAt: Date)
    case connected(login: String)
    case problem(String)
}

@MainActor @Observable
final class TwitchConnections {
    private struct Account: Codable {
        let clientID: String
        let userID: String
        var tokens: TwitchTokenPair
    }

    private(set) var clientID: String
    private(set) var activeSignIn: TwitchRole?
    private var states = [TwitchRole: TwitchConnectionState]()
    private var saved = Set<TwitchRole>()
    private var started = false
    @ObservationIgnored private var tasks = [TwitchRole: Task<Void, Never>]()
    private let store: any ConnectionSecretStore
    private let defaults: UserDefaults
    private let api: TwitchOAuth
    private let now: () -> Date
    private let pollSleep: (TimeInterval) async throws -> Void
    @ObservationIgnored private var removing = Set<TwitchRole>()
    private static let unconfirmedRevoke = "Removed from this Mac. Check Twitch Settings > Connections to confirm revocation."

    init(store: any ConnectionSecretStore, defaults: UserDefaults = .standard,
         api: TwitchOAuth = .init(), now: @escaping () -> Date = Date.init,
         pollSleep: @escaping (TimeInterval) async throws -> Void = { try await Task.sleep(for: .seconds($0)) }) {
        self.store = store
        self.defaults = defaults
        self.api = api
        self.now = now
        self.pollSleep = pollSleep
        clientID = defaults.string(forKey: "twitchPublicClientID") ?? ""
    }

    func state(for role: TwitchRole) -> TwitchConnectionState { states[role] ?? .checking }
    func hasSavedAccount(_ role: TwitchRole) -> Bool { saved.contains(role) }

    var canEditClientID: Bool {
        started && activeSignIn == nil && saved.isEmpty && TwitchRole.allCases.allSatisfy { state(for: $0) != .checking }
    }

    func saveClientID(_ value: String) throws {
        let id = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canEditClientID else { throw TwitchAuthError.configurationLocked }
        guard id.utf8.count <= 128, id.utf8.allSatisfy({ $0.isASCIIAlphaNumeric }) else { throw TwitchAuthError.clientID }
        clientID = id
        defaults.set(id, forKey: "twitchPublicClientID")
    }

    func canConnect(_ role: TwitchRole) -> Bool {
        guard !clientID.isEmpty, activeSignIn == nil, !saved.contains(role) else { return false }
        switch state(for: role) {
        case .disconnected, .problem: return true
        default: return false
        }
    }

    func restore() {
        guard !started else { return }
        started = true
        for role in TwitchRole.allCases { retryValidation(role) }
    }

    func connect(_ role: TwitchRole) {
        guard canConnect(role) else { return }
        activeSignIn = role
        states[role] = .requestingCode
        tasks[role] = Task { await authorize(role) }
    }

    func cancel(_ role: TwitchRole) {
        guard activeSignIn == role else { return }
        switch state(for: role) {
        case .waiting, .requestingCode:
            tasks.removeValue(forKey: role)?.cancel()
            activeSignIn = nil
            states[role] = .disconnected
        default: break
        }
    }

    func disconnect(_ role: TwitchRole) {
        guard saved.contains(role), !removing.contains(role) else { return }
        let previous = tasks.removeValue(forKey: role)
        previous?.cancel()
        removing.insert(role)
        states[role] = .checking
        tasks[role] = Task {
            // A single-use refresh may be committing a rotated pair. Delete after that write finishes.
            await previous?.value
            let account = try? await read(role)
            do {
                try await store.remove(role.account)
                saved.remove(role)
                if let account {
                    try await api.revoke(clientID: account.clientID, token: account.tokens.access_token)
                    states[role] = .disconnected
                } else {
                    states[role] = .problem(Self.unconfirmedRevoke)
                }
            } catch {
                states[role] = .problem(saved.contains(role) ? TwitchAuthError.storage.rawValue : Self.unconfirmedRevoke)
            }
            removing.remove(role)
        }
    }

    func retryValidation(_ role: TwitchRole) {
        guard activeSignIn != role, !removing.contains(role), states[role] != .checking else { return }
        tasks[role]?.cancel()
        states[role] = .checking
        tasks[role] = Task {
            do {
                guard var account = try await read(role) else {
                    try Task.checkCancellation()
                    saved.remove(role)
                    states[role] = .disconnected
                    return
                }
                try Task.checkCancellation()
                saved.insert(role)
                guard account.clientID == clientID else { throw TwitchAuthError.differentApp }
                let identity: TwitchIdentity
                do {
                    identity = try await api.validate(account.tokens.access_token)
                } catch TwitchAuthError.unauthorized {
                    account.tokens = try await api.refresh(clientID: account.clientID, token: account.tokens.refresh_token)
                    // Persist the replacement refresh token before another network request can fail.
                    try await write(account, role: role)
                    identity = try await api.validate(account.tokens.access_token)
                }
                try Task.checkCancellation()
                try check(identity, role: role, expectedID: account.userID)
                validated(identity, role: role)
            } catch {
                guard !Task.isCancelled else { return }
                if let failure = error as? TwitchAuthError,
                   [.invalidRefresh, .unauthorized, .invalidGrant].contains(failure) {
                    do {
                        try await store.remove(role.account)
                        try Task.checkCancellation()
                        saved.remove(role)
                    } catch {
                        guard !Task.isCancelled else { return }
                        states[role] = .problem(TwitchAuthError.storage.rawValue)
                        return
                    }
                } else {
                    // A locked Keychain is different from an absent account.
                    saved.insert(role)
                    let failure = error as? TwitchAuthError
                    if failure != .differentApp && failure != .storage { scheduleValidation(role, after: 60) }
                }
                states[role] = .problem(Self.message(error))
            }
        }
    }

    private func authorize(_ role: TwitchRole) async {
        defer { if !Task.isCancelled { activeSignIn = nil } }
        do {
            let code = try await api.device(clientID: clientID, role: role)
            try Task.checkCancellation()
            let expires = now().addingTimeInterval(Double(code.expires_in))
            states[role] = .waiting(code: code.user_code, url: code.verification_uri, expiresAt: expires)
            var interval = Double(code.interval)
            while now() < expires {
                try await pollSleep(min(interval, expires.timeIntervalSince(now())))
                try Task.checkCancellation()
                guard now() < expires else { break }
                let tokens: TwitchTokenPair
                do {
                    tokens = try await api.poll(clientID: clientID, role: role, code: code.device_code)
                } catch TwitchAuthError.pending {
                    continue
                } catch TwitchAuthError.slowDown {
                    interval += 5
                    continue
                }
                let identity = try await api.validate(tokens.access_token)
                try check(identity, role: role, expectedID: nil)
                let other = try await read(role == .bot ? .broadcaster : .bot)
                try Task.checkCancellation()
                guard other?.userID != identity.user_id else { throw TwitchAuthError.duplicate }
                states[role] = .checking
                try await write(Account(clientID: clientID, userID: identity.user_id, tokens: tokens), role: role)
                try Task.checkCancellation()
                saved.insert(role)
                validated(identity, role: role)
                return
            }
            throw TwitchAuthError.expired
        } catch {
            guard !Task.isCancelled else { return }
            states[role] = .problem(Self.message(error))
        }
    }

    private func check(_ identity: TwitchIdentity, role: TwitchRole, expectedID: String?) throws {
        guard identity.client_id == clientID, !identity.user_id.isEmpty, !identity.login.isEmpty,
              expectedID == nil || identity.user_id == expectedID,
              Set(identity.scopes ?? []) == Set(role.scopes) else { throw TwitchAuthError.invalidGrant }
    }

    private func validated(_ identity: TwitchIdentity, role: TwitchRole) {
        states[role] = .connected(login: identity.login)
        let lifetime = identity.expires_in > 0 ? min(3600, identity.expires_in) : 3600
        scheduleValidation(role, after: lifetime)
    }

    private func scheduleValidation(_ role: TwitchRole, after seconds: Int) {
        tasks[role] = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
            self?.retryValidation(role)
        }
    }

    private func read(_ role: TwitchRole) async throws -> Account? {
        do {
            guard let data = try await store.read(role.account) else { return nil }
            return try JSONDecoder().decode(Account.self, from: data)
        } catch { throw TwitchAuthError.storage }
    }

    private func write(_ account: Account, role: TwitchRole) async throws {
        try Task.checkCancellation()
        do { try await store.write(JSONEncoder().encode(account), account: role.account) }
        catch { throw TwitchAuthError.storage }
    }

    private static func message(_ error: Error) -> String {
        (error as? TwitchAuthError)?.rawValue ?? TwitchAuthError.service.rawValue
    }
}

private extension UInt8 {
    var isASCIIAlphaNumeric: Bool { (48...57).contains(self) || (65...90).contains(self) || (97...122).contains(self) }
}
