#!/bin/bash

# Sway Setup Script for Debian Sid
# Author: Assistant
# Description: Complete setup script for Sway window manager with full functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
error "This script should not be run as root for security reasons."
exit 1
fi

# Check if running Debian Sid
check_debian_sid() {
if ! grep -q "sid" /etc/debian_version 2>/dev/null && ! grep -q "unstable" /etc/os-release 2>/dev/null; then
warn "This script is designed for Debian Sid. Continuing anyway..."
read -p "Press Enter to continue or Ctrl+C to abort..."
fi
}

# Update system
update_system() {
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y
}

# Install Sway and essential packages
install_sway_packages() {
log "Installing Sway and essential packages..."

local packages=(
# Core Sway packages
sway swayidle swaylock swaybg

# Display and graphics
wlroots waybar wofi grim slurp wl-clipboard
mako-notifier brightnessctl

# Audio
pipewire pipewire-alsa pipewire-pulse wireplumber
alsa-utils pavucontrol

# File management and utilities
thunar thunar-volman gvfs-backends
network-manager-gnome

# Terminal and applications
foot firefox-esr

# Fonts
fonts-noto fonts-noto-color-emoji fonts-font-awesome

# Additional utilities
playerctl imv mpv
xdg-desktop-portal-wlr
polkit-kde-agent-1
)

sudo apt install -y "${packages[@]}"
}

# Configure keyboard layout
configure_keyboard() {
echo -e "${BLUE}=== Keyboard Configuration ===${NC}"

# Get available layouts
local layouts=$(localectl list-keymaps | head -20)

echo "Available keyboard layouts (showing first 20):"
echo "$layouts"
echo ""
echo "Common layouts: us, uk, de, fr, es, it, dvorak, colemak"

read -p "Enter your keyboard layout (default: us): " kb_layout
kb_layout=${kb_layout:-us}

read -p "Enter keyboard variant (optional, press Enter to skip): " kb_variant

read -p "Do you want to configure Caps Lock behavior? [y/N]: " caps_config

local caps_option=""
if [[ $caps_config =~ ^[Yy]$ ]]; then
echo "Caps Lock options:"
echo "1) Default (Caps Lock)"
echo "2) Ctrl (Caps Lock as Ctrl)"
echo "3) Escape (Caps Lock as Escape)"
echo "4) Disable (Caps Lock disabled)"

read -p "Choose option (1-4): " caps_choice
case $caps_choice in
2) caps_option="caps:ctrl_modifier" ;;
3) caps_option="caps:escape" ;;
4) caps_option="caps:none" ;;
*) caps_option="" ;;
esac
fi

# Store keyboard config
KB_LAYOUT="$kb_layout"
KB_VARIANT="$kb_variant"
KB_OPTIONS="$caps_option"
}

# Create Sway configuration
create_sway_config() {
log "Creating Sway configuration..."

mkdir -p ~/.config/sway

cat > ~/.config/sway/config << EOF
# Sway configuration file
# Read man 5 sway for a complete reference.

### Variables
# Logo key. Use Mod1 for Alt.
set \$mod Mod4

# Home row direction keys, like vim
set \$left h
set \$down j
set \$up k
set \$right l

# Your preferred terminal emulator
set \$term foot

# Your preferred application launcher
set \$menu wofi --show drun

### Output configuration
# Wallpaper (uncomment and modify as needed)
# output * bg ~/Pictures/wallpaper.jpg fill

### Idle configuration
exec swayidle -w \\
timeout 300 'swaylock -f -c 000000' \\
timeout 600 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"' \\
before-sleep 'swaylock -f -c 000000'

### Input configuration
input type:keyboard {
xkb_layout $KB_LAYOUT
EOF

if [[ -n "$KB_VARIANT" ]]; then
echo " xkb_variant $KB_VARIANT" >> ~/.config/sway/config
fi

if [[ -n "$KB_OPTIONS" ]]; then
echo " xkb_options $KB_OPTIONS" >> ~/.config/sway/config
fi

cat >> ~/.config/sway/config << 'EOF'
repeat_delay 300
repeat_rate 50
}

input type:touchpad {
dwt enabled
tap enabled
natural_scroll enabled
middle_emulation enabled
}

### Key bindings
# Start a terminal
bindsym $mod+Return exec $term

# Kill focused window
bindsym $mod+Shift+q kill

# Start your launcher
bindsym $mod+d exec $menu

# Drag floating windows by holding down $mod and left mouse button.
floating_modifier $mod normal

# Reload the configuration file
bindsym $mod+Shift+c reload

# Exit sway (logs you out of your Wayland session)
bindsym $mod+Shift+e exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'

# Moving around:
# Move your focus around
bindsym $mod+$left focus left
bindsym $mod+$down focus down
bindsym $mod+$up focus up
bindsym $mod+$right focus right
# Or use $mod+[up|down|left|right]
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Move the focused window with the same, but add Shift
bindsym $mod+Shift+$left move left
bindsym $mod+Shift+$down move down
bindsym $mod+Shift+$up move up
bindsym $mod+Shift+$right move right
# Ditto, with arrow keys
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Workspaces:
# Switch to workspace
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+6 workspace number 6
bindsym $mod+7 workspace number 7
bindsym $mod+8 workspace number 8
bindsym $mod+9 workspace number 9
bindsym $mod+0 workspace number 10

# Move focused container to workspace
bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5
bindsym $mod+Shift+6 move container to workspace number 6
bindsym $mod+Shift+7 move container to workspace number 7
bindsym $mod+Shift+8 move container to workspace number 8
bindsym $mod+Shift+9 move container to workspace number 9
bindsym $mod+Shift+0 move container to workspace number 10

# Layout stuff:
# You can "split" the current object of your focus with
# $mod+b or $mod+v, for horizontal and vertical splits
# respectively.
bindsym $mod+b splith
bindsym $mod+v splitv

# Switch the current container between different layout styles
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Make the current focus fullscreen
bindsym $mod+f fullscreen

# Toggle the current focus between tiling and floating mode
bindsym $mod+Shift+space floating toggle

# Swap focus between the tiling area and the floating area
bindsym $mod+space focus mode_toggle

# Move focus to the parent container
bindsym $mod+a focus parent

# Scratchpad:
# Move the currently focused window to the scratchpad
bindsym $mod+Shift+minus move scratchpad

# Show the next scratchpad window or hide the focused scratchpad window.
bindsym $mod+minus scratchpad show

# Resizing containers:
mode "resize" {
bindsym $left resize shrink width 10px
bindsym $down resize grow height 10px
bindsym $up resize shrink height 10px
bindsym $right resize grow width 10px

# Ditto, with arrow keys
bindsym Left resize shrink width 10px
bindsym Down resize grow height 10px
bindsym Up resize shrink height 10px
bindsym Right resize grow width 10px

# Return to default mode
bindsym Return mode "default"
bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# Media keys
bindsym XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindsym XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous

# Brightness keys
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym XF86MonBrightnessUp exec brightnessctl set 5%+

# Screenshots
bindsym Print exec grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png
bindsym $mod+Print exec grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

# File manager
bindsym $mod+Shift+f exec thunar

# Lock screen
bindsym $mod+Shift+l exec swaylock -f -c 000000

# Status Bar:
bar {
position top
status_command while date +'%Y-%m-%d %I:%M:%S %p'; do sleep 1; done

colors {
statusline #ffffff
background #323232
inactive_workspace #32323200 #32323200 #5c5c5c
}
}

# Autostart applications
exec --no-startup-id /usr/lib/polkit-kde/polkit-kde-authentication-agent-1
exec --no-startup-id mako
exec --no-startup-id nm-applet --indicator

include /etc/sway/config.d/*
EOF

log "Sway configuration created successfully!"
}

# Create Waybar configuration
create_waybar_config() {
log "Creating Waybar configuration..."

mkdir -p ~/.config/waybar

cat > ~/.config/waybar/config << 'EOF'
{
"layer": "top",
"position": "top",
"height": 30,
"spacing": 4,

"modules-left": ["sway/workspaces", "sway/mode"],
"modules-center": ["clock"],
"modules-right": ["pulseaudio", "network", "battery", "tray"],

"sway/workspaces": {
"disable-scroll": true,
"all-outputs": true,
"format": "{icon}",
"format-icons": {
"1": "1",
"2": "2",
"3": "3",
"4": "4",
"5": "5",
"6": "6",
"7": "7",
"8": "8",
"9": "9",
"10": "10"
}
},

"clock": {
"tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
"format": "{:%Y-%m-%d %H:%M}"
},

"battery": {
"states": {
"warning": 30,
"critical": 15
},
"format": "{capacity}% {icon}",
"format-charging": "{capacity}% ",
"format-plugged": "{capacity}% ",
"format-alt": "{time} {icon}",
"format-icons": ["", "", "", "", ""]
},

"network": {
"format-wifi": "{essid} ({signalStrength}%) ",
"format-ethernet": "{ipaddr}/{cidr} ",
"tooltip-format": "{ifname} via {gwaddr} ",
"format-linked": "{ifname} (No IP) ",
"format-disconnected": "Disconnected ⚠",
"format-alt": "{ifname}: {ipaddr}/{cidr}"
},

"pulseaudio": {
"format": "{volume}% {icon} {format_source}",
"format-bluetooth": "{volume}% {icon} {format_source}",
"format-bluetooth-muted": " {icon} {format_source}",
"format-muted": " {format_source}",
"format-source": "{volume}% ",
"format-source-muted": "",
"format-icons": {
"headphone": "",
"hands-free": "",
"headset": "",
"phone": "",
"portable": "",
"car": "",
"default": ["", "", ""]
},
"on-click": "pavucontrol"
}
}
EOF

cat > ~/.config/waybar/style.css << 'EOF'
* {
border: none;
border-radius: 0;
font-family: "Font Awesome 5 Free", "Noto Sans";
font-size: 13px;
min-height: 0;
}

window#waybar {
background-color: rgba(43, 48, 59, 0.8);
border-bottom: 3px solid rgba(100, 114, 125, 0.5);
color: #ffffff;
transition-property: background-color;

}

#pulseaudio {
background-color: #cba6f7;
color: #1e1e2e;
}

#pulseaudio.muted {
background-color: #6c7086;
color: #bac2de;
}

#idle_inhibitor {
background-color: #eba0ac;
color: #1e1e2e;
}

#idle_inhibitor.activated {
background-color: #f9e2af;
color: #1e1e2e;
}

#tray {
background-color: rgba(49, 50, 68, 0.8);
}

#tray > .passive {
-gtk-icon-effect: dim;
}

#tray > .needs-attention {
-gtk-icon-effect: highlight;
background-color: #f38ba8;
}

/* Tooltip styling */
tooltip {
background: rgba(30, 30, 46, 0.95);
border: 1px solid #45475a;
border-radius: 6px;
color: #cdd6f4;
}

tooltip label {
color: #cdd6f4;
}
EOF

success "Waybar configuration completed"
}

# Create helper scripts
create_helper_scripts() {
section "Creating Helper Scripts"

mkdir -p ~/.config/sway/scripts

# Power menu script
cat > ~/.config/sway/scripts/power-menu.sh << 'EOF'
#!/bin/bash

# Power menu for Sway
}

button {
box-shadow: inset 0 -3px transparent;
border: none;
border-radius: 0;
}

#workspaces button {
padding: 0 5px;
background-color: transparent;
color: #ffffff;
}

#workspaces button:hover {
background: rgba(0, 0, 0, 0.2);
}

#workspaces button.focused {
background-color: #64727D;
box-shadow: inset 0 -3px #ffffff;
}

#workspaces button.urgent {
background-color: #eb4d4b;
}

#clock,
#battery,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#pulseaudio,
#tray,
#mode,
#idle_inhibitor,
#scratchpad,
#mpd {
padding: 0 10px;
color: #ffffff;
}

#window,
#workspaces {
margin: 0 4px;
}

.modules-left > widget:first-child > #workspaces {
margin-left: 0;
}

.modules-right > widget:last-child > #workspaces {
margin-right: 0;
}

#clock {
background-color: #64727D;
}

#battery {
background-color: #ffffff;
color: #000000;
}

#battery.charging, #battery.plugged {
color: #ffffff;
background-color: #26A65B;
}

@keyframes blink {
to {
background-color: #ffffff;
color: #000000;
}
}

#battery.critical:not(.charging) {
background-color: #f53c3c;
color: #ffffff;
animation-name: blink;
animation-duration: 0.5s;
animation-timing-function: linear;
animation-iteration-count: infinite;
animation-direction: alternate;
}

label:focus {
background-color: #000000;
}

#network {
background-color: #2980b9;
}

#network.disconnected {
background-color: #f53c3c;
}

#pulseaudio {
background-color: #f1c40f;
color: #000000;
}

#pulseaudio.muted {
background-color: #90b1b1;
color: #2a5c45;
}

#tray {
background-color: #2980b9;
}

#tray > .passive {
-gtk-icon-effect: dim;
}

#tray > .needs-attention {
-gtk-icon-effect: highlight;
background-color: #eb4d4b;
}
EOF

log "Waybar configuration created successfully!"
}

# Configure environment variables
setup_environment() {
log "Setting up environment variables..."

cat > ~/.config/environment.d/sway.conf << 'EOF'
# Wayland environment variables
WAYLAND_DISPLAY=wayland-1
QT_QPA_PLATFORM=wayland
GDK_BACKEND=wayland
XDG_CURRENT_DESKTOP=sway
XDG_SESSION_DESKTOP=sway
XDG_SESSION_TYPE=wayland
MOZ_ENABLE_WAYLAND=1
EOF
}

# Create desktop entry for display manager
create_desktop_entry() {
log "Creating desktop entry for display manager..."

sudo tee /usr/share/wayland-sessions/sway.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Sway
Comment=An i3-compatible Wayland compositor
Exec=sway
Type=Application
EOF
}

# Setup audio
setup_audio() {
log "Setting up audio with PipeWire..."

# Enable PipeWire services for user
systemctl --user daemon-reload
systemctl --user enable pipewire pipewire-pulse wireplumber

# Start PipeWire services
systemctl --user start pipewire pipewire-pulse wireplumber
}

# Final setup and instructions
final_setup() {
log "Performing final setup..."

# Create Pictures directory for screenshots
mkdir -p ~/Pictures

# Set up user groups
sudo usermod -a -G video,audio,input "$USER"

echo -e "\n${GREEN}=== Sway Setup Complete! ===${NC}"
echo -e "\n${BLUE}Keyboard Configuration:${NC}"
echo "Layout: $KB_LAYOUT"
[[ -n "$KB_VARIANT" ]] && echo "Variant: $KB_VARIANT"
[[ -n "$KB_OPTIONS" ]] && echo "Options: $KB_OPTIONS"

echo -e "\n${BLUE}Important Notes:${NC}"
echo "• Log out and select 'Sway' from your display manager"
echo "• Or run 'sway' from a TTY (Ctrl+Alt+F1-F6)"
echo "• Configuration files are in ~/.config/sway/"
echo "• Press Super+Return to open terminal"
echo "• Press Super+d to open application launcher"
echo "• Press Super+Shift+e to exit Sway"

echo -e "\n${BLUE}Key Bindings Summary:${NC}"
echo "Super+Return - Terminal"
echo "Super+d - App launcher"
echo "Super+Shift+q - Kill window"
echo "Super+f - Fullscreen"
echo "Super+Shift+Space - Toggle floating"
echo "Super+1-0 - Switch workspace"
echo "Super+Shift+1-0 - Move to workspace"
echo "Super+Print - Screenshot area"
echo "Print - Screenshot full"
echo "Super+Shift+l - Lock screen"
echo "Super+Shift+f - File manager"

echo -e "\n${YELLOW}Reboot recommended to ensure all services start properly.${NC}"

read -p "Would you like to reboot now? [y/N]: " reboot_choice
if [[ $reboot_choice =~ ^[Yy]$ ]]; then
sudo reboot
fi
}

# Main execution
main() {
echo -e "${BLUE}=== Sway Setup Script for Debian Sid ===${NC}"
echo "This script will install and configure Sway with full functionality."
echo ""

read -p "Continue with installation? [Y/n]: " continue_choice
if [[ $continue_choice =~ ^[Nn]$ ]]; then
echo "Installation cancelled."
exit 0
fi

check_debian_sid
configure_keyboard
update_system
install_sway_packages
create_sway_config
create_waybar_config
setup_environment
create_desktop_entry
setup_audio
final_setup
}

# Run main function
main "$@
