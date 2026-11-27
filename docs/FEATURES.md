**English** · [Español](es/FEATURES.md) · [Português](pt/FEATURES.md) · [← Docs Home](README.md)

# Features

Everything in **DarkShadow's Shell** is controlled through the Material 3 **Settings** app (`SUPER + U`) with a navigation rail, instant search ("Search anything!"), and live previews.

---

## Bar & Dynamic Island

| Feature | Details |
| --- | --- |
| **DarkShadow Bar** | Quickshell bar with top/bottom/left/right placement, autohide, soft shadow, transparency, seconds clock, and Waybar fallback |
| **Bar & Workspace Styles** | 9 bar styles (Dynamic, Flat, Floating, Islands, One island, Frame, Pills, Notch, etc.) and 9 workspace styles (dots, Pac-Man, letters) |
| **Dynamic Island** | Center clock that expands into media player, volume, workspaces, notifications, battery/charger, and screen recording |
| **Today & System Card** | Click the clock (or `SUPER + ALT + D`) for calendar, weather, day wave, and CPU/GPU/RAM/disk rings |
| **Drag-and-Drop Layout** | 5 Material 3 presets + drag-and-drop modules (launcher, workspaces, title, music, island, tray, volume, Bluetooth, Wi-Fi, battery, notifications, power, visualizer) |
| **Distro Logo** | Automatically shows your distro's icon in the bar, welcome screen, and Settings |

## Desktop Widgets, Wallpapers & Vibe

| Feature | Details |
| --- | --- |
| **Desktop Widgets** | Frosted-glass or solid cards (auto-hide when windows cover the screen): clock, calendar, weather, music, lyrics, CPU/GPU/RAM/storage, user card, battery gauges, audio visualizer (Bars, Mirror, Wave, Dots), to-do, focus timer, and notes |
| **Edit Mode** | `SUPER + ALT + W` opens a side panel to add, move, resize, and restyle widgets |
| **Wallpaper Picker** | `SUPER + W` opens a searchable wallpaper sheet with shuffle, Waypaper folders, and automatic palette extraction |
| **Animations & Live Wallpapers** | Transitions (Ripple, Wave, Wipe, Portal, Fade, Slide, Dissolve), slideshows, video wallpapers (`mpvpaper`), and shell-drawn animated scenes (Aurora, Starfall, Orbit, Mesh) |
| **Desktop Menu** | Right-click the desktop for quick wallpaper switching, night light, DND, gaming mode, lock, and Settings shortcuts |
| **Vibe Mode** | Music-reactive desktop: cover-art colors, bar visualizer, screen-edge glow, breathing island, lockscreen album ring, synced desktop lyrics, and weather particles (rain, snow, fog, cherry petals, fireflies) |

## Themes, Appearance & Sounds

| Feature | Details |
| --- | --- |
| **Color Schemes & Themes** | 21 schemes (Auto, Grey, monochrome, and 13 accents) plus 17 one-click preset themes (Catppuccin, Rosé Pine, Tokyo Night, Gruvbox, Nord, Everforest, Kanagawa, OLED, Brutal, Sakura, etc.) |
| **App Integration** | Applies your palette to Waybar, borders, notifications, lockscreen, VS Code / VSCodium, and Discord (Vesktop, Vencord, Equicord, BetterDiscord) |
| **Explore Community Themes** | Browse verified `.dstheme` community setups and share yours ([guide](../community/README.md)) |
| **Typography & Components** | Uses **Google Sans Flex** (UI) and **Google Sans Code** (code), JetBrainsMono Nerd Font (terminal), plus shape/corner/slider controls |
| **Motion** | Animation presets (calm, lively, bouncy, snappy, minimal), speed, spring/easing curves |
| **Cursors** | Bibata, Hyprcursor themes, and downloadable packs (Catppuccin, Phinger) with live preview |
| **SFX & Notification Sounds** | 8 UI sound packs (Pebble, Tap, Soft, Pluck, Keys, Crystal, Bubble, Retro) and 10 notification tones |

## Dock & Launcher

| Feature | Details |
| --- | --- |
| **Dock** | Bottom, left, or right edge; pinned/open apps, dedicated app menu with search, hover-to-reveal, media controls, and icon tinting |
| **DarkShadow Launcher** | `ALT + Space` with 5 themes (Shadow, Graphite, Midnight, Rose, Paper), list/grid/bar/split layouts, math calculator, unit/currency converter, emoji picker (`:`), and home file search |
| **Control Center & Notifications** | `SUPER + A` / `SUPER + N`: quick toggles, media seek wave, and Google-style (or swaync) pop-ups with actions and timeout progress |

## Infinite Desktop & Touchpad Gestures

| Feature | Details |
| --- | --- |
| **Infinite Desktop** | `SUPER + F`: turn a workspace (or all screens) into an endless floating canvas with cursor-centered zoom and edge-push dragging |
| **Touchpad Gestures** | Continuous 1:1 two-finger pinch zoom on the canvas, pointer isolation during canvas pan, and configurable 3/4-finger swipe/pinch actions in Settings |

## System, Care, Lockscreen & Security

| Feature | Details |
| --- | --- |
| **SDDM Login Screen** | Material 3 SDDM theme synced to your wallpaper, colors, font, and avatar (`rice-sddm`) |
| **Idle & Lockscreen** | Material 3 lockscreen with blurred wallpaper, clock styles, weather/battery/system chips, and media wave (`hyprlock` fallback) |
| **Screenshots & Recording** | Region/full screenshots with built-in editor (arrows, boxes, blur, text, pinned shots, QR scanner) and region recording |
| **Game Bar & Performance** | `SUPER + G` overlay (CPU/GPU temp, RAM, ping, quick controls) + one-click blur/transparency toggle and Gaming mode |
| **Care, Profiles & Screen Time** | Full system updates (with snapper/timeshift snapshots), cache cleaner, single-file setup backup, named profiles (`rice-profile`), and local screen-time stats (`rice-screentime`) |
| **Window Rules & Equalizer** | Per-app rules saved safely in `~/.config/rice/rules.json`, optional gaming workspace, and 8 EasyEffects EQ presets (`rice-eq`) |
| **Keyboard, Languages & Monitors** | Up to 4 keyboard layouts, English & Polish UI (with CJK font helper), and display configuration for Hyprland and niri |
| **Welcome & Sync** | Mandatory 6-step first-login onboarding wizard (`Language & region`, `Look`, `Bar & dock`, `Font & cursor`, `Profile & lock screen`, `Summary`, replayable anytime via `rice-welcome show`) and `./sync.sh` to export your settings safely without secrets |
