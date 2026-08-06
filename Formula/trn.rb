class Trn < Formula
  desc "Swift command-line translator for macOS using Apple's Translation framework"
  homepage "https://github.com/hotchpotch/mac-translate-cli"
  url "https://github.com/hotchpotch/mac-translate-cli/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "a682d1a80decc9ff574b264e11988e6439f687248d9d79a1c4049a6541901c85"
  license "MIT"

  depends_on macos: :tahoe

  def install
    if OS.mac?
      macos_version = Version.new(Utils.safe_popen_read("/usr/bin/sw_vers", "-productVersion").strip)
      odie "trn requires macOS 26.4 or later." if macos_version < Version.new("26.4")
    end

    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/trn"
  end

  test do
    assert_equal "hello", shell_output("#{bin}/trn --from en --to en hello").strip
  end
end
