import Foundation

public struct Candidate: Codable, Equatable, Hashable, Sendable {
    public let text: String
    public let annotation: String
    public let matchedLength: Int

    public init(text: String, annotation: String = "", matchedLength: Int) {
        self.text = text
        self.annotation = annotation
        self.matchedLength = matchedLength
    }
}

public struct CandidatePage: Equatable, Sendable {
    public let query: String
    public let pageNumber: Int
    public let pageSize: Int
    public let candidates: [Candidate]

    public init(query: String, pageNumber: Int, pageSize: Int = 6, candidates: [Candidate]) {
        self.query = query
        self.pageNumber = pageNumber
        self.pageSize = pageSize
        let start = max(0, pageNumber) * pageSize
        guard start < candidates.count else {
            self.candidates = []
            return
        }
        let end = min(start + pageSize, candidates.count)
        self.candidates = Array(candidates[start..<end])
    }
}
