#!/usr/bin/env sh
set -eu

arch="$(uname -m)"
platform="$(uname -s)"
channel="${VSCODE_BUILD:-stable}"

name="code"
display_name="Visual Studio Code"

local_bin_path="$HOME/.local/bin"
local_application_path="$HOME/.local/share/applications"
app_installation_path="$HOME/.local/vscode-stable"

executable_path="$app_installation_path/bin/code"
desktop_icon_path="$app_installation_path/resources/app/resources/linux/code.png"

download_location=/tmp/vscode
download_file="$download_location/code.tar.gz"

log() {
	local color_reset="\033[0m"
	local color_green="\033[38;2;0;255;0m"    # Bright green
	local color_yellow="\033[38;2;255;255;0m" # Bright yellow
	local color_red="\033[38;2;255;0;0m"      # Bright red
	local color_blue="\033[38;2;0;0;255m"     # Bright blue

	case "$1" in
	success)
		echo "${color_green}[SUCCESS] ===>${color_reset} $2"
		;;
	info)
		echo "${color_blue}[INFO] ===>${color_reset} $2"
		;;
	warning)
		echo "${color_yellow}[WARNING] ===>${color_reset} $2"
		;;
	error)
		echo "${color_red}[ERROR] ===>${color_reset} $2"
		;;
	*)
		echo "$2"
		;;
	esac
}

main() {
	log info "Detected platform: $platform"
	log info "Detected architecture: $arch"

	command -v curl >/dev/null || {
		log error "Curl not found, please install. Exiting..." >&2
		exit 1
	}

	if [ "$platform" != "Linux" ]; then
		log error "This script only supports Linux. Exiting..."
		exit 1
	fi

	case "$arch" in
	x86_64)
		arch="x64"
		;;
	arm64 | aarch64)
		arch="arm64"
		;;
	armv7* | armv6* | arm32)
		arch="armhf"
		;;
	*)
		log error "Unsupported architecture: $arch. This script only supports 64-bit Linux. Exiting..."
		exit 1
		;;
	esac

	do_fetch
	pre_extract
	do_extract
	do_install
	post_install
}

do_fetch() {
	local download_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-$arch"

	mkdir -p "$download_location"

	log info "Downloading Visual Studio Code from $download_url..."

	curl --progress-bar -fLC - "$download_url" -o "$download_file"
}

pre_extract() {
	log info "Setting up installation directories"

	rm -rf "$app_installation_path"

	mkdir -p "$local_bin_path"
	mkdir -p "$local_application_path"
	mkdir -p "$app_installation_path"
}

do_extract() {
	log info "Extracting Visual Studio Code from the .tar.gz file"

	tar -xzf "$download_file" -C "$app_installation_path" --strip-components=1
}

do_install() {
	log info "Linking Visual Studio Code binary to $local_bin_path"

	if [ -f "$executable_path" ]; then
		ln -sf "$executable_path" "$local_bin_path/$name"
	else
		log error "Failed to link Visual Studio Code binary"
		exit 1
	fi

	log info "Creating .desktop file for Visual Studio Code"

	cat <<EOF >"$local_application_path/code.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=$display_name
Icon=$desktop_icon_path
Exec=$executable_path %F
Comment=Code Editing. Redefined.
Categories=Development;IDE;
Terminal=false
StartupNotify=true
EOF

	log info "Creating URL handler .desktop file for vscode:// links"

	cat <<EOF >"$local_application_path/code-url-handler.desktop"
[Desktop Entry]
Name=Visual Studio Code - URL Handler
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=$executable_path --open-url %U
Icon=$desktop_icon_path
Type=Application
NoDisplay=true
StartupNotify=true
Categories=Utility;TextEditor;Development;IDE;
MimeType=x-scheme-handler/vscode;
Keywords=vscode;
EOF

	log info "Registering Visual Studio Code as a URL handler"

	if command -v update-desktop-database >/dev/null 2>&1 && command -v xdg-mime >/dev/null 2>&1; then
		log info "Both update-desktop-database and xdg-mime are available, proceeding with registration"

		update-desktop-database "$local_application_path"
		xdg-mime default code-url-handler.desktop x-scheme-handler/vscode
	else
		log warning "Required tools (update-desktop-database or xdg-mime) not found. Skipping URL handler registration."
	fi
}

post_install() {
	log success "$display_name installation completed."

	if [ "$(which "$name")" = "$local_bin_path/$name" ]; then
		echo "Visual Studio Code has been installed. Run with 'code'."
	else
		echo "To run Visual Studio Code from your terminal, you must add ~/.local/bin to your PATH."
		echo "Run:"
		case "$SHELL" in
		*zsh)
			echo "   echo 'export PATH=\$HOME/.local/bin:\$PATH' >> ~/.zshrc"
			echo "   source ~/.zshrc"
			;;
		*fish)
			echo "   fish_add_path -U $HOME/.local/bin"
			;;
		*)
			echo "   echo 'export PATH=\$HOME/.local/bin:\$PATH' >> ~/.bashrc"
			echo "   source ~/.bashrc"
			;;
		esac
	fi
}

main "$@"
