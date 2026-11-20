import Foundation
import Observation
import Security

protocol ConnectionSecretStore: Sendable {
    func read(_ account: String) async throws -> Data?
    func contains(_ account: String) async throws -> Bool
    func write(_ data: Data, account: String) async throws
    func remove(_ account: String) async throws
}

extension ConnectionSecretStore {
    func contains(_ account: String) async throws -> Bool { try await read(account) != nil }
}

actor KeychainSecretStore: ConnectionSecretStore {
    private let service: String

    init(service: String? = nil) {
        self.service = service ?? (Bundle.main.bundleIdentifier ?? "com.mrdemonwolf.echopaw.dev") + ".connections"
    }

    private func item(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    func contains(_ account: String) async throws -> Bool {
        var query = item(account)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecItemNotFound { return false }
        guard status == errSecSuccess else { throw CredentialError.keychainUnavailable }
        return true
    }

    func read(_ account: String) throws -> Data? {
        var query = item(account)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw CredentialError.keychainUnavailable }
        return data
    }

    func write(_ data: Data, account: String) throws {
        let query = item(account)
        let value = [kSecValueData as String: data]
        var fields = query
        fields[kSecValueData as String] = data
        var status = SecItemAdd(fields as CFDictionary, nil)
        if status == errSecDuplicateItem {
            status = SecItemUpdate(query as CFDictionary, value as CFDictionary)
        }
        guard status == errSecSuccess else { throw CredentialError.keychainUnavailable }
    }

    func remove(_ account: String) throws {
        let status = SecItemDelete(item(account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw CredentialError.keychainUnavailable }
    }
}

enum KeyProvider: String, CaseIterable {
    case openAI, elevenLabs

    var title: String { self == .openAI ? "OpenAI" : "ElevenLabs" }
    fileprivate var account: String { "api-key." + rawValue }
}

enum CredentialError: LocalizedError {
    case invalidKey, keychainUnavailable, busy

    var errorDescription: String? {
        switch self {
        case .invalidKey: "Paste one API key without spaces or line breaks."
        case .keychainUnavailable: "EchoPaw couldn't access the login Keychain. Check that it is unlocked and try again."
        case .busy: "Wait for the current Keychain change to finish."
        }
    }
}

@Observable @MainActor
final class ProviderKeys {
    enum State: String {
        case checking = "Checking…", absent = "No key saved", saved = "Key saved", unavailable = "Keychain unavailable"
        case saving = "Saving…", removing = "Removing…"

        var isChanging: Bool { self == .saving || self == .removing }
    }

    private let store: any ConnectionSecretStore
    private var states: [KeyProvider: State] = [:]
    @ObservationIgnored private var currentReload = UUID()

    init(store: any ConnectionSecretStore) { self.store = store }

    func state(for provider: KeyProvider) -> State { states[provider] ?? .checking }
    func status(for provider: KeyProvider) -> String { state(for: provider).rawValue }
    func isSaved(_ provider: KeyProvider) -> Bool { state(for: provider) == .saved }

    func reload() async {
        let reload = UUID()
        currentReload = reload
        for provider in KeyProvider.allCases where states[provider]?.isChanging != true {
            states[provider] = .checking
            let current: State
            do { current = try await store.contains(provider.account) ? .saved : .absent }
            catch { current = .unavailable }
            guard reload == currentReload else { return }
            if states[provider] == .checking { states[provider] = current }
        }
    }

    func save(_ input: String, for provider: KeyProvider) async throws {
        let key = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, key.utf8.allSatisfy({ (33...126).contains($0) }) else { throw CredentialError.invalidKey }
        try await change(provider, data: Data(key.utf8))
    }

    func remove(_ provider: KeyProvider) async throws { try await change(provider, data: nil) }

    private func change(_ provider: KeyProvider, data: Data?) async throws {
        guard states[provider]?.isChanging != true else { throw CredentialError.busy }
        states[provider] = data == nil ? .removing : .saving
        do {
            if let data { try await store.write(data, account: provider.account) }
            else { try await store.remove(provider.account) }
        } catch {
            states[provider] = .unavailable
            throw CredentialError.keychainUnavailable
        }
        states[provider] = data == nil ? .absent : .saved
    }
}
