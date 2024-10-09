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

executable_path="$app_installation_path/code/bin/code"
desktop_icon_path="$app_installation_path/pixmaps/vscode.png"

download_location=/tmp/vscode
download_file="$download_location/code.deb"

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

	command -v zstd >/dev/null || {
		log error "Zstandard (zstd) not found, please install. Exiting..." >&2
		exit 1
	}

	if [ "$platform" = "Darwin" ]; then
		platform="macos"
	elif [ "$platform" = "Linux" ]; then
		platform="linux"
	else
		log error "Unsupported platform $platform Exiting..."

		exit 1
	fi

	case "$arch" in
	x86_64)
		arch="x64"
		;;
	i[3-6]86)
		arch="x86"
		;;
	arm64 | aarch64)
		arch="arm64"
		;;
	armv7* | armv6* | arm32)
		arch="armhf"
		;;
	*)
		log error "Unsupported architecture: $arch Exiting..."
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
	local download_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-$arch"

	mkdir -p "$download_location"

	log info "Downloading Visual Studio Code..."

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
	log info "Extracting Vscode from the package"

	cd "$download_location"

	ar x "$download_file"

	if [ -f "$download_location/data.tar.xz" ]; then
		log info "Extracting data.tar.xz..."

		tar xf "$download_location/data.tar.xz" -C "$download_location"
	elif [ -f "$download_location/data.tar.zst" ]; then
		log info "Extracting data.tar.zst..."

		tar xf "$download_location/data.tar.zst" -C "$download_location"
	else
		log error "Neither data.tar.xz nor data.tar.zst found in $download_location."
	fi
}

do_install() {
	log info "Installing Vscode to $app_installation_path"

	mv "$download_location/usr/share/"* "$app_installation_path"

	log info "Linking vscode binary to $local_bin_path"

	if [ -f "$executable_path" ]; then
		ln -sf "$executable_path" "$local_bin_path"
	else
		log error "Failed to link vscode binary"

		exit 1
	fi

	log info "Updating .desktop file with executable and icon paths"

	for file in "$app_installation_path/applications/"*.desktop; do
		sed -i "s|/usr/share/code/code|$executable_path|g" "$file"
		sed -i "s|Icon=vscode|Icon=$desktop_icon_path|g" "$file"
	done

	cp "$app_installation_path/applications/"*.desktop "$local_application_path"
}

post_install() {
	log success "$display_name installation completed."

	if [ "$(which "code")" = "$local_bin_path/code" ]; then
		echo "Vscode has been installed. Run with 'code'"
	else
		echo "To run Vscode from your terminal, you must add ~/.local/bin to your PATH"
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

		echo "To run Vscode now, '~/.local/bin/code'"
	fi
}

main "$@"
