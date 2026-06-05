import Testing
@testable import TranslateCore

@Suite("Input resolver")
struct InputResolverTests {
    private let resolver = InputResolver()

    @Test("stdin takes precedence over positional text")
    func stdinTakesPrecedence() throws {
        let options = CLIOptions(targetLanguage: "en", sourceLanguage: nil, positionalText: "positional")

        let text = try resolver.resolve(options: options, stdin: "stdin\n")

        #expect(text == "stdin")
    }

    @Test("falls back to positional text")
    func fallsBackToPositionalText() throws {
        let options = CLIOptions(targetLanguage: "en", sourceLanguage: nil, positionalText: "positional")

        let text = try resolver.resolve(options: options, stdin: nil)

        #expect(text == "positional")
    }

    @Test("requires text")
    func requiresText() throws {
        let options = CLIOptions(targetLanguage: "en", sourceLanguage: nil, positionalText: nil)

        #expect(throws: InputError.missingText) {
            try resolver.resolve(options: options, stdin: nil)
        }
    }
}

