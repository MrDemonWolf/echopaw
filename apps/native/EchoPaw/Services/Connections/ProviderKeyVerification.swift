import Foundation

final class CredentialRedirectPolicy: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

struct ProviderKeyVerification: Sendable {
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = 15
        configuration.httpShouldSetCookies = false
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        return URLSession(configuration: configuration, delegate: CredentialRedirectPolicy(), delegateQueue: nil)
    }()

    private let perform: @Sendable (URLRequest) async throws -> Int

    init(perform: @escaping @Sendable (URLRequest) async throws -> Int = { request in
        let (_, response) = try await session.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode ?? 0
    }) {
        self.perform = perform
    }

    func check(_ key: String, for provider: KeyProvider) async throws {
        var request = URLRequest(url: provider == .openAI
            ? URL(string: "https://api.openai.com/v1/models")!
            : URL(string: "https://api.elevenlabs.io/v2/voices?page_size=1")!,
            cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12)
        if provider == .openAI {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue(key, forHTTPHeaderField: "xi-api-key")
        }

        let status: Int
        do {
            try Task.checkCancellation()
            status = try await perform(request)
            try Task.checkCancellation()
        } catch {
            if Task.isCancelled || error is CancellationError { throw CancellationError() }
            throw KeyVerificationError.unavailable
        }
        switch status {
        case 200: return
        case 401, 403: throw KeyVerificationError.rejected(provider)
        case 429: throw KeyVerificationError.rateLimited
        default: throw KeyVerificationError.unavailable
        }
    }
}

enum KeyVerificationError: LocalizedError, Equatable {
    case rejected(KeyProvider), rateLimited, unavailable

    var errorDescription: String? {
        switch self {
        case .rejected(let provider):
            provider == .openAI
                ? "OpenAI declined the check. Check the key and give it read access to List models."
                : "ElevenLabs declined the check. Check the key, its Voices read permission and any IP restrictions."
        case .rateLimited: "The provider is limiting requests. Wait a moment and try again."
        case .unavailable: "The key check couldn’t finish. Check your connection and try again."
        }
    }
}
