#!/usr/bin/env bash
# Screen Corners installer.
#
#   curl -fsSL https://raw.githubusercontent.com/PankovDefi/screen-corners/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --radius 15 --no-autostart
#
# Or from a cloned repo: ./install.sh [--radius N] [--no-autostart]
set -euo pipefail

REPO="${SCREEN_CORNERS_REPO:-PankovDefi/screen-corners}"
BRANCH="${SCREEN_CORNERS_BRANCH:-main}"
APP_NAME="ScreenCorners.app"
BUNDLE_ID="com.screencorners.app"
PLIST="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"
DOMAIN="gui/$(id -u)"

RADIUS=""
AUTOSTART=1

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }
usage() {
  cat <<EOF
Screen Corners installer

Options:
  --radius N       corner radius in points (default 15)
  --no-autostart   don't launch at login
  -h, --help       show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --radius)       RADIUS="${2:-}"; shift 2 || die "--radius needs a value" ;;
    --radius=*)     RADIUS="${1#*=}"; shift ;;
    --no-autostart) AUTOSTART=0; shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              die "Unknown option: $1 (see --help)" ;;
  esac
done

[[ -z "$RADIUS" || "$RADIUS" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "--radius must be a number"
[[ "$(uname -s)" == "Darwin" ]] || die "Screen Corners works on macOS only"

if ! xcode-select -p >/dev/null 2>&1; then
  say "Xcode Command Line Tools are required to build the app. Opening the installer..."
  xcode-select --install >/dev/null 2>&1 || true
  die "Run this command again when Command Line Tools have finished installing."
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Use the local checkout if the script is run from the repo, otherwise download it.
SRC=""
SELF="${BASH_SOURCE[0]:-}"
if [[ -n "$SELF" && -f "$SELF" ]]; then
  DIR="$(cd "$(dirname "$SELF")" && pwd)"
  [[ -f "$DIR/scripts/build.sh" ]] && SRC="$DIR"
fi
if [[ -z "$SRC" ]]; then
  say "Downloading $REPO ($BRANCH)..."
  mkdir -p "$WORK/src"
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" \
    | tar -xz -C "$WORK/src" --strip-components=1 \
    || die "Download failed"
  SRC="$WORK/src"
fi

say "Building..."
if ! bash "$SRC/scripts/build.sh" "$WORK/build" >"$WORK/build.log" 2>&1; then
  cat "$WORK/build.log" >&2
  die "Build failed (log above)"
fi

say "Stopping previous version (if any)..."
launchctl bootout "$DOMAIN/$BUNDLE_ID" >/dev/null 2>&1 || true
pkill -x ScreenCorners >/dev/null 2>&1 || true
sleep 0.5

if [[ -w /Applications ]]; then DEST="/Applications"; else DEST="$HOME/Applications"; fi
mkdir -p "$DEST"
rm -rf "/Applications/$APP_NAME" "$HOME/Applications/$APP_NAME" 2>/dev/null || true
cp -R "$WORK/build/$APP_NAME" "$DEST/"
APP="$DEST/$APP_NAME"
BIN="$APP/Contents/MacOS/ScreenCorners"
say "Installed to $APP"

if [[ -n "$RADIUS" ]]; then
  defaults write "$BUNDLE_ID" radius -float "$RADIUS"
  say "Radius set to $RADIUS pt"
fi

if [[ $AUTOSTART -eq 1 ]]; then
  "$BIN" --register-login-item >/dev/null
  launchctl bootstrap "$DOMAIN" "$PLIST" >/dev/null 2>&1 || open "$APP"
  say "Launch at login: on"
else
  "$BIN" --unregister-login-item >/dev/null || true
  open "$APP"
  say "Launch at login: off"
fi

printf '\n\033[1;32mDone!\033[0m Screen Corners is running — look for its icon in the menu bar.\n'
