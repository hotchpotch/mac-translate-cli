import Foundation

public struct TranslationResult: Equatable, Sendable {
    public let sourceLanguageCode: String
    public let targetLanguageCode: String
    public let sourceText: String
    public let targetText: String

    public init(sourceLanguageCode: String, targetLanguageCode: String, sourceText: String, targetText: String) {
        self.sourceLanguageCode = sourceLanguageCode
        self.targetLanguageCode = targetLanguageCode
        self.sourceText = sourceText
        self.targetText = targetText
    }
}

public protocol TextTranslating: Sendable {
    func translate(_ request: TranslationRequest) async throws -> TranslationResult
}

public struct MockTranslator: TextTranslating {
    public init() {}

    public func translate(_ request: TranslationRequest) async throws -> TranslationResult {
        TranslationResult(
            sourceLanguageCode: request.sourceLanguageCode,
            targetLanguageCode: request.targetLanguageCode,
            sourceText: request.sourceText,
            targetText: "[\(request.targetLanguageCode)] \(request.sourceText)"
        )
    }
}

