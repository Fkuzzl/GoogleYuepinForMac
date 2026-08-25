import XCTest
@testable import GoogleYuepinCore

final class CompositionEngineTests: XCTestCase {
    func testSimpleCandidateCommit() {
        var engine = CompositionEngine()
        for character in "nei" {
            XCTAssertEqual(engine.append(letter: character), .needsCandidates)
        }
        XCTAssertEqual(engine.lookupQuery, "nei")

        engine.apply(
            candidates: [Candidate(text: "你", annotation: "nei", matchedLength: 3)],
            for: "nei"
        )

        XCTAssertEqual(engine.displayText, "你")
        XCTAssertEqual(engine.selectCandidate(), .commit("你"))
        XCTAssertFalse(engine.isComposing)
    }

    func testPartialCandidateKeepsRemainderAndContext() {
        var engine = CompositionEngine()
        for character in "neihou" { _ = engine.append(letter: character) }
        engine.apply(
            candidates: [Candidate(text: "你", annotation: "nei", matchedLength: 3)],
            for: "neihou"
        )

        XCTAssertEqual(engine.selectCandidate(), .needsCandidates)
        XCTAssertEqual(engine.rawInput, "hou")
        XCTAssertEqual(engine.committedPrefix, "你")
        XCTAssertEqual(engine.lookupQuery, "|你,hou")
    }

    func testBackspaceReopensPreviousSegment() {
        var engine = CompositionEngine()
        for character in "neihou" { _ = engine.append(letter: character) }
        engine.apply(
            candidates: [Candidate(text: "你", matchedLength: 3)],
            for: "neihou"
        )
        _ = engine.selectCandidate()
        while !engine.rawInput.isEmpty { _ = engine.backspace() }

        XCTAssertEqual(engine.backspace(), .needsCandidates)
        XCTAssertEqual(engine.rawInput, "nei")
        XCTAssertTrue(engine.segments.isEmpty)
    }

    func testStaleCandidateResponseIsIgnored() {
        var engine = CompositionEngine()
        for character in "nei" { _ = engine.append(letter: character) }
        let oldQuery = engine.lookupQuery
        _ = engine.append(letter: "h")

        engine.apply(candidates: [Candidate(text: "你", matchedLength: 3)], for: oldQuery)
        XCTAssertTrue(engine.candidates.isEmpty)
        XCTAssertEqual(engine.rawInput, "neih")
    }

    func testPaginationAndNumberSelection() {
        var engine = CompositionEngine()
        for character in "nei" { _ = engine.append(letter: character) }
        let candidates = (0..<12).map { Candidate(text: "候\($0)", matchedLength: 3) }
        engine.apply(candidates: candidates, for: "nei")

        engine.movePage(by: 1)
        XCTAssertEqual(engine.pageNumber, 1)
        XCTAssertEqual(engine.currentPage.first?.text, "候6")
        XCTAssertEqual(engine.selectCandidate(onPage: 2), .commit("候8"))
    }

    func testInputLengthIsBounded() {
        var engine = CompositionEngine()
        for _ in 0..<60 { _ = engine.append(letter: "a") }
        XCTAssertEqual(engine.rawInput.count, CompositionEngine.maximumInputLength)
    }
}
