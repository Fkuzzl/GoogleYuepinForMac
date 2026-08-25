import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol CandidateProviding: Sendable {
    func candidates(for query: String, limit: Int) async throws -> [Candidate]
}

public enum GoogleCandidateProviderError: Error {
    case invalidURL
    case invalidHTTPStatus(Int)
}

public struct GoogleCandidateProvider: CandidateProviding, Sendable {
    public static let endpoint = URL(string: "https://inputtools.google.com/request")!

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func candidates(for query: String, limit: Int = 24) async throws -> [Candidate] {
        guard var components = URLComponents(url: Self.endpoint, resolvingAgainstBaseURL: false) else {
            throw GoogleCandidateProviderError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "text", value: query),
            URLQueryItem(name: "itc", value: "yue-hant-t-i0-und"),
            URLQueryItem(name: "num", value: String(max(1, limit))),
            URLQueryItem(name: "ie", value: "utf-8"),
            URLQueryItem(name: "oe", value: "utf-8"),
        ]
        guard let url = components.url else {
            throw GoogleCandidateProviderError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 2.5
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("GoogleYuepinForMac/0.1", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw GoogleCandidateProviderError.invalidHTTPStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return try GoogleResponseParser.parse(data: data, query: query)
    }
}
