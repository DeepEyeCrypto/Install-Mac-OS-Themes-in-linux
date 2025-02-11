#!/bin/bash

# macOS Theme Install Script for Kali Linux
# Requires GNOME Desktop Environment

# Exit on error and print commands
set -e

# Install necessary dependencies
sudo apt update
sudo apt install -y git curl gnome-tweaks gnome-shell-extensions plank

# Download and install WhiteSur GTK theme
echo "Installing WhiteSur GTK theme..."
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
WhiteSur-gtk-theme/install.sh -t all -c light -s 220 -i standard --dest ~/.themes
rm -rf WhiteSur-gtk-theme

# Install McMojave Circle icons
echo "Installing McMojave icons..."
git clone https://github.com/vinceliuice/McMojave-circle.git
McMojave-circle/install.sh --dest ~/.icons
rm -rf McMojave-circle

# Install Capitaine Cursors
echo "Installing Capitaine Cursors..."
git clone https://github.com/keeferrourke/capitaine-cursors.git
mkdir -p ~/.icons/Capitaine
cp -r capitaine-cursors/dist/* ~/.icons/Capitaine/
rm -rf capitaine-cursors

# Install San Francisco Font
echo "Installing San Francisco Font..."
mkdir -p ~/.local/share/fonts/SFPro
curl -L https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/archive/master.zip -o SFPro.zip
unzip SFPro.zip -d ~/.local/share/fonts/SFPro/
mv ~/.local/share/fonts/SFPro/San-Francisco-Pro-Fonts-master/* ~/.local/share/fonts/SFPro/
rm -rf SFPro.zip ~/.local/share/fonts/SFPro/San-Francisco-Pro-Fonts-master
fc-cache -fv

# Set theme settings
echo "Configuring theme settings..."
gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-light"
gsettings set org.gnome.desktop.interface icon-theme 'McMojave-circle'
gsettings set org.gnome.desktop.interface cursor-theme 'Capitaine'
gsettings set org.gnome.desktop.interface font-name 'SF Pro Display 10'

# Set macOS wallpaper (replace URL with actual macOS wallpaper)
echo "Setting up wallpaper..."
WALLPAPER_URL="https://raw.githubusercontent.com/thanhtamkaito/SettingOpenVCS/master/macOS/monterey.jpg"
mkdir -p ~/Pictures/macOS-wallpaper
curl -L "$WALLPAPER_URL" -o ~/Pictures/macOS-wallpaper/desktop.jpg
gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/macOS-wallpaper/desktop.jpg"

# Configure Plank dock
echo "Setting up Plank dock..."
mkdir -p ~/.config/plank/dock1/launchers
cp /usr/share/applications/org.gnome.Terminal.desktop ~/.config/plank/dock1/launchers/
cp /usr/share/applications/firefox-esr.desktop ~/.config/plank/dock1/launchers/

# Add Plank to autostart
mkdir -p ~/.config/autostart
echo "[Desktop Entry]
Name=Plank
Exec=plank
Type=Application
" > ~/.config/autostart/plank.desktop

# Enable GNOME extensions
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com

echo "Installation complete! Log out and log back in to apply all changes."
