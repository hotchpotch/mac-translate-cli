# mac-translate-cli: `trn` command

`mac-translate-cli` provides `trn`, a small Swift command-line translator for macOS 26.4 Tahoe or later.

- 🍎 Uses the macOS built-in Translation framework, optimized for Apple Silicon.
- ⚡ Fast in everyday use because translation runs through Apple's on-device system translation service.
- 💸 Free to use: no paid translation API key or subscription is required.
- 🔒 Fully local: your source text does not need to be sent to a remote translation API.
- 🛠️ Secure and convenient for private notes, documents, shell pipelines, and developer workflows.
- 🎛️ Select high-quality Apple Intelligence translation or low-latency traditional translation with `--quality`.
- 📊 The [quality report](translation-quality-check.md) found `low` sufficient for the tested English/Japanese cases, while running about 10x faster than `high`.

## Install

Install `trn` with Homebrew:

```sh
brew tap hotchpotch/mac-translate-cli https://github.com/hotchpotch/mac-translate-cli
brew install hotchpotch/mac-translate-cli/trn
```

Run a translation:

```sh
trn --to ja "Hello world!"
#=> こんにちは、世界！
```

Use it in a pipeline:

```sh
echo "Hello world!" | trn --to ja
#=> こんにちは、世界！
```

## Requirements

- macOS 26.4 Tahoe or later
- Command Line Tools with the macOS 26.4 SDK or later for building the executable
- Xcode with the macOS 26.4 SDK or later for running the test suite
- Installed Apple translation language packages for the language pairs you want to use

If a required language package is supported but not installed, `trn` reports that the package needs to be installed from System Settings.

## Usage

`trn` behaves like a Unix-style filter: it accepts text from standard input, buffers it into translation chunks, translates the chunks concurrently, and writes the translated text to standard output in the original order. You can also pass one positional text argument for quick one-off translations.

Quality-sensitive evaluation:

```sh
trn --from en --to ja --quality high "Hello world!"
trn --from en --to ja --quality low "Hello world!"
```

`low` is the default and is usually the practical choice for English/Japanese translation. Use `--quality high` when you want to compare against Apple's high-fidelity translation model or inspect whether a specific sentence benefits from it.

Basic translation:

```sh
trn --to ja "Hello world!"
#=> こんにちは、世界！
```

Use a language name instead of a language code:

```sh
trn --to japanese "Hello world!"
#=> こんにちは、世界！
```

Read source text from standard input:

```sh
echo "Hello world!" | trn --to ja
#=> こんにちは、世界！
```

Specify the source language explicitly:

```sh
trn --from en --to ja "Hello world!"
#=> こんにちは、世界！
```

Choose translation quality:

```sh
trn --to ja --quality high "Hello world!"
trn --to ja -q low "Hello world!"
```

`low` is the default and uses Apple's lower-latency traditional translation models. `high` uses Apple Intelligence high-fidelity translation when available.

If `--from` is omitted, `trn` auto-detects the source language from the input text before creating the translation request:

```sh
trn --to en "こんにちは、世界！"
#=> Hello, world!
```

## Buffered Translation

Buffered paragraph translation is the default. `trn` splits input on newlines and keeps each chunk at or below 512 characters when possible. The `-s` / `--stream` flag is still accepted for clarity and backward compatibility, but it is not required.

```sh
cat notes.txt | trn --to ja
```

The default maximum concurrency is `4`. You can change it with `-j` or `--concurrency`:

```sh
cat notes.txt | trn --to ja --concurrency 2
cat notes.txt | trn --to ja -j 2
```

Buffered chunks are translated concurrently, but output order is preserved.

When `--from` is omitted, `trn` detects the source language once from the full input and reuses that language for every chunk.

Change the translation buffer size with `-b` or `--buffer-size`. The value is a character count. Smaller buffers start work sooner and can reduce per-request size; larger buffers preserve more context per translation request.

```sh
cat notes.txt | trn --to ja --buffer-size 256
cat notes.txt | trn --to ja -b 1024
```

Example:

```sh
printf 'Hello world!\nGood morning.\n' | trn --to ja --concurrency 2
#=> こんにちは、世界！
#=>
#=> おはようございます。
```

## Local Build

Build the debug executable:

```sh
swift build
```

Run the executable from the build directory:

```sh
.build/debug/trn --to ja "Hello world!"
#=> こんにちは、世界！
```

Build a release executable:

```sh
swift build -c release
```

Copy the release binary into a directory on your `PATH`.

For a user-local bin directory:

```sh
mkdir -p ~/.bin
cp .build/release/trn ~/.bin/
```

For a system-wide install location:

```sh
sudo cp .build/release/trn /usr/local/bin/
```

After copying, confirm that the command is available:

```sh
trn --to ja "Hello world!"
#=> こんにちは、世界！
```

## Development

Run the test suite:

```sh
swift test
```

The tests use Swift Testing, so run them with Xcode selected rather than Command Line Tools only.

Build the package:

```sh
swift build
```

The core behavior lives in `Sources/TranslateCore/` so it can be tested without launching a subprocess. The executable entry point is `Sources/trn/main.swift`.

## License

MIT License. See [LICENSE](LICENSE).

## Author

Yuichi Tateno ([@hotchpotch](https://github.com/hotchpotch))
