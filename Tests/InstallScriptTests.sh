#!/bin/sh

set -eu

repository_directory=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
test_directory=$(mktemp -d "${TMPDIR:-/tmp}/trn-install-test.XXXXXX")

cleanup() {
  rm -rf -- "$test_directory"
}
trap cleanup EXIT HUP INT TERM

fixture_directory="${test_directory}/fixtures"
payload_directory="${test_directory}/payload"
fake_bin_directory="${test_directory}/fake-bin"
install_directory="${test_directory}/install-bin"
mkdir -p "$fixture_directory" "$payload_directory" "$fake_bin_directory" "$install_directory"

architecture=$(uname -m)
archive_name="trn-${architecture}-apple-darwin.tar.gz"

cat >"${payload_directory}/trn" <<'SCRIPT'
#!/bin/sh
echo "trn 9.9.9"
SCRIPT
chmod 755 "${payload_directory}/trn"
cp "${repository_directory}/LICENSE" "${payload_directory}/LICENSE"
tar -czf "${fixture_directory}/${archive_name}" -C "$payload_directory" trn LICENSE
archive_checksum=$(shasum -a 256 "${fixture_directory}/${archive_name}" | awk '{ print $1 }')
printf '%s  ./%s\n' "$archive_checksum" "$archive_name" >"${fixture_directory}/SHA256SUMS"

cat >"${fake_bin_directory}/curl" <<'SCRIPT'
#!/bin/sh
set -eu

output_path=""
source_url=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --output)
      output_path=$2
      shift 2
      ;;
    --*) shift ;;
    *)
      source_url=$1
      shift
      ;;
  esac
done

cp "${TRN_INSTALL_FIXTURES}/${source_url##*/}" "$output_path"
SCRIPT
chmod 755 "${fake_bin_directory}/curl"

PATH="${fake_bin_directory}:$PATH" \
  TRN_INSTALL_FIXTURES="$fixture_directory" \
  TRN_RELEASE_BASE_URL="https://example.invalid/releases/latest/download" \
  TRN_INSTALL_DIR="$install_directory" \
  sh "${repository_directory}/install.sh"

installed_version=$("${install_directory}/trn" --version)
if [ "$installed_version" != "trn 9.9.9" ]; then
  echo "Unexpected installed version: $installed_version" >&2
  exit 1
fi

user_home="${test_directory}/user-home"
mkdir -p "$user_home"
PATH="${fake_bin_directory}:$PATH" \
  HOME="$user_home" \
  TRN_INSTALL_FIXTURES="$fixture_directory" \
  TRN_RELEASE_BASE_URL="https://example.invalid/releases/latest/download" \
  sh "${repository_directory}/install.sh" --user

user_installed_version=$("${user_home}/.local/bin/trn" --version)
if [ "$user_installed_version" != "trn 9.9.9" ]; then
  echo "Unexpected user-installed version: $user_installed_version" >&2
  exit 1
fi

custom_install_directory="${test_directory}/custom-bin"
PATH="${fake_bin_directory}:$PATH" \
  HOME="$user_home" \
  TRN_INSTALL_FIXTURES="$fixture_directory" \
  TRN_RELEASE_BASE_URL="https://example.invalid/releases/latest/download" \
  sh "${repository_directory}/install.sh" --user "$custom_install_directory"

custom_installed_version=$("${custom_install_directory}/trn" --version)
if [ "$custom_installed_version" != "trn 9.9.9" ]; then
  echo "Unexpected custom-installed version: $custom_installed_version" >&2
  exit 1
fi

printf '%064d  ./%s\n' 0 "$archive_name" >"${fixture_directory}/SHA256SUMS"
if PATH="${fake_bin_directory}:$PATH" \
  TRN_INSTALL_FIXTURES="$fixture_directory" \
  TRN_RELEASE_BASE_URL="https://example.invalid/releases/latest/download" \
  TRN_INSTALL_DIR="${test_directory}/bad-install" \
  sh "${repository_directory}/install.sh" >/dev/null 2>&1; then
  echo "Installer accepted an invalid checksum" >&2
  exit 1
fi

echo "Install script tests passed."
