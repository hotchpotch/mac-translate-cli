import Foundation

public struct CLIOptions: Equatable, Sendable {
    public let targetLanguage: String
    public let sourceLanguage: String?
    public let positionalText: String?
    public let streamMode: StreamMode
    public let concurrency: Int

    public init(
        targetLanguage: String,
        sourceLanguage: String?,
        positionalText: String?,
        streamMode: StreamMode = .disabled,
        concurrency: Int = 4
    ) {
        self.targetLanguage = targetLanguage
        self.sourceLanguage = sourceLanguage
        self.positionalText = positionalText
        self.streamMode = streamMode
        self.concurrency = concurrency
    }
}

public enum StreamMode: Equatable, Sendable {
    case disabled
    case paragraph
}

public enum CLIParseError: Error, Equatable, CustomStringConvertible {
    case missingRequiredTo
    case missingValue(String)
    case invalidValue(String, String)
    case unknownOption(String)
    case tooManyPositionalArguments

    public var description: String {
        switch self {
        case .missingRequiredTo:
            "missing required option: --to"
        case let .missingValue(option):
            "missing value for \(option)"
        case let .invalidValue(option, value):
            "invalid value for \(option): \(value)"
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
        var streamMode = StreamMode.disabled
        var concurrency = 4
        var positionals: [String] = []
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--to":
                targetLanguage = try value(after: argument, in: arguments, index: &index)
            case "--from":
                sourceLanguage = try value(after: argument, in: arguments, index: &index)
            case "-s", "--stream":
                streamMode = .paragraph
                index += 1
            case "-j", "--concurrency":
                let concurrencyValue = try value(after: argument, in: arguments, index: &index)
                guard let parsedConcurrency = Int(concurrencyValue), parsedConcurrency > 0 else {
                    throw CLIParseError.invalidValue(argument, concurrencyValue)
                }
                concurrency = parsedConcurrency
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
            positionalText: positionals.first,
            streamMode: streamMode,
            concurrency: concurrency
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
usage: trn --to <language> [--from <language>] [-s|--stream] [-j|--concurrency <count>] [text]

examples:
  trn --to en "こんにちは"
  echo "こんにちは" | trn --to english
  cat notes.txt | trn --to en --stream --concurrency 4
  trn --from ja --to en "こんにちは"
"""
