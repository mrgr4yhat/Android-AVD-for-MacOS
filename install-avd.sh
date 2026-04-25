#!/bin/bash

# ============================================================
#  AVD Installer for macOS (No Android Studio Required)
#  Supports Apple Silicon (M1/M2/M3/M4) and Intel Macs
# ============================================================

set -e

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ──────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${RESET}  $1"; }
success() { echo -e "${GREEN}[OK]${RESET}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}▶ $1${RESET}"; }
divider() { echo -e "${CYAN}────────────────────────────────────────────────${RESET}"; }

# ── Config (edit these if needed) ────────────────────────────
ANDROID_API_LEVEL="35"
AVD_NAME="MyAndroidEmulator"
DEVICE_PROFILE="pixel_8"
SHELL_RC="$HOME/.zshrc"

# ── Banner ────────────────────────────────────────────────────
clear
divider
echo -e "${BOLD}  🤖  Android AVD Installer for macOS${RESET}"
echo -e "      No Android Studio required"
divider
echo ""

# ── Step 0: Detect Architecture ───────────────────────────────
step "Detecting Mac architecture"
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
  ABI="arm64-v8a"
  success "Apple Silicon (M-series) detected → using arm64-v8a system image"
else
  ABI="x86_64"
  success "Intel Mac detected → using x86_64 system image"
fi

SYSTEM_IMAGE="system-images;android-${ANDROID_API_LEVEL};google_apis_playstore;${ABI}"

# ── Step 1: Check macOS & Xcode CLI Tools ─────────────────────
step "Checking prerequisites"
if ! xcode-select -p &>/dev/null; then
  warn "Xcode Command Line Tools not found. Installing..."
  xcode-select --install
  echo "After installation completes, re-run this script."
  exit 0
else
  success "Xcode Command Line Tools found"
fi

# ── Step 2: Install Homebrew ──────────────────────────────────
step "Checking Homebrew"
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add Homebrew to PATH for Apple Silicon
  if [[ "$ARCH" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  success "Homebrew installed"
else
  success "Homebrew already installed ($(brew --version | head -1))"
fi

# ── Step 3: Install Java (Temurin) ────────────────────────────
step "Checking Java"
if ! java -version &>/dev/null 2>&1; then
  info "Installing Eclipse Temurin (Java 17)..."
  brew install --cask temurin
  success "Java installed"
else
  JAVA_VER=$(java -version 2>&1 | head -1)
  success "Java already installed: $JAVA_VER"
fi

# ── Step 4: Install Android Command Line Tools ────────────────
step "Installing Android Command Line Tools"
if brew list --cask android-commandlinetools &>/dev/null 2>&1; then
  success "android-commandlinetools already installed"
else
  info "Installing via Homebrew (this may take a few minutes)..."
  brew install --cask android-commandlinetools
  success "Android Command Line Tools installed"
fi

# Detect Homebrew prefix
BREW_PREFIX=$(brew --prefix)
CMDLINE_TOOLS_PATH="$BREW_PREFIX/share/android-commandlinetools"

# ── Step 5: Set Environment Variables ────────────────────────
step "Configuring environment variables"

EXPORT_BLOCK="
# ── Android SDK (added by install-avd-macos.sh) ──
export ANDROID_HOME=\"$CMDLINE_TOOLS_PATH\"
export PATH=\"\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin\"
export PATH=\"\$PATH:\$ANDROID_HOME/platform-tools\"
export PATH=\"\$PATH:\$ANDROID_HOME/emulator\"
# ─────────────────────────────────────────────────"

if grep -q "ANDROID_HOME" "$SHELL_RC" 2>/dev/null; then
  warn "ANDROID_HOME already set in $SHELL_RC — skipping"
else
  echo "$EXPORT_BLOCK" >> "$SHELL_RC"
  success "Environment variables added to $SHELL_RC"
fi

# Source for current session
export ANDROID_HOME="$CMDLINE_TOOLS_PATH"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/emulator"

# ── Step 6: Verify sdkmanager ─────────────────────────────────
step "Verifying sdkmanager"
if ! command -v sdkmanager &>/dev/null; then
  error "sdkmanager not found. Please check ANDROID_HOME path: $ANDROID_HOME"
fi
success "sdkmanager found at $(which sdkmanager)"

# Create required config file
mkdir -p "$HOME/.android"
touch "$HOME/.android/repositories.cfg"
success "Android config directory ready"

# ── Step 7: Accept SDK Licenses ───────────────────────────────
step "Accepting SDK licenses"
yes | sdkmanager --licenses > /dev/null 2>&1 && success "All SDK licenses accepted" || warn "Some licenses may need manual acceptance"

# ── Step 8: Install SDK Components ────────────────────────────
step "Installing SDK components (platform-tools, emulator, system image)"
info "API Level  : Android $ANDROID_API_LEVEL"
info "System Image: $SYSTEM_IMAGE"
info "This may take several minutes depending on your connection..."

sdkmanager \
  "platform-tools" \
  "emulator" \
  "platforms;android-${ANDROID_API_LEVEL}" \
  "$SYSTEM_IMAGE"

success "SDK components installed"

# ── Step 9: Create AVD ────────────────────────────────────────
step "Creating Android Virtual Device"

# Check if AVD already exists
if avdmanager list avd 2>/dev/null | grep -q "Name: $AVD_NAME"; then
  warn "AVD '$AVD_NAME' already exists — skipping creation"
else
  echo "no" | avdmanager create avd \
    -n "$AVD_NAME" \
    -k "$SYSTEM_IMAGE" \
    --device "$DEVICE_PROFILE" \
    --force

  success "AVD '$AVD_NAME' created (Device: $DEVICE_PROFILE, API: $ANDROID_API_LEVEL)"
fi

# ── Done ──────────────────────────────────────────────────────
echo ""
divider
echo -e "${BOLD}${GREEN}  ✅  Installation Complete!${RESET}"
divider
echo ""
echo -e "${BOLD}Available AVDs:${RESET}"
avdmanager list avd 2>/dev/null | grep "Name:" | sed 's/^/  /'
echo ""
echo -e "${BOLD}To launch your emulator:${RESET}"
echo -e "  ${CYAN}source $SHELL_RC${RESET}         # reload shell (first time only)"
echo -e "  ${CYAN}emulator -avd $AVD_NAME -gpu host${RESET}"
echo ""
echo -e "${BOLD}Other useful commands:${RESET}"
echo -e "  ${CYAN}avdmanager list avd${RESET}         # list all AVDs"
echo -e "  ${CYAN}avdmanager list devices${RESET}     # list device profiles"
echo -e "  ${CYAN}adb devices${RESET}                 # check connected devices"
echo -e "  ${CYAN}adb install app.apk${RESET}         # install an APK"
echo ""
divider
