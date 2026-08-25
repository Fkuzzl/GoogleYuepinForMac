import Foundation

public actor CachedCandidateService: CandidateProviding {
    private let provider: any CandidateProviding
    private let cache: CandidateCache

    public init(provider: any CandidateProviding, cache: CandidateCache) {
        self.provider = provider
        self.cache = cache
    }

    public func candidates(for query: String, limit: Int = 24) async throws -> [Candidate] {
        if let cached = try await cache.candidates(for: query), !cached.isEmpty {
            return Array(cached.prefix(limit))
        }

        do {
            let fetched = try await provider.candidates(for: query, limit: limit)
            if !fetched.isEmpty {
                try await cache.store(fetched, for: query)
            }
            return fetched
        } catch {
            if let stale = try? await cache.candidates(for: query, allowExpired: true), !stale.isEmpty {
                return Array(stale.prefix(limit))
            }
            throw error
        }
    }
}
