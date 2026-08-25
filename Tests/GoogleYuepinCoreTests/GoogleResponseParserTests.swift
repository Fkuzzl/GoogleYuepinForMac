import Foundation
import XCTest
@testable import GoogleYuepinCore

final class GoogleResponseParserTests: XCTestCase {
    func testParsesCurrentGoogleResponseShape() throws {
        let data = try fixture(named: "nei-success")
        let candidates = try GoogleResponseParser.parse(data: data, query: "nei")

        XCTAssertEqual(candidates.count, 6)
        XCTAssertEqual(candidates.first, Candidate(text: "你", annotation: "nei", matchedLength: 3))
        XCTAssertEqual(candidates.last?.text, "尼")
    }

    func testParsesMatchedLengths() throws {
        let data = try fixture(named: "partial-match")
        let candidates = try GoogleResponseParser.parse(data: data, query: "neihou")

        XCTAssertEqual(candidates.map(\.matchedLength), [6, 3])
    }

    func testUsesRealInputLengthForContextQuery() throws {
        let data = try fixture(named: "nei-success")
        let candidates = try GoogleResponseParser.parse(data: data, query: "|我,nei")

        XCTAssertEqual(candidates.first?.matchedLength, 3)
        XCTAssertEqual(GoogleResponseParser.realInput(from: "|我,nei"), "nei")
    }

    func testRejectsUnsuccessfulResponse() throws {
        let data = Data("[\"ERROR\",[]]".utf8)
        XCTAssertThrowsError(try GoogleResponseParser.parse(data: data, query: "nei")) { error in
            XCTAssertEqual(error as? GoogleResponseParserError, .unsuccessfulStatus("ERROR"))
        }
    }

    private func fixture(named name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
}
