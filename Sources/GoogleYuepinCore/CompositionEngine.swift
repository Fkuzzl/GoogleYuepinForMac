import Foundation

public struct CompositionSegment: Equatable, Sendable {
    public let output: String
    public let matchedInput: String

    public init(output: String, matchedInput: String) {
        self.output = output
        self.matchedInput = matchedInput
    }
}

public enum CompositionEffect: Equatable, Sendable {
    case none
    case needsCandidates
    case commit(String)
    case cancel
}

public struct CompositionEngine: Sendable {
    public static let maximumInputLength = 50
    public static let pageSize = 6

    public private(set) var rawInput = ""
    public private(set) var segments: [CompositionSegment] = []
    public private(set) var candidates: [Candidate] = []
    public private(set) var selectedIndex = 0
    public private(set) var pageNumber = 0

    public init() {}

    public var isComposing: Bool {
        !rawInput.isEmpty || !segments.isEmpty
    }

    public var committedPrefix: String {
        segments.map(\.output).joined()
    }

    public var lookupQuery: String {
        guard !segments.isEmpty else { return rawInput }
        return "|\(committedPrefix),\(rawInput)"
    }

    public var currentPage: [Candidate] {
        let start = pageNumber * Self.pageSize
        guard start < candidates.count else { return [] }
        return Array(candidates[start..<min(start + Self.pageSize, candidates.count)])
    }

    public var selectedCandidate: Candidate? {
        guard selectedIndex >= 0, selectedIndex < candidates.count else { return nil }
        return candidates[selectedIndex]
    }

    public var displayText: String {
        guard let candidate = selectedCandidate, !rawInput.isEmpty else {
            return committedPrefix + rawInput
        }
        let matchedCount = min(max(candidate.matchedLength, 0), rawInput.count)
        let split = rawInput.index(rawInput.startIndex, offsetBy: matchedCount)
        return committedPrefix + candidate.text + String(rawInput[split...])
    }

    @discardableResult
    public mutating func append(letter: Character) -> CompositionEffect {
        guard letter.isASCII, letter.isLetter, totalInputLength < Self.maximumInputLength else {
            return .none
        }
        rawInput.append(contentsOf: String(letter).lowercased())
        resetCandidates()
        return .needsCandidates
    }

    @discardableResult
    public mutating func backspace() -> CompositionEffect {
        if !rawInput.isEmpty {
            rawInput.removeLast()
        } else if let last = segments.popLast() {
            rawInput = last.matchedInput
        } else {
            return .none
        }
        resetCandidates()
        return isComposing ? .needsCandidates : .cancel
    }

    public mutating func apply(candidates newCandidates: [Candidate], for query: String) {
        guard query == lookupQuery else { return }
        candidates = newCandidates
        selectedIndex = 0
        pageNumber = 0
    }

    public mutating func moveSelection(by offset: Int) {
        guard !candidates.isEmpty else { return }
        selectedIndex = min(max(selectedIndex + offset, 0), candidates.count - 1)
        pageNumber = selectedIndex / Self.pageSize
    }

    public mutating func movePage(by offset: Int) {
        guard !candidates.isEmpty else { return }
        let maxPage = (candidates.count - 1) / Self.pageSize
        pageNumber = min(max(pageNumber + offset, 0), maxPage)
        selectedIndex = pageNumber * Self.pageSize
    }

    @discardableResult
    public mutating func selectCandidate(onPage index: Int? = nil) -> CompositionEffect {
        let absoluteIndex = index.map { pageNumber * Self.pageSize + $0 } ?? selectedIndex
        guard absoluteIndex >= 0, absoluteIndex < candidates.count, !rawInput.isEmpty else {
            return .none
        }

        let candidate = candidates[absoluteIndex]
        let matchedCount = min(max(candidate.matchedLength, 1), rawInput.count)
        let split = rawInput.index(rawInput.startIndex, offsetBy: matchedCount)
        let matchedInput = String(rawInput[..<split])
        let remainder = String(rawInput[split...])
        segments.append(CompositionSegment(output: candidate.text, matchedInput: matchedInput))
        rawInput = remainder
        resetCandidates()

        if rawInput.isEmpty {
            let text = committedPrefix
            reset()
            return .commit(text)
        }
        return .needsCandidates
    }

    public mutating func commitRaw() -> CompositionEffect {
        let text = committedPrefix + rawInput
        reset()
        return text.isEmpty ? .none : .commit(text)
    }

    public mutating func cancel() -> CompositionEffect {
        reset()
        return .cancel
    }

    public mutating func reset() {
        rawInput = ""
        segments = []
        resetCandidates()
    }

    private var totalInputLength: Int {
        rawInput.count + segments.reduce(0) { $0 + $1.matchedInput.count }
    }

    private mutating func resetCandidates() {
        candidates = []
        selectedIndex = 0
        pageNumber = 0
    }
}
