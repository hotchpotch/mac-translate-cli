import Foundation
import NaturalLanguage

public enum LanguageResolverError: Error, Equatable, CustomStringConvertible {
    case unsupportedLanguage(String)
    case unableToDetectLanguage

    public var description: String {
        switch self {
        case let .unsupportedLanguage(language):
            "unsupported language: \(language)"
        case .unableToDetectLanguage:
            "unable to detect source language"
        }
    }
}

public struct TranslationRequest: Equatable, Sendable {
    public let sourceText: String
    public let sourceLanguageCode: String
    public let targetLanguageCode: String

    public init(sourceText: String, sourceLanguageCode: String, targetLanguageCode: String) {
        self.sourceText = sourceText
        self.sourceLanguageCode = sourceLanguageCode
        self.targetLanguageCode = targetLanguageCode
    }
}

public struct LanguageResolver: Sendable {
    private let aliases: [String: String]

    public init(aliases: [String: String] = LanguageResolver.defaultAliases) {
        self.aliases = aliases
    }

    public func resolveTarget(_ language: String) throws -> String {
        try resolve(language)
    }

    public func resolveSource(_ language: String?, text: String) throws -> String {
        if let language {
            return try resolve(language)
        }

        guard let detected = NLLanguageRecognizer.dominantLanguage(for: text),
              detected != .undetermined
        else {
            throw LanguageResolverError.unableToDetectLanguage
        }

        return try resolve(detected.rawValue)
    }

    private func resolve(_ language: String) throws -> String {
        let normalized = language
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")

        if let alias = aliases[normalized] {
            return alias
        }

        let parts = normalized.split(separator: "-")
        if let first = parts.first, first.count == 2 || first.count == 3 {
            return String(first)
        }

        throw LanguageResolverError.unsupportedLanguage(language)
    }

    public static let defaultAliases: [String: String] = [
        "arabic": "ar",
        "ar": "ar",
        "chinese": "zh",
        "zh": "zh",
        "english": "en",
        "en": "en",
        "french": "fr",
        "fr": "fr",
        "german": "de",
        "de": "de",
        "italian": "it",
        "it": "it",
        "japanese": "ja",
        "ja": "ja",
        "korean": "ko",
        "ko": "ko",
        "portuguese": "pt",
        "pt": "pt",
        "russian": "ru",
        "ru": "ru",
        "spanish": "es",
        "es": "es"
    ]
}

