# Android-AVD-for-MacOS

# install-avd-macos

Set up an Android Virtual Device (AVD) on macOS without installing Android Studio.

This script automates the full setup process using only the Android Command Line Tools
via Homebrew — including SDK installation, license acceptance, and AVD creation.

## Features
- 🍎 Auto-detects Apple Silicon (arm64) and Intel (x86_64) Macs
- 🍺 Installs dependencies via Homebrew (Java + Android CLI Tools)
- ⚙️  Configures ANDROID_HOME and PATH in ~/.zshrc automatically
- 📦 Downloads SDK platform-tools, emulator, and system images
- 📱 Creates a Pixel 8 AVD ready to launch

## Usage
chmod +x install-avd-macos.sh
./install-avd-macos.sh

## Launch Emulator
source ~/.zshrc

emulator -avd Emulator -gpu host

## Requirements
- macOS (Apple Silicon or Intel)
- Internet connection
- ~3–5 GB free disk space
