import Foundation
import Testing
@testable import EchoPaw

private actor TwitchTestStore: ConnectionSecretStore {
    private var items = [String: Data]()
    func read(_ account: String) -> Data? { items[account] }
    func write(_ data: Data, account: String) { items[account] = data }
    func remove(_ account: String) { items.removeValue(forKey: account) }
}

@MainActor
private final class TwitchTestServer {
    var replies = [(Int, String)]()
    var requests = [URLRequest]()
    var pauses = [Double]()
    var time = Date.now
    var waitForRequest: CheckedContinuation<Void, Never>?
    var suspendNext = false

    let challenge = #"{"device_code":"fixture-device","user_code":"FROST","verification_uri":"https://www.twitch.tv/activate?device-code=FROST","interval":5,"expires_in":60}"#
    let tokens = #"{"access_token":"access-fixture","refresh_token":"refresh+fixture"}"#
    func identity(_ id: String, bot: Bool = false) -> String {
        let scopes = bot ? #"["user:read:chat"]"# : "[]"
        return #"{"client_id":"fixtureClient","user_id":"\#(id)","login":"user\#(id)","scopes":\#(scopes),"expires_in":6000}"#
    }

    var api: TwitchOAuth {
        TwitchOAuth { request in
            self.requests.append(request)
            #expect(request.url?.host == "id.twitch.tv")
            guard !self.replies.isEmpty else { throw URLError(.badServerResponse) }
            let (status, json) = self.replies.removeFirst()
            if self.suspendNext {
                self.suspendNext = false
                await withCheckedContinuation { self.waitForRequest = $0 }
            }
            return (Data(json.utf8), HTTPURLResponse(url: try #require(request.url), statusCode: status,
                                                     httpVersion: nil, headerFields: nil)!)
        }
    }

    func model(_ store: TwitchTestStore, defaults: UserDefaults) -> TwitchConnections {
        TwitchConnections(store: store, defaults: defaults, api: api, now: { self.time }) { seconds in
            self.pauses.append(seconds)
            self.time.addTimeInterval(seconds)
        }
    }
}

@MainActor
struct TwitchConnectionsTests {
    private func waitUntil(_ predicate: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(3)
        while !predicate(), ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(1)) }
        try #require(predicate())
    }

    @Test func publicDeviceFlowWaitsForConsentAndKeepsRolesSeparate() async throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = TwitchTestStore()
        let server = TwitchTestServer()
        let model = server.model(store, defaults: defaults)
        model.restore()
        try await waitUntil { model.canEditClientID }
        #expect(server.requests.isEmpty)
        try model.saveClientID(" fixtureClient ")
        server.replies = [(200, server.challenge), (400, #"{"message":"authorization_pending"}"#),
                          (400, #"{"error":"slow_down"}"#), (200, server.tokens), (200, server.identity("101"))]
        model.connect(.broadcaster)
        model.connect(.bot)
        try await waitUntil { model.state(for: .broadcaster) == .connected(login: "user101") }
        #expect(server.pauses == [5, 5, 10])
        #expect(server.requests.map { $0.url?.lastPathComponent } == ["device", "token", "token", "token", "validate"])
        #expect(String(decoding: server.requests[0].httpBody ?? Data(), as: UTF8.self) == "client_id=fixtureClient&scopes=")
        #expect(server.requests.last?.value(forHTTPHeaderField: "Authorization") == "Bearer access-fixture")
        #expect(!model.canEditClientID)
        #expect(model.state(for: .bot) == .disconnected)

        server.replies = [(200, server.challenge), (200, server.tokens), (200, server.identity("101", bot: true))]
        model.connect(.bot)
        try await waitUntil { model.state(for: .bot) == .problem(TwitchAuthError.duplicate.rawValue) }
        #expect(await store.read(TwitchRole.bot.account) == nil)
        server.replies = [(200, server.challenge), (200, server.tokens), (200, server.identity("202", bot: true))]
        model.connect(.bot)
        try await waitUntil { model.state(for: .bot) == .connected(login: "user202") }
        #expect(await store.read(TwitchRole.broadcaster.account) != nil)
        #expect(await store.read(TwitchRole.bot.account) != nil)
    }

    @Test func restoreRefreshesOnceAndPreservesRotationAcrossNetworkFailure() async throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = TwitchTestStore()
        let server = TwitchTestServer()
        let model = server.model(store, defaults: defaults)
        model.restore()
        try await waitUntil { model.canEditClientID }
        try model.saveClientID("fixtureClient")
        server.replies = [(200, server.challenge), (200, server.tokens), (200, server.identity("202", bot: true))]
        model.connect(.bot)
        try await waitUntil { model.hasSavedAccount(.bot) }

        let restored = server.model(store, defaults: defaults)
        server.replies = [(401, "{}"), (200, #"{"access_token":"rotated-access","refresh_token":"rotated-refresh"}"#), (503, "{}")]
        restored.restore()
        restored.restore()
        try await waitUntil { restored.state(for: .bot) == .problem(TwitchAuthError.service.rawValue) }
        #expect(restored.hasSavedAccount(.bot))
        let request = try #require(server.requests.first { String(decoding: $0.httpBody ?? Data(), as: UTF8.self).contains("refresh_token=") })
        #expect(String(decoding: request.httpBody ?? Data(), as: UTF8.self).contains("refresh_token=refresh%2Bfixture"))

        server.replies = [(200, server.identity("202", bot: true))]
        restored.retryValidation(.bot)
        try await waitUntil { restored.state(for: .bot) == .connected(login: "user202") }
        #expect(server.requests.last?.value(forHTTPHeaderField: "Authorization") == "Bearer rotated-access")
        server.replies = [(200, "")]
        restored.disconnect(.bot)
        try await waitUntil { restored.state(for: .bot) == .disconnected }
        #expect(server.requests.last?.url?.lastPathComponent == "revoke")
        #expect(await store.read(TwitchRole.bot.account) == nil)
    }

    @Test func cancellationRejectsLateChallengeAndBlocksUntrustedActivationURL() async throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = TwitchTestStore()
        let server = TwitchTestServer()
        let model = server.model(store, defaults: defaults)
        model.restore()
        try await waitUntil { model.canEditClientID }
        try model.saveClientID("fixtureClient")
        server.suspendNext = true
        server.replies = [(200, server.challenge)]
        model.connect(.bot)
        try await waitUntil { server.waitForRequest != nil }
        model.cancel(.bot)
        server.waitForRequest?.resume()
        server.replies = [(200, server.challenge.replacingOccurrences(of: "www.twitch.tv", with: "example.invalid"))]
        model.connect(.broadcaster)
        try await waitUntil { model.state(for: .broadcaster) == .problem(TwitchAuthError.service.rawValue) }
        #expect(model.state(for: .bot) == .disconnected)
        #expect(server.requests.count == 2)
        #expect(await store.read(TwitchRole.bot.account) == nil)

        server.replies = [(200, server.challenge), (200, server.tokens), (200, server.identity("202"))]
        model.connect(.bot)
        try await waitUntil { model.state(for: .bot) == .problem(TwitchAuthError.invalidGrant.rawValue) }
        #expect(await store.read(TwitchRole.bot.account) == nil)
    }

    @Test func deniedAndExpiredCodesCanRetryAndRevokedRefreshEndsSession() async throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = TwitchTestStore()
        let server = TwitchTestServer()
        let model = server.model(store, defaults: defaults)
        model.restore()
        try await waitUntil { model.canEditClientID }
        try model.saveClientID("fixtureClient")
        server.replies = [(200, server.challenge), (403, #"{"error":"access_denied"}"#)]
        model.connect(.bot)
        try await waitUntil { model.state(for: .bot) == .problem(TwitchAuthError.denied.rawValue) }
        let shortLived = server.challenge.replacingOccurrences(of: #""expires_in":60"#, with: #""expires_in":5"#)
        server.replies = [(200, shortLived)]
        model.connect(.bot)
        try await waitUntil { model.state(for: .bot) == .problem(TwitchAuthError.expired.rawValue) }
        #expect(server.requests.count == 3)

        server.replies = [(200, server.challenge), (200, server.tokens), (200, server.identity("202", bot: true))]
        model.connect(.bot)
        try await waitUntil { model.hasSavedAccount(.bot) }
        server.replies = [(401, "{}"), (400, #"{"error":"Bad Request","status":400,"message":"Invalid refresh token"}"#)]
        model.retryValidation(.bot)
        try await waitUntil { model.state(for: .bot) == .problem(TwitchAuthError.invalidRefresh.rawValue) }
        #expect(await store.read(TwitchRole.bot.account) == nil)
        #expect(model.canConnect(.bot))
    }
}
