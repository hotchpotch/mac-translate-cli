class Trn < Formula
  desc "Swift command-line translator for macOS using Apple's Translation framework"
  homepage "https://github.com/hotchpotch/mac-translate-cli"
  url "https://github.com/hotchpotch/mac-translate-cli/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "32836d8ece7564dce147a5c402c6123d1e7ad3bbe3586cb2ed6169153580d8b1"
  license "MIT"

  bottle do
    root_url "https://github.com/hotchpotch/mac-translate-cli/releases/download/v0.2.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "962e5d97d0e1af1f62e89e8914ac3505f270496c2a60a44af3d66ab273211e78"
    sha256 cellar: :any_skip_relocation, tahoe:       "b6d49e9db51d774f7ed9152a5eb3da072bebb250ac0819ea14eba2ae7973d69c"
  end

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
