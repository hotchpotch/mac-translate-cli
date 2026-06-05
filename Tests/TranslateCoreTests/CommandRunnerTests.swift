import Testing
@testable import TranslateCore

private struct RecordingTranslator: TextTranslating {
    let translateHandler: @Sendable (TranslationRequest) async throws -> TranslationResult

    func translate(_ request: TranslationRequest) async throws -> TranslationResult {
        try await translateHandler(request)
    }
}

@Suite("Command runner")
struct CommandRunnerTests {
    @Test("translates with a mockable translator")
    func translatesWithMockableTranslator() async {
        let translator = RecordingTranslator { request in
            #expect(request.sourceText == "こんにちは")
            #expect(request.sourceLanguageCode == "ja")
            #expect(request.targetLanguageCode == "en")
            return TranslationResult(
                sourceLanguageCode: request.sourceLanguageCode,
                targetLanguageCode: request.targetLanguageCode,
                sourceText: request.sourceText,
                targetText: "Hello"
            )
        }
        let runner = CommandRunner(translator: translator)

        let result = await runner.run(arguments: ["--to", "en", "こんにちは"], stdin: nil)

        #expect(result == CommandResult(output: "Hello\n", errorOutput: "", exitCode: 0))
    }

    @Test("returns usage on failure")
    func returnsUsageOnFailure() async {
        let runner = CommandRunner(translator: MockTranslator())

        let result = await runner.run(arguments: ["こんにちは"], stdin: nil)

        #expect(result.exitCode == 1)
        #expect(result.output == "")
        #expect(result.errorOutput.contains("usage: trn"))
    }

    @Test("returns original text when source and target are the same")
    func returnsOriginalForSameLanguage() async {
        let runner = CommandRunner(translator: MockTranslator())

        let result = await runner.run(arguments: ["--to", "en", "hello"], stdin: nil)

        #expect(result == CommandResult(output: "hello\n", errorOutput: "", exitCode: 0))
    }
}
