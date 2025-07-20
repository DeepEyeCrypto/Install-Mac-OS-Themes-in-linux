#!/bin/bash

LOGFILE=install-macos-theme.log
set -euo pipefail

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_de() {
    if echo $XDG_CURRENT_DESKTOP | grep -qi "GNOME"; then
        echo "GNOME"
    elif echo $XDG_CURRENT_DESKTOP | grep -qi "MATE"; then
        echo "MATE"
    else
        echo "Unknown"
    fi
}

log "Detecting desktop environment..."
DE=$(detect_de)
if [[ "$DE" == "Unknown" ]]; then
    log "Unsupported desktop: Only GNOME and MATE supported."
    exit 1
else
    log "Detected $DE desktop."
fi

read -p "This will theme your $DE desktop like macOS. Continue? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    log "User aborted."
    exit 1
fi

# Backup DE settings
if [[ "$DE" == "GNOME" ]]; then
    log "Backing up GNOME settings..."
    dconf dump /org/gnome/ > gnome-settings-backup.dconf
elif [[ "$DE" == "MATE" ]]; then
    log "Backing up MATE settings..."
    dconf dump /org/mate/ > mate-settings-backup.dconf
fi

# Dependencies
DEPS=(git curl plank unzip)
if [[ "$DE" == "GNOME" ]]; then
    DEPS+=("gnome-tweaks" "gnome-shell-extensions")
elif [[ "$DE" == "MATE" ]]; then
    DEPS+=("mate-tweak")
fi

for dep in "${DEPS[@]}"; do
    if ! command_exists "$dep"; then
        log "Installing dependency: $dep"
        sudo apt install -y "$dep"
    else
        log "$dep already installed."
    fi
done

for dir in WhiteSur-gtk-theme McMojave-circle capitaine-cursors; do
    [ -d "$dir" ] && rm -rf "$dir"
done

log "Installing WhiteSur GTK theme..."
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
"./WhiteSur-gtk-theme/install.sh" -t all -c light -s 220 -i standard --dest ~/.themes
rm -rf WhiteSur-gtk-theme

log "Installing McMojave Circle icons..."
git clone --depth=1 https://github.com/vinceliuice/McMojave-circle.git
"./McMojave-circle/install.sh" --dest ~/.icons
rm -rf McMojave-circle

log "Installing Capitaine Cursors..."
git clone --depth=1 https://github.com/keeferrourke/capitaine-cursors.git
mkdir -p ~/.icons/Capitaine
cp -r capitaine-cursors/dist/* ~/.icons/Capitaine/
rm -rf capitaine-cursors

# Font
read -p "Install San Francisco font (not open-source)? (y/n): " font_confirm
if [[ "$font_confirm" == "y" ]]; then
    mkdir -p ~/.local/share/fonts/SFPro
    curl -L https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/archive/master.zip -o SFPro.zip
    unzip SFPro.zip -d ~/.local/share/fonts/SFPro/
    mv ~/.local/share/fonts/SFPro/San-Francisco-Pro-Fonts-master/* ~/.local/share/fonts/SFPro/
    rm -rf SFPro.zip ~/.local/share/fonts/SFPro/San-Francisco-Pro-Fonts-master
    fc-cache -fv
    log "San Francisco font installed."
else
    log "Skipping font installation."
fi

log "Setting up Plank (Dock) autostart..."
mkdir -p ~/.config/autostart
cat <<EOT > ~/.config/autostart/plank.desktop
[Desktop Entry]
Name=Plank
Exec=plank
Type=Application
X-GNOME-Autostart-enabled=true
EOT

mkdir -p ~/.config/plank/dock1/launchers
for app in org.gnome.Terminal firefox-esr; do
    [ -f "/usr/share/applications/$app.desktop" ] && cp "/usr/share/applications/$app.desktop" ~/.config/plank/dock1/launchers/
done

# Desktop-specific theme settings
if [[ "$DE" == "GNOME" ]]; then
    log "Applying GNOME theme settings..."
    gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-light"
    gsettings set org.gnome.desktop.interface icon-theme "McMojave-circle"
    gsettings set org.gnome.desktop.interface cursor-theme "Capitaine"
    gsettings set org.gnome.desktop.interface font-name "SF Pro Display 10"
    EXTNAME="user-theme@gnome-shell-extensions.gcampax.github.com"
    if gnome-extensions list | grep -q "$EXTNAME"; then
        log "Enabling User Theme GNOME extension..."
        gnome-extensions enable "$EXTNAME"
    else
        log "User Theme extension not found or not installed. Enable manually if needed."
    fi
elif [[ "$DE" == "MATE" ]]; then
    log "Applying MATE theme settings..."
    gsettings set org.mate.interface gtk-theme "WhiteSur-light"
    gsettings set org.mate.interface icon-theme "McMojave-circle"
    gsettings set org.mate.peripherals-mouse cursor-theme "Capitaine"
    gsettings set org.mate.interface font-name "SF Pro Display 10"
fi

# Wallpaper
WALLPAPER_URL="https://raw.githubusercontent.com/thanhtamkaito/SettingOpenVCS/master/macOS/monterey.jpg"
log "Setting macOS wallpaper..."
mkdir -p ~/Pictures/macOS-wallpaper
curl -L "$WALLPAPER_URL" -o ~/Pictures/macOS-wallpaper/desktop.jpg

if [[ "$DE" == "GNOME" ]]; then
    gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/macOS-wallpaper/desktop.jpg"
elif [[ "$DE" == "MATE" ]]; then
    gsettings set org.mate.background picture-filename "$HOME/Pictures/macOS-wallpaper/desktop.jpg"
fi

log "All done! Logout and log back in to enjoy the macOS look on $DE."
