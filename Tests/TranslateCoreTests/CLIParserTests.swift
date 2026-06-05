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

    @Test("parses stream flag and concurrency")
    func parsesStreamFlagAndConcurrency() throws {
        let options = try parser.parse(["-s", "--to", "en", "-j", "2", "こんにちは"])

        #expect(options.streamMode == .paragraph)
        #expect(options.concurrency == 2)
    }

    @Test("parses long stream flag and concurrency")
    func parsesLongStreamFlagAndConcurrency() throws {
        let options = try parser.parse(["--stream", "--to", "en", "--concurrency", "3", "こんにちは"])

        #expect(options.streamMode == .paragraph)
        #expect(options.concurrency == 3)
    }

    @Test("rejects invalid concurrency")
    func rejectsInvalidConcurrency() throws {
        #expect(throws: CLIParseError.invalidValue("--concurrency", "0")) {
            try parser.parse(["--to", "en", "--concurrency", "0", "こんにちは"])
        }
    }

    @Test("rejects missing option values")
    func rejectsMissingOptionValue() throws {
        #expect(throws: CLIParseError.missingValue("--to")) {
            try parser.parse(["--to"])
        }
    }
}
