class Trn < Formula
  desc "Swift command-line translator for macOS using Apple's Translation framework"
  homepage "https://github.com/hotchpotch/mac-translate-cli"
  url "https://github.com/hotchpotch/mac-translate-cli.git", tag: "v0.1.0"
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
