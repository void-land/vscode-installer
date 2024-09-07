<p align="center">
  <a href="https://github.com/YourRepo/VSCode-Linux-Installer"><img width="140" src="./assets/vscode.png" /></a>
</p>

<p align="center">
    <h4 align="center">Automated shell script for installing Visual Studio Code on Linux.</h4>
    <p align="center">
        <strong>Supports:</strong> x64, arm64, and x86 architectures
    </p> 
</p>

## Features

- Automatically detects Linux distribution and architecture.
- Downloads the latest stable release of Visual Studio Code.
- Extracts and installs to `~/.local/vscode-stable` for user-only access.
- Automatically adds the binary to `~/.local/bin` for easy terminal access.
- Creates a `.desktop` file for easy launching from the applications menu.
- Optional flags for clearing cache and forced reinstallation.

## Installation

1. Close any running instances of Visual Studio Code.
2. Run the following command in your terminal:

```
curl -f https://raw.githubusercontent.com/void-land/vscode-installer/main/install.sh | sh
```

## Uninstallation

To uninstall Visual Studio Code, run the following command:

```
curl -f https://raw.githubusercontent.com/void-land/vscode-installer/main/uninstall.sh | sh
```

Alternatively, you can manually delete the installation directory:

```
rm -rf ~/.local/vscode-stable ~/.local/bin/code
rm -rf ~/.local/share/applications/code.desktop
rm -rf ~/.local/share/applications/code-url-handler.desktop
```

## Notes

- For Flatpak users, please refer to the specific instructions for Flatpak version management.

## Disclaimer

This script is provided as-is, and the repository owners are not responsible for any issues caused by the use of this installer.