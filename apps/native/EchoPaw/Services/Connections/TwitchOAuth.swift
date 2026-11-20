import Foundation

enum TwitchRole: String, CaseIterable {
    case broadcaster, bot

    var scopes: [String] { self == .bot ? ["user:read:chat"] : [] }
    var account: String { "twitch.oauth.\(rawValue)" }
}

enum TwitchAuthError: String, LocalizedError {
    case clientID = "Enter the Client ID of a public Twitch application."
    case configurationLocked = "Disconnect both Twitch accounts before changing the Client ID."
    case pending = "Waiting for Twitch authorization."
    case slowDown = "Twitch requested a longer polling interval."
    case expired = "The sign-in code expired. Start a new sign-in."
    case denied = "Twitch sign-in was declined. You can try again."
    case unauthorized = "The Twitch access token is no longer valid."
    case invalidRefresh = "The Twitch session expired or was revoked. Sign in again."
    case invalidGrant = "Twitch returned a different identity, app, or permission set. Sign in again."
    case differentApp = "This account belongs to another Twitch client ID. Disconnect it before signing in again."
    case duplicate = "This account is already linked to the other role. Choose a different Twitch account."
    case service = "Could not complete the request to Twitch. Check your connection and try again."
    case storage = "Could not access the Twitch account in Keychain. Check Keychain access and retry."

    var errorDescription: String? { rawValue }
}

struct TwitchTokenPair: Codable {
    let access_token: String
    let refresh_token: String
}

struct TwitchIdentity: Decodable {
    let user_id: String
    let login: String
    let client_id: String
    let scopes: [String]?
    let expires_in: Int
}

struct TwitchDeviceCode: Decodable {
    let device_code: String
    let user_code: String
    let verification_uri: URL
    let expires_in: Int
    let interval: Int
}

private final class TwitchRedirectPolicy: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

@MainActor
struct TwitchOAuth {
    private static let session = URLSession(configuration: .ephemeral, delegate: TwitchRedirectPolicy(), delegateQueue: nil)
    var send: (URLRequest) async throws -> (Data, URLResponse) = { try await session.data(for: $0) }

    func device(clientID: String, role: TwitchRole) async throws -> TwitchDeviceCode {
        let data = try await request("device", ["client_id": clientID, "scopes": role.scopes.joined(separator: " ")])
        let code = try JSONDecoder().decode(TwitchDeviceCode.self, from: data)
        let url = code.verification_uri
        guard url.scheme == "https", ["www.twitch.tv", "twitch.tv"].contains(url.host),
              url.user == nil, url.password == nil, url.port == nil, url.fragment == nil, url.path == "/activate",
              !code.user_code.isEmpty, !code.device_code.isEmpty,
              (1...86_400).contains(code.expires_in), (1...code.expires_in).contains(code.interval) else {
            throw TwitchAuthError.service
        }
        return code
    }

    func poll(clientID: String, role: TwitchRole, code: String) async throws -> TwitchTokenPair {
        try await tokens(["client_id": clientID, "device_code": code, "scopes": role.scopes.joined(separator: " "),
                          "grant_type": "urn:ietf:params:oauth:grant-type:device_code"])
    }

    func refresh(clientID: String, token: String) async throws -> TwitchTokenPair {
        try await tokens(["client_id": clientID, "grant_type": "refresh_token", "refresh_token": token])
    }

    func validate(_ token: String) async throws -> TwitchIdentity {
        let data = try await request("validate", bearer: token)
        return try JSONDecoder().decode(TwitchIdentity.self, from: data)
    }

    func revoke(clientID: String, token: String) async throws {
        _ = try await request("revoke", ["client_id": clientID, "token": token])
    }

    private func tokens(_ fields: [String: String]) async throws -> TwitchTokenPair {
        let data = try await request("token", fields)
        let pair = try JSONDecoder().decode(TwitchTokenPair.self, from: data)
        guard !pair.access_token.isEmpty, !pair.refresh_token.isEmpty else { throw TwitchAuthError.service }
        return pair
    }

    private func request(_ endpoint: String, _ fields: [String: String] = [:], bearer: String? = nil) async throws -> Data {
        try Task.checkCancellation()
        var request = URLRequest(url: URL(string: "https://id.twitch.tv/oauth2/")!.appendingPathComponent(endpoint),
                                 cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        if let bearer {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        } else {
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            var form = URLComponents()
            form.queryItems = fields.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
            request.httpBody = form.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B").data(using: .utf8)
        }
        let (data, response) = try await send(request)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse else { throw TwitchAuthError.service }
        if http.statusCode == 200 { return data }
        if http.statusCode == 429 { throw TwitchAuthError.slowDown }
        if http.statusCode == 401 { throw TwitchAuthError.unauthorized }
        guard http.statusCode == 400 || http.statusCode == 403 else { throw TwitchAuthError.service }
        struct Failure: Decodable {
            let message: String?
            let error: String?
        }
        let failure = try? JSONDecoder().decode(Failure.self, from: data)
        switch (failure?.message ?? failure?.error)?.lowercased() {
        case "authorization_pending": throw TwitchAuthError.pending
        case "slow_down": throw TwitchAuthError.slowDown
        case "expired_token", "invalid device code": throw TwitchAuthError.expired
        case "access_denied", "authorization_declined": throw TwitchAuthError.denied
        case "invalid refresh token", "invalid_grant":
            throw fields["grant_type"] == "refresh_token" ? TwitchAuthError.invalidRefresh : TwitchAuthError.expired
        default: throw endpoint == "device" ? TwitchAuthError.clientID : TwitchAuthError.service
        }
    }
}
