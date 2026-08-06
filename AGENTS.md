# AGENTS.md

## Project Overview

This repository contains `trn`, a Swift command-line translator for macOS. The CLI uses Apple's Translation framework on macOS 26.4+ and keeps command parsing, input handling, language resolution, and translation behind testable library code in `TranslateCore`.

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
.build/debug/trn --to en --quality low "こんにちは"
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
- Keep translation quality deterministic: `low` is the default, `high` is the only alternate value, and both must be covered by parser and command runner tests.
- Avoid network translation services by default. This tool is intended to use on-device Apple translation.

## Testing Guidelines

- Follow TDD for behavioral changes: add or update a focused test before changing implementation.
- Add parser tests for new flags or argument behavior.
- Add command runner tests for user-visible CLI behavior and error handling.
- Avoid tests that require installed language packages. Use mock translators for core tests.
- Run `swift test` before committing.

## macOS Translation Notes

- The production translator uses `TranslationSession(installedSource:target:preferredStrategy:)`.
- Language availability is checked before translation using the same preferred strategy as the translation session.
- `--quality high` maps to `TranslationSession.Strategy.highFidelity`; `--quality low` maps to `TranslationSession.Strategy.lowLatency`.
- If a required language package is supported but not installed, the CLI reports that the user should install it from System Settings.
- Auto-detection currently uses `NaturalLanguage` before creating the Translation framework request.

## Git Guidelines

- Keep commits small and behavior-focused.
- Do not commit `.build/`, `.swiftpm/`, Xcode user state, or derived artifacts.
- Check `git status --short` before staging.

## Release and Homebrew Guidelines

- Keep the CLI version in `Sources/TranslateCore/CLIOptions.swift` (`trnVersion`) in sync with the release tag.
- Before tagging, run `swift test` and confirm a release build with Command Line Tools:

```sh
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift build -c release --disable-sandbox
```

- Push the release commit to `main`, then create and push an annotated release tag:

```sh
git tag -a v0.2.0 -m "v0.2.0"
git push origin main v0.2.0
```

- Pushing a version tag runs `.github/workflows/release.yml`. The workflow:
  - verifies that the tag matches `trnVersion` and runs the tests;
  - builds Apple Silicon and Intel standalone binaries with stable asset names so `/releases/latest/download/...` URLs keep working;
  - builds and tests Homebrew bottles for both architectures;
  - publishes the binaries, bottles, and checksums to GitHub Releases; and
  - updates `Formula/trn.rb` on `main` with the tag archive checksum and bottle metadata.
- If the workflow needs to be rerun, use its manual trigger with the existing version tag.
- Do not manually put a not-yet-known tag archive checksum or bottle checksum in `Formula/trn.rb` before tagging. Until the release workflow completes, the formula should continue to describe the previous published release.
- After the workflow succeeds, verify the release assets and confirm that the formula update commit landed on `main`:

```sh
gh release view v0.2.0
git pull --ff-only origin main
brew update
```

- Verify that Homebrew pours the bottle from the tap:

```sh
brew tap hotchpotch/mac-translate-cli https://github.com/hotchpotch/mac-translate-cli
brew reinstall --force-bottle hotchpotch/mac-translate-cli/trn
brew test hotchpotch/mac-translate-cli/trn
```
