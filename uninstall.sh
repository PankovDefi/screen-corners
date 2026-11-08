#!/usr/bin/env bash
# Removes Screen Corners, its launch agent and settings.
#   curl -fsSL https://raw.githubusercontent.com/PankovDefi/screen-corners/main/uninstall.sh | bash
set -euo pipefail

BUNDLE_ID="com.screencorners.app"
PLIST="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"

launchctl bootout "gui/$(id -u)/$BUNDLE_ID" >/dev/null 2>&1 || true
pkill -x ScreenCorners >/dev/null 2>&1 || true
rm -f "$PLIST"

for app in "/Applications/ScreenCorners.app" "$HOME/Applications/ScreenCorners.app"; do
  if [[ -d "$app" ]]; then
    rm -rf "$app" 2>/dev/null || echo "Couldn't remove $app — delete it manually (needs admin rights)."
  fi
done

defaults delete "$BUNDLE_ID" >/dev/null 2>&1 || true

echo "Screen Corners removed."
