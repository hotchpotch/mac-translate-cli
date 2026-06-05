import Foundation

public struct CLIOptions: Equatable, Sendable {
    public let targetLanguage: String
    public let sourceLanguage: String?
    public let positionalText: String?

    public init(targetLanguage: String, sourceLanguage: String?, positionalText: String?) {
        self.targetLanguage = targetLanguage
        self.sourceLanguage = sourceLanguage
        self.positionalText = positionalText
    }
}

public enum CLIParseError: Error, Equatable, CustomStringConvertible {
    case missingRequiredTo
    case missingValue(String)
    case unknownOption(String)
    case tooManyPositionalArguments

    public var description: String {
        switch self {
        case .missingRequiredTo:
            "missing required option: --to"
        case let .missingValue(option):
            "missing value for \(option)"
        case let .unknownOption(option):
            "unknown option: \(option)"
        case .tooManyPositionalArguments:
            "too many positional arguments"
        }
    }
}

public struct CLIParser: Sendable {
    public init() {}

    public func parse(_ arguments: [String]) throws -> CLIOptions {
        var targetLanguage: String?
        var sourceLanguage: String?
        var positionals: [String] = []
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--to":
                targetLanguage = try value(after: argument, in: arguments, index: &index)
            case "--from":
                sourceLanguage = try value(after: argument, in: arguments, index: &index)
            default:
                if argument.hasPrefix("--") {
                    throw CLIParseError.unknownOption(argument)
                }
                positionals.append(argument)
                index += 1
            }
        }

        guard let targetLanguage else {
            throw CLIParseError.missingRequiredTo
        }

        guard positionals.count <= 1 else {
            throw CLIParseError.tooManyPositionalArguments
        }

        return CLIOptions(
            targetLanguage: targetLanguage,
            sourceLanguage: sourceLanguage,
            positionalText: positionals.first
        )
    }

    private func value(after option: String, in arguments: [String], index: inout Int) throws -> String {
        let valueIndex = index + 1
        guard valueIndex < arguments.count else {
            throw CLIParseError.missingValue(option)
        }
        let value = arguments[valueIndex]
        guard !value.hasPrefix("--") else {
            throw CLIParseError.missingValue(option)
        }
        index += 2
        return value
    }
}

public let usage = """
usage: trn --to <language> [--from <language>] [text]

examples:
  trn --to en "こんにちは"
  echo "こんにちは" | trn --to english
  trn --from ja --to en "こんにちは"
"""

