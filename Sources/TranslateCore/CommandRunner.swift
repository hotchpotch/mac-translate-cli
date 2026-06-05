import Foundation

public struct CommandResult: Equatable, Sendable {
    public let output: String
    public let errorOutput: String
    public let exitCode: Int32

    public init(output: String, errorOutput: String, exitCode: Int32) {
        self.output = output
        self.errorOutput = errorOutput
        self.exitCode = exitCode
    }
}

public struct CommandRunner<Translator: TextTranslating>: Sendable {
    private let parser: CLIParser
    private let inputResolver: InputResolver
    private let languageResolver: LanguageResolver
    private let translator: Translator

    public init(
        parser: CLIParser = CLIParser(),
        inputResolver: InputResolver = InputResolver(),
        languageResolver: LanguageResolver = LanguageResolver(),
        translator: Translator
    ) {
        self.parser = parser
        self.inputResolver = inputResolver
        self.languageResolver = languageResolver
        self.translator = translator
    }

    public func run(arguments: [String], stdin: String?) async -> CommandResult {
        do {
            let options = try parser.parse(arguments)
            let text = try inputResolver.resolve(options: options, stdin: stdin)
            let request = TranslationRequest(
                sourceText: text,
                sourceLanguageCode: try languageResolver.resolveSource(options.sourceLanguage, text: text),
                targetLanguageCode: try languageResolver.resolveTarget(options.targetLanguage)
            )
            guard request.sourceLanguageCode != request.targetLanguageCode else {
                return CommandResult(output: text + "\n", errorOutput: "", exitCode: 0)
            }

            let result = try await translator.translate(request)
            return CommandResult(output: result.targetText + "\n", errorOutput: "", exitCode: 0)
        } catch {
            let message = "\(error)\n\n\(usage)\n"
            return CommandResult(output: "", errorOutput: message, exitCode: 1)
        }
    }
}
