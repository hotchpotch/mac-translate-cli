import Testing
@testable import TranslateCore

@Suite("Language resolver")
struct LanguageResolverTests {
    private let resolver = LanguageResolver()

    @Test("resolves language aliases")
    func resolvesAliases() throws {
        #expect(try resolver.resolveTarget("english") == "en")
        #expect(try resolver.resolveTarget("en") == "en")
        #expect(try resolver.resolveTarget("ja-JP") == "ja")
    }

    @Test("uses explicit source language")
    func usesExplicitSourceLanguage() throws {
        #expect(try resolver.resolveSource("japanese", text: "hello") == "ja")
    }

    @Test("detects source language when --from is omitted")
    func detectsSourceLanguage() throws {
        #expect(try resolver.resolveSource(nil, text: "こんにちは") == "ja")
    }
}

