# AGENTS.md

## Project Overview

This repository contains `trn`, a Swift command-line translator for macOS. The CLI uses Apple's Translation framework on macOS 26+ and keeps command parsing, input handling, language resolution, and translation behind testable library code in `TranslateCore`.

## Repository Layout

- `Package.swift`: Swift Package Manager manifest.
- `Sources/TranslateCore/`: reusable core logic for parsing, input resolution, language resolution, and translation.
- `Sources/trn/main.swift`: executable entry point for standard input/output and process exit codes.
- `Tests/TranslateCoreTests/`: unit tests for the core behavior.

## Development Commands

Run the full test suite:

```sh
swift test
```

Build the executable:

```sh
swift build
```

Run the debug executable:

```sh
.build/debug/trn --to en "こんにちは"
printf 'こんにちは\n' | .build/debug/trn --to english
.build/debug/trn --from ja --to en "こんにちは"
```

## Implementation Guidelines

- Keep CLI orchestration thin. `Sources/trn/main.swift` should only handle process arguments, standard input/output, and exit codes.
- Put behavior in `TranslateCore` so it can be tested without invoking a subprocess.
- Prefer protocol-based boundaries for external services. `TextTranslating` exists so tests can use mocks while production uses `AppleTranslator`.
- Keep language aliases deterministic and covered by tests when adding new names.
- Preserve stdin precedence over positional text.
- If source and target languages are the same, return the original text without calling the Translation framework.
- Avoid network translation services by default. This tool is intended to use on-device Apple translation.

## Testing Guidelines

- Follow TDD for behavioral changes: add or update a focused test before changing implementation.
- Add parser tests for new flags or argument behavior.
- Add command runner tests for user-visible CLI behavior and error handling.
- Avoid tests that require installed language packages. Use mock translators for core tests.
- Run `swift test` before committing.

## macOS Translation Notes

- The production translator uses `TranslationSession(installedSource:target:)`.
- Language availability is checked before translation.
- If a required language package is supported but not installed, the CLI reports that the user should install it from System Settings.
- Auto-detection currently uses `NaturalLanguage` before creating the Translation framework request.

## Git Guidelines

- Keep commits small and behavior-focused.
- Do not commit `.build/`, `.swiftpm/`, Xcode user state, or derived artifacts.
- Check `git status --short` before staging.

