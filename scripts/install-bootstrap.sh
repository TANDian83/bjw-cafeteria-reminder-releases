#!/bin/bash
# install-bootstrap.sh — install BJW Cafeteria Reminder without cloning the repo.
#
# Usage: curl -fsSL <url>/scripts/install-bootstrap.sh | bash
#
# What this does:
#   1. Downloads latest.json + latest.json.minisig from GitHub Releases
#   2. Verifies Ed25519 signature (minisign)
#   3. Downloads + verifies zip (SHA-256)
#   4. Installs .app to /Applications/, helpers to ~/.bjw-cafeteria/bin/
#   5. Installs Skill via agency plugin install (or fallback copy)
#   6. Launches the app
set -euo pipefail

# -- Config -------------------------------------------------------------------
REPO_SLUG="TANDian83/bjw-cafeteria-reminder-releases"
RELEASE_BASE="https://github.com/${REPO_SLUG}/releases/latest/download"
PINNED_PUBKEY="RWQKYnv7bWvDwhNLs7Np+luzdRsl6w7nZMkKErhSgjB5HuUDUHaG3k6m"

APP_NAME="BjwCafeteriaReminder"
MIN_MACOS="14"
MIN_FREE_MB=500

c_red()   { printf "\033[31m%s\033[0m" "$*"; }
c_green() { printf "\033[32m%s\033[0m" "$*"; }
c_yellow(){ printf "\033[33m%s\033[0m" "$*"; }
c_bold()  { printf "\033[1m%s\033[0m" "$*"; }
ok()      { echo "$(c_green "✓") $*"; }
fail()    { echo "$(c_red "✗") $*" >&2; }
warn()    { echo "$(c_yellow "!") $*"; }
die()     { fail "$*"; exit 1; }

# -- Pre-flight ---------------------------------------------------------------
echo
c_bold "BJW Cafeteria Reminder — Bootstrapper Installer"; echo
echo

# macOS version check
MACOS_VER=$(sw_vers -productVersion | cut -d. -f1)
if [ "$MACOS_VER" -lt "$MIN_MACOS" ]; then
    die "macOS $MIN_MACOS+ required (you have $(sw_vers -productVersion))"
fi
ok "macOS $(sw_vers -productVersion)"

# minisign
if ! command -v minisign >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        warn "minisign not found. Installing via Homebrew..."
        brew install minisign
    else
        die "minisign not found and Homebrew not available. Ask IT to install minisign, or: brew install minisign"
    fi
fi
ok "minisign found"

# agency CLI (warn only)
if ! command -v agency >/dev/null 2>&1 && [ ! -x "$HOME/.config/agency/CurrentVersion/agency" ]; then
    warn "agency CLI not found. Skill install will be skipped."
    HAS_AGENCY=0
else
    ok "agency CLI found"
    HAS_AGENCY=1
fi

# claude CLI (warn only)
if ! command -v claude >/dev/null 2>&1; then
    warn "Claude Code CLI not found on PATH."
fi

# Disk space check
FREE_MB=$(df -m /Applications 2>/dev/null | awk 'NR==2{print $4}')
if [ -n "$FREE_MB" ] && [ "$FREE_MB" -lt "$MIN_FREE_MB" ]; then
    die "Need ≥${MIN_FREE_MB}MB free on /Applications volume (have ${FREE_MB}MB)"
fi

# /Applications writable
if [ ! -w /Applications ]; then
    die "/Applications is not writable — contact IT"
fi

# -- Download + verify latest.json -------------------------------------------
TMPDIR_INSTALL=$(mktemp -d /tmp/bjw-install.XXXXXX)
trap 'rm -rf "$TMPDIR_INSTALL"' EXIT

echo
c_bold "Downloading release metadata..."; echo
curl -fSL "$RELEASE_BASE/latest.json" -o "$TMPDIR_INSTALL/latest.json"
curl -fSL "$RELEASE_BASE/latest.json.minisig" -o "$TMPDIR_INSTALL/latest.json.minisig"

# Write pinned pubkey to temp file for minisign -V
PUBKEY_FILE="$TMPDIR_INSTALL/release.pub"
echo "untrusted comment: bjw-cafeteria-reminder release key" > "$PUBKEY_FILE"
echo "$PINNED_PUBKEY" >> "$PUBKEY_FILE"

echo "Verifying signature..."
if ! minisign -V -p "$PUBKEY_FILE" -m "$TMPDIR_INSTALL/latest.json" >/dev/null 2>&1; then
    die "Signature verification FAILED. Aborting."
fi
ok "Signature verified"

# -- Parse latest.json --------------------------------------------------------
VERSION=$(python3 -c "import json; print(json.load(open('$TMPDIR_INSTALL/latest.json'))['version'])")
ZIP_URL=$(python3 -c "import json; print(json.load(open('$TMPDIR_INSTALL/latest.json'))['zipUrl'])")
ZIP_SHA=$(python3 -c "import json; print(json.load(open('$TMPDIR_INSTALL/latest.json'))['zipSha256'])")
echo "Version: $VERSION"

# -- Download + verify zip ----------------------------------------------------
echo
c_bold "Downloading BjwCafeteriaReminder-${VERSION}.zip..."; echo
ZIP_FILE="$TMPDIR_INSTALL/bjw-${VERSION}.zip"
curl -fSL "$ZIP_URL" -o "$ZIP_FILE"

ACTUAL_SHA=$(shasum -a 256 "$ZIP_FILE" | awk '{print $1}')
if [ "$ACTUAL_SHA" != "$ZIP_SHA" ]; then
    die "SHA-256 mismatch! Expected: $ZIP_SHA Got: $ACTUAL_SHA"
fi
ok "SHA-256 verified"

# -- Unzip + verify codesign --------------------------------------------------
UNZIP_DIR="$TMPDIR_INSTALL/unzipped"
unzip -q "$ZIP_FILE" -d "$UNZIP_DIR"

if ! codesign --verify "$UNZIP_DIR/$APP_NAME.app" 2>/dev/null; then
    warn "codesign verification failed on downloaded bundle (ad-hoc signed; expected for dev builds)"
fi

# -- Check appMinVersion from plugin.json if Skill already installed ----------
SKILL_PLUGIN="$HOME/.claude/skills/bjw-weekly-cafeteria/plugin.json"
if [ -f "$SKILL_PLUGIN" ]; then
    APP_MIN=$(python3 -c "import json; d=json.load(open('$SKILL_PLUGIN')); print(d.get('appMinVersion','0.0.0'))" 2>/dev/null || echo "0.0.0")
    if python3 -c "
v1=list(map(int,'$VERSION'.split('.')))
v2=list(map(int,'$APP_MIN'.split('.')))
exit(0 if v1>=v2 else 1)
" 2>/dev/null; then
        :
    else
        die "Installed Skill requires App ≥ $APP_MIN, but this release is $VERSION. Update the App first."
    fi
fi

# -- Install ------------------------------------------------------------------
echo
c_bold "Installing..."; echo

# Quit running app
if pgrep -f "$APP_NAME" >/dev/null 2>&1; then
    warn "Quitting running $APP_NAME..."
    pkill -f "$APP_NAME" || true
    sleep 1
fi

# Handle .previous — delete old one if exists
if [ -d "/Applications/$APP_NAME.app.previous" ]; then
    rm -rf "/Applications/$APP_NAME.app.previous"
fi

# Preserve current as .previous
if [ -d "/Applications/$APP_NAME.app" ]; then
    mv "/Applications/$APP_NAME.app" "/Applications/$APP_NAME.app.previous"
    ok "Current app backed up to .previous"
fi

# Copy new app
cp -R "$UNZIP_DIR/$APP_NAME.app" "/Applications/"
xattr -dr com.apple.quarantine "/Applications/$APP_NAME.app" 2>/dev/null || true
ok "App installed to /Applications/$APP_NAME.app"

# Python helpers
mkdir -p "$HOME/.bjw-cafeteria/bin"
if [ -d "$UNZIP_DIR/python-helpers" ]; then
    cp "$UNZIP_DIR/python-helpers/"* "$HOME/.bjw-cafeteria/bin/"
    chmod +x "$HOME/.bjw-cafeteria/bin/md2json" "$HOME/.bjw-cafeteria/bin/install-schedule"
    ok "Python helpers installed to ~/.bjw-cafeteria/bin/"
fi

# State directory
mkdir -p "$HOME/.bjw-cafeteria/state"
mkdir -p "$HOME/.bjw-cafeteria/logs"

# -- Skill install ------------------------------------------------------------
if [ "$HAS_AGENCY" -eq 1 ]; then
    echo
    c_bold "Installing Skill via Agency Marketplace..."; echo
    if agency plugin install bjw-weekly-cafeteria@playground 2>/dev/null; then
        ok "Skill installed via Marketplace"
    else
        warn "agency plugin install failed. Falling back to local copy."
        mkdir -p "$HOME/.claude/skills/bjw-weekly-cafeteria"
        # The SKILL.md is not in the zip; instruct user
        warn "Run 'agency plugin install bjw-weekly-cafeteria@playground' manually after setup."
    fi
else
    warn "Skipping Skill install (agency CLI not found)."
    warn "Install agency CLI, then run: agency plugin install bjw-weekly-cafeteria@playground"
fi

# -- Launch -------------------------------------------------------------------
echo
open "/Applications/$APP_NAME.app"
sleep 2
ok "App launched. Look for the fork.knife icon in your menu bar."

echo
c_bold "Done! Next steps:"; echo
cat <<EOF
  1. Click the menu-bar icon → "复制拉取命令" → paste in Terminal (first data pull, 2-9 min)
  2. System Settings → Notifications → BJW Cafeteria Reminder → set to "持续"
  3. Click menu-bar icon → 设置… → toggle "登录时自动启动"

  Updates: re-run this installer when a new version is announced.
  Uninstall: see https://github.com/${REPO_SLUG}#uninstall
EOF
