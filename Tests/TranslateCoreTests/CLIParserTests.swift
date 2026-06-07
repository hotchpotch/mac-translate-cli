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
        #expect(options.streamMode == .paragraph)
        #expect(options.bufferSize == 512)
    }

    @Test("parses help command")
    func parsesHelpCommand() throws {
        #expect(try parser.parseCommand(["--help"]) == .help)
        #expect(try parser.parseCommand(["-h"]) == .help)
    }

    @Test("parses version command")
    func parsesVersionCommand() throws {
        #expect(try parser.parseCommand(["--version"]) == .version)
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

    @Test("parses buffer size")
    func parsesBufferSize() throws {
        let options = try parser.parse(["--to", "en", "--buffer-size", "128", "こんにちは"])

        #expect(options.streamMode == .paragraph)
        #expect(options.bufferSize == 128)
    }

    @Test("parses short buffer size")
    func parsesShortBufferSize() throws {
        let options = try parser.parse(["--to", "en", "-b", "256", "こんにちは"])

        #expect(options.bufferSize == 256)
    }

    @Test("rejects invalid concurrency")
    func rejectsInvalidConcurrency() throws {
        #expect(throws: CLIParseError.invalidValue("--concurrency", "0")) {
            try parser.parse(["--to", "en", "--concurrency", "0", "こんにちは"])
        }
    }

    @Test("rejects invalid buffer size")
    func rejectsInvalidBufferSize() throws {
        #expect(throws: CLIParseError.invalidValue("--buffer-size", "0")) {
            try parser.parse(["--to", "en", "--buffer-size", "0", "こんにちは"])
        }
    }

    @Test("rejects missing option values")
    func rejectsMissingOptionValue() throws {
        #expect(throws: CLIParseError.missingValue("--to")) {
            try parser.parse(["--to"])
        }
    }
}
