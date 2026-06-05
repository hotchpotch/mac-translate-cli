import Testing
@testable import TranslateCore

@Suite("CLI parser")
struct CLIParserTests {
    private let parser = CLIParser()

    @Test("requires --to")
    func requiresTo() throws {
        #expect(throws: CLIParseError.missingRequiredTo) {
            try parser.parse(["hello"])
        }
    }

    @Test("parses target and positional text")
    func parsesTargetAndText() throws {
        let options = try parser.parse(["--to", "en", "こんにちは"])

        #expect(options == CLIOptions(targetLanguage: "en", sourceLanguage: nil, positionalText: "こんにちは"))
    }

    @Test("parses source language")
    func parsesSourceLanguage() throws {
        let options = try parser.parse(["--from", "ja", "--to", "english", "こんにちは"])

        #expect(options == CLIOptions(targetLanguage: "english", sourceLanguage: "ja", positionalText: "こんにちは"))
    }

    @Test("rejects missing option values")
    func rejectsMissingOptionValue() throws {
        #expect(throws: CLIParseError.missingValue("--to")) {
            try parser.parse(["--to"])
        }
    }
}

