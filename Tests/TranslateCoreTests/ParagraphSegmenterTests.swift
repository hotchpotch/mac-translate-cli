import Testing
@testable import TranslateCore

@Suite("Paragraph segmenter")
struct ParagraphSegmenterTests {
    @Test("groups newline-delimited text up to the character limit")
    func groupsLinesUpToLimit() {
        let segmenter = ParagraphSegmenter(maxCharacters: 10)

        let segments = segmenter.segments(from: "aa\nbb\ncc")

        #expect(segments == [
            StreamSegment(index: 0, sourceText: "aa\nbb\ncc", suffix: "", isLast: true)
        ])
    }

    @Test("splits on newline before exceeding the character limit")
    func splitsOnNewlineBeforeLimit() {
        let segmenter = ParagraphSegmenter(maxCharacters: 10)

        let segments = segmenter.segments(from: "12345\n6789\nabcdefghijkl")

        #expect(segments == [
            StreamSegment(index: 0, sourceText: "12345", suffix: "\n", isLast: false),
            StreamSegment(index: 1, sourceText: "6789", suffix: "\n", isLast: false),
            StreamSegment(index: 2, sourceText: "abcdefghij", suffix: "", isLast: false),
            StreamSegment(index: 3, sourceText: "kl", suffix: "", isLast: true)
        ])
    }
}
