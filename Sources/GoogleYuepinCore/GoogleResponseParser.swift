import Foundation

public enum GoogleResponseParserError: Error, Equatable {
    case invalidJSON
    case unsuccessfulStatus(String)
    case malformedResponse
}

public enum GoogleResponseParser {
    public static func parse(data: Data, query: String) throws -> [Candidate] {
        let root: Any
        do {
            root = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw GoogleResponseParserError.invalidJSON
        }

        guard let response = root as? [Any],
              let status = response.first as? String else {
            throw GoogleResponseParserError.malformedResponse
        }
        guard status == "SUCCESS" else {
            throw GoogleResponseParserError.unsuccessfulStatus(status)
        }
        guard response.count > 1,
              let resultGroups = response[1] as? [Any],
              let firstGroup = resultGroups.first as? [Any],
              firstGroup.count > 1,
              let words = firstGroup[1] as? [String] else {
            throw GoogleResponseParserError.malformedResponse
        }

        let metadata = firstGroup.count > 3 ? firstGroup[3] as? [String: Any] : nil
        let annotations = metadata?["annotation"] as? [String] ?? []
        let matchedLengths = metadata?["matched_length"] as? [Int] ?? []
        let defaultLength = realInput(from: query).count

        return words.enumerated().map { index, word in
            Candidate(
                text: word,
                annotation: index < annotations.count ? annotations[index] : "",
                matchedLength: index < matchedLengths.count ? matchedLengths[index] : defaultLength
            )
        }
    }

    public static func realInput(from query: String) -> String {
        guard query.hasPrefix("|"), let comma = query.firstIndex(of: ",") else {
            return query
        }
        return String(query[query.index(after: comma)...])
    }
}
