#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_NAME="xfrmgen"
BIN_DIR="${BIN_DIR:-$ROOT_DIR/bin}"

OS="$(uname -s)"
if [[ "$OS" != "Linux" ]]; then
  echo "This tool supports Linux only. Detected: $OS"
  exit 1
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required."
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "tar is required."
  exit 1
fi

REPO="${REPO:-sudogeeker/go-xfrm}"
if [[ -z "$REPO" ]]; then
  if git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    origin="$(git -C "$ROOT_DIR" config --get remote.origin.url || true)"
    if [[ "$origin" =~ github\.com[:/]+([^/]+/[^/]+?)(\.git)?$ ]]; then
      REPO="${BASH_REMATCH[1]}"
    fi
  fi
fi

if [[ -z "$REPO" ]]; then
  echo "Could not determine GitHub repo. Set REPO=owner/repo and re-run."
  exit 1
fi

API="https://api.github.com/repos/${REPO}/releases/latest"
AUTH_HEADERS=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH_HEADERS=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

json="$(curl -fsSL "${AUTH_HEADERS[@]}" "$API")"
asset_url="$(echo "$json" | grep -Eo 'https://[^"]+linux_'"$ARCH"'\\.tar\\.gz' | head -n1)"

if [[ -z "$asset_url" ]]; then
  echo "Could not find a linux_${ARCH} release asset for ${REPO}."
  exit 1
fi

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

archive="$tmpdir/pkg.tar.gz"
curl -fsSL "${AUTH_HEADERS[@]}" "$asset_url" -o "$archive"
tar -xzf "$archive" -C "$tmpdir"

bin_path="$(find "$tmpdir" -maxdepth 2 -type f -name "$BIN_NAME" -print -quit)"
if [[ -z "$bin_path" ]]; then
  echo "Binary ${BIN_NAME} not found in release archive."
  exit 1
fi

mkdir -p "$BIN_DIR"
cp "$bin_path" "$BIN_DIR/$BIN_NAME"
chmod +x "$BIN_DIR/$BIN_NAME"

echo "Installed: $BIN_DIR/$BIN_NAME"

if [[ "${RUN_AFTER_DOWNLOAD:-1}" != "1" ]]; then
  exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    sudo "$BIN_DIR/$BIN_NAME" "$@"
  else
    echo "Run as root: $BIN_DIR/$BIN_NAME $*"
    exit 1
  fi
else
  "$BIN_DIR/$BIN_NAME" "$@"
fi
