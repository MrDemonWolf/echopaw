import Foundation
import Testing
@testable import EchoPaw

@MainActor
struct ProviderKeysTests {
    @Test func savesReplacesRestoresAndRemovesEachKeyIndependently() async throws {
        let store = TestStore()
        let keys = ProviderKeys(store: store)
        await keys.reload()
        #expect(keys.status(for: .openAI) == "No key saved")
        #expect(await store.reads == 0)

        try await keys.save(" trimmed-test-value\n", for: .openAI)
        #expect(await store.read("api-key.openAI") == Data("trimmed-test-value".utf8))
        try await keys.save("replacement-test-value", for: .openAI)
        try await keys.save("eleven-test-value", for: .elevenLabs)

        let reopened = ProviderKeys(store: store)
        await reopened.reload()
        #expect(reopened.isSaved(.openAI) && reopened.isSaved(.elevenLabs))
        #expect(await store.read("api-key.openAI") == Data("replacement-test-value".utf8))
        try await reopened.remove(.openAI)
        try await reopened.remove(.openAI)
        #expect(!reopened.isSaved(.openAI))
        #expect(reopened.isSaved(.elevenLabs))
        #expect(await store.read("api-key.openAI") == nil)
    }

    @Test(arguments: [" \t\n", "key with spaces", "two\r\nlines", "key\u{0}here"])
    func invalidPastePreservesSavedKey(_ input: String) async throws {
        let store = TestStore()
        let keys = ProviderKeys(store: store)
        try await keys.save("previous-test-value", for: .openAI)
        await #expect(throws: CredentialError.invalidKey) { try await keys.save(input, for: .openAI) }
        #expect(await store.read("api-key.openAI") == Data("previous-test-value".utf8))
        #expect(keys.isSaved(.openAI))
    }

    @Test func surfacesStoreFailuresAndRecoversWithoutOverwritingKey() async throws {
        let store = TestStore()
        let keys = ProviderKeys(store: store)
        try await keys.save("kept-test-value", for: .elevenLabs)
        await store.setUnavailable(true)
        await keys.reload()
        #expect(keys.status(for: .elevenLabs) == "Keychain unavailable")
        await #expect(throws: CredentialError.keychainUnavailable) { try await keys.save("new-test-value", for: .elevenLabs) }
        await #expect(throws: CredentialError.keychainUnavailable) { try await keys.remove(.elevenLabs) }
        await store.setUnavailable(false)
        await keys.reload()
        #expect(keys.isSaved(.elevenLabs))
        #expect(await store.read("api-key.elevenLabs") == Data("kept-test-value".utf8))
    }

    @Test func delayedLookupCannotHideANewerSave() async throws {
        let store = TestStore()
        let keys = ProviderKeys(store: store)
        await store.delayNextLookup()
        let reload = Task { await keys.reload() }
        let deadline = ContinuousClock.now + .seconds(2)
        while await !store.waiting && ContinuousClock.now < deadline { await Task.yield() }
        try #require(await store.waiting)
        try await keys.save("new-test-value", for: .openAI)
        await store.finishLookup()
        await reload.value
        #expect(keys.isSaved(.openAI))
    }

    private actor TestStore: ConnectionSecretStore {
        struct TestError: Error {}
        private var items: [String: Data] = [:]
        private var unavailable = false
        private(set) var reads = 0
        private var delayed = false
        private var lookup: CheckedContinuation<Void, Never>?
        var waiting: Bool { lookup != nil }

        func setUnavailable(_ value: Bool) { unavailable = value }
        func delayNextLookup() { delayed = true }
        func finishLookup() {
            lookup?.resume()
            lookup = nil
        }
        func read(_ account: String) -> Data? {
            reads += 1
            return items[account]
        }
        func contains(_ account: String) async throws -> Bool {
            guard !unavailable else { throw TestError() }
            let exists = items[account] != nil
            if delayed {
                delayed = false
                await withCheckedContinuation { lookup = $0 }
            }
            return exists
        }
        func write(_ data: Data, account: String) throws {
            guard !unavailable else { throw TestError() }
            items[account] = data
        }
        func remove(_ account: String) throws {
            guard !unavailable else { throw TestError() }
            items.removeValue(forKey: account)
        }
    }
}
