class Trn < Formula
  desc "Swift command-line translator for macOS using Apple's Translation framework"
  homepage "https://github.com/hotchpotch/mac-translate-cli"
  url "https://github.com/hotchpotch/mac-translate-cli/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "829863c381e9906fd7f40fbba63af06bd79d0fe0e963b56d86ba37bffe1cac4d"
  license "MIT"

  depends_on macos: :tahoe

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/trn"
  end

  test do
    assert_equal "hello", shell_output("#{bin}/trn --from en --to en hello").strip
  end
end
