enum ChinesePunctuation {
    private static var doubleQuoteOpens = true
    private static var singleQuoteOpens = true

    static func replacement(for text: String) -> String? {
        switch text {
        case "-": return "－"
        case "[": return "【"
        case "]": return "】"
        case ";": return "；"
        case ",": return "，"
        case ".": return "。"
        case "/": return "／"
        case "\\": return "、"
        case "~": return "～"
        case "!": return "！"
        case "@": return "＠"
        case "#": return "＃"
        case "$": return "￥"
        case "^": return "……"
        case "&": return "＆"
        case "*": return "×"
        case "(": return "（"
        case ")": return "）"
        case "_": return "——"
        case "{": return "｛"
        case "}": return "｝"
        case ":": return "："
        case "<": return "《"
        case ">": return "》"
        case "?": return "？"
        case "'":
            defer { singleQuoteOpens.toggle() }
            return singleQuoteOpens ? "「" : "」"
        case "\"":
            defer { doubleQuoteOpens.toggle() }
            return doubleQuoteOpens ? "『" : "』"
        default:
            return nil
        }
    }
}
