import Foundation

public enum InputError: Error, Equatable, CustomStringConvertible {
    case missingText

    public var description: String {
        switch self {
        case .missingText:
            "missing text: provide stdin or a positional text argument"
        }
    }
}

public struct InputResolver: Sendable {
    public init() {}

    public func resolve(options: CLIOptions, stdin: String?) throws -> String {
        if let stdin, !stdin.isEmpty {
            return stdin.trimmingTrailingNewlines()
        }

        if let positionalText = options.positionalText, !positionalText.isEmpty {
            return positionalText
        }

        throw InputError.missingText
    }
}

extension String {
    fileprivate func trimmingTrailingNewlines() -> String {
        var result = self
        while result.last == "\n" || result.last == "\r" {
            result.removeLast()
        }
        return result
    }
}

