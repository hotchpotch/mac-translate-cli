#!/bin/sh

set -eu

repository_url="https://github.com/hotchpotch/trn"
release_base_url=${TRN_RELEASE_BASE_URL:-"${repository_url}/releases/latest/download"}
install_directory=${TRN_INSTALL_DIR:-/usr/local/bin}
install_for_user=false
user_directory_provided=false

if [ -n "${TRN_INSTALL_DIR:-}" ]; then
  install_for_user=true
fi

usage() {
  cat <<'USAGE'
usage: install.sh [--user [DIRECTORY]]

Install the latest trn release.

  --user [DIRECTORY]  Install without sudo. Defaults to ~/.local/bin.
  --help              Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --user)
      install_for_user=true
      if [ "$#" -gt 1 ]; then
        case "$2" in
          -*) ;;
          *)
            install_directory=$2
            user_directory_provided=true
            shift
            ;;
        esac
      fi
      if [ "$user_directory_provided" = false ]; then
        if [ -z "${HOME:-}" ]; then
          echo "HOME must be set when --user has no directory." >&2
          exit 1
        fi
        install_directory="${HOME}/.local/bin"
      fi
      ;;
    --user=*)
      install_directory=${1#--user=}
      if [ -z "$install_directory" ]; then
        echo "--user directory must not be empty." >&2
        exit 1
      fi
      install_for_user=true
      user_directory_provided=true
      ;;
    --help | -h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

for required_command in uname sw_vers awk curl tar shasum install mktemp mkdir rm; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "Required command not found: $required_command" >&2
    exit 1
  fi
done

if [ "$(uname -s)" != "Darwin" ]; then
  echo "trn supports macOS only." >&2
  exit 1
fi

macos_version=$(sw_vers -productVersion)
macos_major=$(printf '%s\n' "$macos_version" | awk -F. '{ print $1 }')
macos_minor=$(printf '%s\n' "$macos_version" | awk -F. '{ print $2 }')
if [ "$macos_major" -lt 26 ] || { [ "$macos_major" -eq 26 ] && [ "$macos_minor" -lt 4 ]; }; then
  echo "trn requires macOS 26.4 or later. Current version: $macos_version" >&2
  exit 1
fi

architecture=$(uname -m)
case "$architecture" in
  arm64 | x86_64) ;;
  *)
    echo "Unsupported Mac architecture: $architecture" >&2
    exit 1
    ;;
esac

archive_name="trn-${architecture}-apple-darwin.tar.gz"
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/trn-install.XXXXXX")

cleanup() {
  rm -rf -- "$temporary_directory"
}
trap cleanup EXIT HUP INT TERM

download() {
  curl --fail --silent --show-error --location \
    --proto '=https' --proto-redir '=https' --tlsv1.2 \
    --output "$2" "$1"
}

echo "Downloading the latest trn release for $architecture..."
download "${release_base_url}/${archive_name}" "${temporary_directory}/${archive_name}"
download "${release_base_url}/SHA256SUMS" "${temporary_directory}/SHA256SUMS"

expected_checksum=$(awk -v target="./${archive_name}" '$2 == target { print $1; exit }' "${temporary_directory}/SHA256SUMS")
actual_checksum=$(shasum -a 256 "${temporary_directory}/${archive_name}" | awk '{ print $1 }')

if [ -z "$expected_checksum" ] || [ "$expected_checksum" != "$actual_checksum" ]; then
  echo "Checksum verification failed for $archive_name" >&2
  exit 1
fi

tar -xzf "${temporary_directory}/${archive_name}" -C "$temporary_directory"

if [ "$install_for_user" = true ]; then
  if ! mkdir -p "$install_directory" 2>/dev/null; then
    echo "Cannot create user install directory: $install_directory" >&2
    exit 1
  fi
  if [ ! -w "$install_directory" ]; then
    echo "User install directory is not writable: $install_directory" >&2
    exit 1
  fi
  install -m 755 "${temporary_directory}/trn" "${install_directory}/trn"
else
  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required to install to $install_directory." >&2
    exit 1
  fi
  sudo mkdir -p "$install_directory"
  sudo install -m 755 "${temporary_directory}/trn" "${install_directory}/trn"
fi

echo "Installed $("${install_directory}/trn" --version) to ${install_directory}/trn"

if [ "$install_for_user" = true ]; then
  case ":${PATH}:" in
    *":${install_directory}:"*) ;;
    *)
      echo "Add trn to your PATH with:"
      printf '  export PATH="%s:$PATH"\n' "$install_directory"
      ;;
  esac
fi
