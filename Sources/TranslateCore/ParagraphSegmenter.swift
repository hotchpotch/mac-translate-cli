import Foundation

public struct StreamSegment: Equatable, Sendable {
    public let index: Int
    public let sourceText: String
    public let suffix: String
    public let isLast: Bool

    public init(index: Int, sourceText: String, suffix: String, isLast: Bool) {
        self.index = index
        self.sourceText = sourceText
        self.suffix = suffix
        self.isLast = isLast
    }

    public var outputSuffix: String {
        suffix + (isLast && suffix.isEmpty ? "\n" : "")
    }
}

public struct ParagraphSegmenter: Sendable {
    private let maxCharacters: Int

    public init(maxCharacters: Int = 512) {
        self.maxCharacters = max(1, maxCharacters)
    }

    public func segments(from text: String) -> [StreamSegment] {
        let records = newlineRecords(from: text)
        var chunks: [(sourceText: String, suffix: String)] = []
        var currentText: String?
        var currentSuffix = ""

        func currentLength() -> Int {
            (currentText?.count ?? 0) + currentSuffix.count
        }

        func flushCurrent() {
            guard let currentText else {
                return
            }
            chunks.append((sourceText: currentText, suffix: currentSuffix))
        }

        for record in records {
            let fullLength = record.body.count + record.suffix.count
            if fullLength > maxCharacters {
                flushCurrent()
                currentText = nil
                currentSuffix = ""

                chunks.append(contentsOf: hardSplit(body: record.body, suffix: record.suffix))
                continue
            }

            guard let existingText = currentText else {
                currentText = record.body
                currentSuffix = record.suffix
                continue
            }

            let candidateText = existingText + currentSuffix + record.body
            let candidateSuffix = record.suffix
            if candidateText.count + candidateSuffix.count <= maxCharacters {
                currentText = candidateText
                currentSuffix = candidateSuffix
            } else {
                chunks.append((sourceText: existingText, suffix: currentSuffix))
                currentText = record.body
                currentSuffix = record.suffix
            }

            precondition(currentLength() <= maxCharacters || existingText.isEmpty)
        }

        flushCurrent()

        return chunks.enumerated().map { index, chunk in
            StreamSegment(
                index: index,
                sourceText: chunk.sourceText,
                suffix: chunk.suffix,
                isLast: index == chunks.count - 1
            )
        }
    }

    private func newlineRecords(from text: String) -> [(body: String, suffix: String)] {
        var records: [(body: String, suffix: String)] = []
        var line = ""

        for character in text {
            if character == "\n" {
                records.append((body: line, suffix: "\n"))
                line = ""
            } else {
                line.append(character)
            }
        }

        if !line.isEmpty || text.last != "\n" {
            records.append((body: line, suffix: ""))
        }

        return records
    }

    private func hardSplit(body: String, suffix: String) -> [(sourceText: String, suffix: String)] {
        var remaining = body[...]
        var chunks: [(sourceText: String, suffix: String)] = []

        while !remaining.isEmpty {
            let end = remaining.index(
                remaining.startIndex,
                offsetBy: maxCharacters,
                limitedBy: remaining.endIndex
            ) ?? remaining.endIndex
            let piece = String(remaining[..<end])
            remaining = remaining[end...]
            chunks.append((sourceText: piece, suffix: ""))
        }

        if chunks.isEmpty {
            chunks.append((sourceText: "", suffix: suffix))
        } else if !suffix.isEmpty {
            let last = chunks.removeLast()
            if last.sourceText.count + suffix.count <= maxCharacters {
                chunks.append((sourceText: last.sourceText, suffix: suffix))
            } else {
                chunks.append(last)
                chunks.append((sourceText: "", suffix: suffix))
            }
        }

        return chunks
    }
}

