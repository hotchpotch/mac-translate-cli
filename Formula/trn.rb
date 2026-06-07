class Trn < Formula
  desc "Swift command-line translator for macOS using Apple's Translation framework"
  homepage "https://github.com/hotchpotch/mac-translate-cli"
  url "https://github.com/hotchpotch/mac-translate-cli/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "856f7f0cc361474d16c5224f98fb2ada3541e2b9e9c3a01b5b08154fec7b5959"
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
