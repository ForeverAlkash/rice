#!/usr/bin/env bash
# rice installer: bare Arch -> Hyprland + Prism (quickshell) + all configs from this repo.
#
#   git clone https://github.com/<you>/<rice>.git rice && cd rice && ./install.sh
#
# What it does:
#   1. checks: Arch, not root
#   2. one pacman transaction: Hyprland, Quickshell, matugen, PipeWire, NetworkManager,
#      kitty, thunar, fonts, icons, easyeffects, cava, btop, fastfetch, mpv, gestures
#   3. copies the configs from this repo into ~/.config (existing files backed up)
#   4. wallpapers (~/.config/quickshell/wallpapers) from upstream prism-shell if missing
#   5. ydotool daemon + input group for touchpad swipe gestures
#
# run without sudo; it asks for the password itself.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"

C_G='\033[32m' C_Y='\033[33m' C_R='\033[31m' C_D='\033[90m' C_0='\033[0m'
ok()   { printf "${C_G} ✔${C_0} %s\n" "$*"; }
warn() { printf "${C_Y} !${C_0} %s\n" "$*"; }
die()  { printf "${C_R} ✘${C_0} %s\n" "$*"; exit 1; }

(( EUID )) || die "не запускай от root"
grep -qi '^ID=arch' /etc/os-release || die "это не Arch"

# ---------------------------------------------------------------- packages --
PKGS=(
    # desktop
    hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpolkitagent polkit
    qt5-wayland qt6-wayland xdg-user-dirs xdg-utils
    pipewire wireplumber pipewire-alsa pipewire-pulse
    networkmanager bluez bluez-utils upower
    kitty thunar gvfs tumbler pavucontrol unzip
    # shell (Prism)
    quickshell qt6-svg qt6-imageformats
    matugen awww cava
    wl-clipboard cliphist grim slurp wf-recorder hyprpicker
    brightnessctl playerctl imagemagick ffmpeg ffmpegthumbnailer
    hyprlock libnotify curl git python
    # looks
    ttf-nerd-fonts-symbols ttf-jetbrains-mono-nerd ttf-roboto adwaita-fonts
    noto-fonts noto-fonts-emoji noto-fonts-cjk
    breeze-icons papirus-icon-theme adw-gtk-theme
    # mine
    qt6ct easyeffects btop fastfetch mpv
    libinput-gestures ydotool
)
missing=()
for p in "${PKGS[@]}"; do pacman -Q "$p" &>/dev/null || missing+=("$p"); done
if ((${#missing[@]})); then
    echo "ставлю: ${missing[*]}"
    sudo pacman -S --needed --noconfirm "${missing[@]}"
else
    ok "все пакеты уже стоят"
fi

# ---------------------------------------------------------------- configs ---
# copy each tracked dir/file into ~/.config, backing up what's already there
copy() { # $1 = relative path in repo
    local src="$HERE/$1" dst="$CFG/$1"
    [[ -e $src ]] || { warn "нет $1 в репо, пропускаю"; return; }
    if [[ -e $dst && ! -L $dst ]]; then
        mv "$dst" "$dst.bak-$STAMP"
        warn "бэкап: $1 -> $1.bak-$STAMP"
    fi
    mkdir -p "$(dirname "$dst")"
    cp -r "$src" "$dst"
    ok "$1"
}
for d in hypr quickshell matugen kitty gtk-3.0 gtk-4.0 qt6ct cava btop fastfetch easyeffects; do copy "$d"; done
for f in libinput-gestures.conf kdeglobals dolphinrc mimeapps.list user-dirs.dirs QtProject.conf; do copy "$f"; done

# ---------------------------------------------------------------- wallpaper --
if [[ ! -d $CFG/quickshell/wallpapers || -z $(ls -A "$CFG/quickshell/wallpapers" 2>/dev/null) ]]; then
    echo "тяну обои из prism-shell…"
    tmp="$(mktemp -d)"
    git clone --depth 1 https://github.com/Jack02134x/prism-shell.git "$tmp/prism"
    mkdir -p "$CFG/quickshell/wallpapers"
    cp -r "$tmp/prism/wallpapers/." "$CFG/quickshell/wallpapers/" 2>/dev/null || true
    rm -rf "$tmp"
    ok "wallpapers"
fi

# ---------------------------------------------------------------- gestures --
# touchpad swipe -> mouse4/5 (back/forward) через libinput-gestures + ydotool
getent group input >/dev/null || sudo groupadd input
sudo gpasswd -a "$USER" input 2>/dev/null || true
sudo systemctl enable --now ydotool 2>/dev/null || true
ok "gestures: юзер в input, ydotool запущен (перезайди для применения группы)"

xdg-user-dirs-update >/dev/null 2>&1 || true

echo
ok "готово. логинься — Hyprland стартует с tty1:"
echo   "    exec Hyprland   # в ~/.zprofile, если ещё нет"
