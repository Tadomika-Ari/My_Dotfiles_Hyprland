#!/bin/bash
#### Advanced Hyprland Installation Script ####

# Color definitions
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\e[1;38;5;214m"
end="\e[1;0m"
dir="$(dirname "$(realpath "$0")")"

# Install counters
installed=()
skipped=()
failed=()

clear && sleep 1

# Check if running on Arch Linux
if ! command -v pacman &> /dev/null; then
    printf "${red}[ Error ]${end} This script requires pacman (Arch Linux). Exiting.\n"
    exit 1
fi

# Check if Hyprland is installed
if ! command -v hyprland &> /dev/null && ! pacman -Q hyprland &> /dev/null 2>&1; then
    printf "${yellow}[ Warn ]${end} Hyprland doesn't seem to be installed. It's recommended to install it first.\n"
    read -rp "Continue anyway? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
fi

# Detect AUR helper
AUR_HELPER=""
if command -v yay &> /dev/null; then
    AUR_HELPER="yay"
elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
else
    printf "${yellow}[ Warn ]${end} No AUR helper found (yay/paru). AUR packages won't be installed.\n"
fi

printf "${cyan}**${end} Pre install script...\n   Need to install some packages first, installing those...\n\n" && sleep 1

# Install function with pacman -> AUR fallback
install_pkg() {
    local pkg=$1

    if pacman -Q "$pkg" &> /dev/null; then
        printf "${magenta}[ Skip ]${end} $pkg is already installed\n"
        skipped+=("$pkg")
        return 0
    fi

    printf "${green}=>${end} Installing $pkg...\n"

    # Try pacman first
    if sudo pacman -S --noconfirm "$pkg" &> /dev/null; then
        printf "${cyan}::${end} Successfully installed ${cyan}$pkg${end}\n"
        installed+=("$pkg")
        return 0
    fi

    # Fallback to AUR helper
    if [ -n "$AUR_HELPER" ]; then
        printf "${yellow}  -> Not in official repos, trying AUR ($AUR_HELPER)...\n${end}"
        if $AUR_HELPER -S --noconfirm "$pkg" &> /dev/null; then
            printf "${cyan}::${end} Successfully installed ${cyan}$pkg${end} (AUR)\n"
            installed+=("$pkg")
            return 0
        fi
    fi

    printf "${red}[ Error ]${end} Failed to install $pkg\n"
    failed+=("$pkg")
    return 1
}

# Package list
declare -A packages=(
    [git]="VCS"
    [kitty]="Terminal"
    [hyprmoncfg]="Monitor manager"
    [fastfetch]="System info"
    [rofi]="App launcher"
    [waybar]="Status bar"
    [waypaper]="Wallpaper manager"
    [awwww]="Smooth wallpaper transitions"
    [code]="VS Code"
    [cava]="Music visualizer"
    [hyprshot]="Screenshot tool"
    [hyprlock]="Lock screen"
    [mpd]="Music daemon"
    [rmpc]="Music player manager"
    [spotify]="Online music"
    [mako]="Notifications"
)

for pkg in "${!packages[@]}"; do
    install_pkg "$pkg"
done

# Install base-devel
printf "\n${green}=>${end} Checking base-devel...\n"
install_pkg "base-devel"

sleep 1

# Paths
dotfiles_dir="$dir/Dotfiles"
config_dir="$HOME/.config"
wallpaper_src="$dir/Wallpaper"
wallpaper_target="$config_dir/wallpaper"

mkdir -p "$wallpaper_target"

# Copy wallpapers
printf "\n${cyan}**${end} Syncing wallpapers...\n"
if [ -d "$wallpaper_src" ]; then
    cp -r "$wallpaper_src"/. "$wallpaper_target"/
    printf "${cyan}::${end} Synced ${cyan}Wallpaper${end} to ${cyan}$wallpaper_target${end}\n"
else
    printf "${yellow}[ Warn ]${end} Wallpaper directory not found: $wallpaper_src\n"
fi

# Copy dotfiles
printf "\n${cyan}**${end} Syncing dotfiles...\n"
if [ -d "$dotfiles_dir" ]; then
    mkdir -p "$config_dir"
    for src in "$dotfiles_dir"/*; do
        [ -d "$src" ] || continue
        name="$(basename "$src")"
        target_name="$(echo "$name" | tr '[:upper:]' '[:lower:]')"
        target="$config_dir/$target_name"

        # Backup existing config
        if [ -d "$target" ]; then
            backup="${target}.bak.$(date +%s)"
            cp -r "$target" "$backup"
            printf "${yellow}[ Backup ]${end} $target -> $backup\n"
        else
            printf "${green}=>${end} Creating $target...\n"
            mkdir -p "$target"
        fi

        cp -r "$src"/. "$target"/
        printf "${cyan}::${end} Synced ${cyan}$name${end} to ${cyan}$target${end}\n"
    done
else
    printf "${red}[ Error ]${end} Dotfiles directory not found: $dotfiles_dir\n"
fi

# Summary
printf "\n${cyan}========================================${end}\n"
printf "${cyan}           Installation Summary          ${end}\n"
printf "${cyan}========================================${end}\n"

if [ ${#installed[@]} -gt 0 ]; then
    printf "${green}[ Installed ]${end} (${#installed[@]}) : ${installed[*]}\n"
fi
if [ ${#skipped[@]} -gt 0 ]; then
    printf "${magenta}[ Skipped   ]${end} (${#skipped[@]}) : ${skipped[*]}\n"
fi
if [ ${#failed[@]} -gt 0 ]; then
    printf "${red}[ Failed    ]${end} (${#failed[@]}) : ${failed[*]}\n"
fi

printf "${cyan}========================================${end}\n"
printf "${green}Done!${end} Restart Hyprland to apply changes.\n"