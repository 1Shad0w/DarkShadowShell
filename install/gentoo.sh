#!/usr/bin/env bash
# shellcheck shell=bash disable=SC2024
# DarkShadow's Shell on Gentoo (V6.70): the packages with Portage.
#
#   ./install.sh                 on Gentoo uses this file for the packages, then sets up the shell as everywhere
#   bash install/gentoo.sh       only the packages (the same steps), for example to see what Portage does first
#   bash install/gentoo.sh --pretend    shows what would be emerged and changes nothing
#
# What it does, in order:
#   1. the two ebuild repositories the desktop needs: GURU (Quickshell, matugen, swaync, cliphist, mpvpaper ...)
#      and hyproverlay (Hyprland and its tools: Gentoo moved them there in 2026), with eselect repository
#   2. reads the package lists (emaint sync; the main tree only when it is older than a week, --no-upgrade skips it)
#   3. picks every package the shell uses from the repositories you have (a few have other names in some trees),
#      leaves out the ones already installed, and writes the keywords (~amd64) and USE flags they need into
#      $GENTOO_ETC/package.accept_keywords/darkshadow-shell and $GENTOO_ETC/package.use/darkshadow-shell
#   4. lets Portage work out what else must change (--autounmask) and keeps only those changes to the package.*
#      files (never anything else in /etc)
#   5. emerges them (binary packages from your binhost when you have one), one by one when together fails
#   6. turns the services on with OpenRC or systemd (D-Bus, elogind, NetworkManager, Bluetooth, power modes)
#
# Compiling Qt 6, Hyprland and the rest takes from one to several hours on the first run. Nothing is removed and
# your world file only gets the packages listed here.

# ------------------------------------------------------------------ standalone: the installer's helpers
GENTOO_SELF="${BASH_SOURCE[0]}"
if [ "${GENTOO_SOURCED:-0}" != 1 ] && [ "$GENTOO_SELF" = "$0" ]; then
  set -Euo pipefail
  ROOT="$(cd "$(dirname "$GENTOO_SELF")/.." && pwd)"
  # shellcheck source=lib/ui.sh
  . "$ROOT/install/lib/ui.sh"
  # shellcheck source=lib/distro.sh
  . "$ROOT/install/lib/distro.sh"
  LOG="${LOG:-$HOME/.cache/darkshadow-gentoo.log}"; mkdir -p "$(dirname "$LOG")"; : >>"$LOG"
  DRY_RUN=0; NO_UPGRADE=0; WM="${WM:-hyprland}"
  for a in "$@"; do
    case "$a" in
      --pretend|-p|--dry-run) DRY_RUN=1 ;;
      --no-upgrade) NO_UPGRADE=1 ;;
      --niri) WM=niri ;; --both) WM=both ;;
      -h|--help) sed -n '2,22p' "$GENTOO_SELF" | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) echo "unknown option: $a (see --help)"; exit 2 ;;
    esac
  done
  has_hypr() { [ "$WM" = hyprland ] || [ "$WM" = both ]; }
  has_niri() { [ "$WM" = niri ] || [ "$WM" = both ]; }
  GENTOO_ALONE=1
else
  GENTOO_ALONE=0
fi

# ------------------------------------------------------------------ what the shell needs
# "a|b": the first one your repositories have. Every name is CATEGORY/PACKAGE.
GENTOO_DESKTOP=(gui-apps/hyprlock gui-apps/hypridle gui-apps/hyprsunset "sys-auth/hyprpolkitagent|gui-apps/hyprpolkitagent"
                sys-apps/xdg-desktop-portal sys-apps/xdg-desktop-portal-gtk dev-qt/qtwayland)
GENTOO_HYPR=(gui-wm/hyprland gui-libs/xdg-desktop-portal-hyprland)
GENTOO_NIRI=(gui-wm/niri gui-apps/xwayland-satellite sys-apps/xdg-desktop-portal-gnome x11-misc/gammastep)
GENTOO_SHELL=(gui-apps/quickshell dev-qt/qtmultimedia dev-qt/qtsvg dev-qt/qtdeclarative
              "gui-apps/swaync|gui-apps/swaynotificationcenter" "gui-apps/awww|gui-apps/swww" media-sound/cava
              x11-terms/kitty app-shells/fish app-misc/fastfetch gnome-base/nautilus x11-misc/matugen)
GENTOO_TOOLS=(gui-apps/wf-recorder gui-apps/grim gui-apps/slurp gui-apps/wl-clipboard app-misc/cliphist gui-apps/wtype
              x11-libs/libnotify x11-misc/xdg-user-dirs x11-misc/xdg-utils app-misc/jq net-misc/curl dev-lang/python
              media-sound/playerctl app-misc/brightnessctl media-sound/pamixer media-gfx/imagemagick media-video/ffmpeg
              media-video/mpv gui-apps/mpvpaper gnome-extra/zenity net-misc/networkmanager net-wireless/bluez
              media-video/pipewire media-video/wireplumber sys-process/btop app-misc/cmatrix media-sound/pavucontrol
              gnome-extra/gnome-calendar sys-power/upower sys-power/power-profiles-daemon sys-apps/dbus
              app-arch/unzip app-arch/xz-utils app-arch/tar dev-vcs/git)
GENTOO_FONTS=(media-fonts/jetbrains-mono media-fonts/noto media-fonts/noto-emoji media-fonts/inter
              "media-fonts/symbols-nerd-font|media-fonts/nerd-fonts-symbols|media-fonts/nerdfonts")
GENTOO_LOOK=(x11-themes/papirus-icon-theme "x11-themes/adw-gtk3|x11-themes/adw-gtk-theme" x11-themes/adwaita-icon-theme
             x11-themes/gnome-themes-standard "x11-themes/bibata-xcursors|x11-themes/bibata-cursor-theme")
# without systemd: the seat (Hyprland and niri need elogind or seatd)
GENTOO_NOSYSTEMD=(sys-auth/elogind)
# the shell cannot start without these: said loudly when they cannot be found
GENTOO_MUST=(gui-apps/quickshell)
# the ebuild repositories (eselect repository enable NAME)
GENTOO_REPOS=(guru hyproverlay)
# USE flags the shell's features need (a flag a package does not have is ignored by Portage)
GENTOO_USE='# DarkShadow'"'"'s Shell (install/gentoo.sh): the features the shell uses. Remove a line to drop it.
# the crash handler needs dev-cpp/cpptrace[unwind], which Gentoo does not build that way: off (the shell does not use it)
gui-apps/quickshell wayland layer-shell session-lock screencopy toplevel-management hyprland i3 sockets jemalloc tray pipewire mpris pam policykit upower notifications bluetooth networkmanager -crash-handler
media-video/ffmpeg x264 encode gpl lame opus vorbis vpx webp
media-video/mpv libmpv wayland
media-gfx/imagemagick jpeg png webp svg
x11-terms/kitty wayland
media-sound/cava pipewire
net-wireless/bluez obex
gnome-base/nautilus previewer
dev-qt/qtmultimedia ffmpeg
# what their dependencies need (swaync, Qt Multimedia)
gui-libs/gtk4-layer-shell introspection vala
dev-libs/libdbusmenu gtk3
sys-libs/zlib minizip'
GENTOO_PIPEWIRE_USE='media-video/pipewire sound-server pipewire-alsa'

# ------------------------------------------------------------------ small helpers
# the fallbacks when this file runs alone (install.sh has its own)
command -v svc_on >/dev/null 2>&1 || svc_on() {
  if [ "$INIT_SYS" = systemd ]; then task "$1" sudo systemctl enable --now "$2.service"
  else task "$1" sudo "$ROOT/bin/rice-sys" service-enable "$3"; fi
}
command -v sudo_keepalive >/dev/null 2>&1 || sudo_keepalive() {
  [ "$DRY_RUN" = 1 ] && return 0
  info "Some steps need administrator rights (sudo)."
  sudo -v || { fail "sudo failed, skipping packages"; return 1; }
  ( while true; do sudo -n true 2>/dev/null; sleep 50; done ) &
  SUDO_PID=$!
}

GENTOO_ARCH=""
# where Portage keeps what is installed and its settings (other places only for the tests)
GENTOO_VDB="${GENTOO_VDB:-/var/db/pkg}"
GENTOO_ETC="${GENTOO_ETC:-/etc/portage}"
GENTOO_REPO_PATHS=()
GENTOO_PICKED=()      # what will be emerged
GENTOO_HAVE=()        # already installed
GENTOO_ABSENT=()      # not in any repository you have
GENTOO_OVERLAY=()     # picked from GURU or hyproverlay: they get the testing keyword

gentoo_arch() {
  GENTOO_ARCH="$(portageq envvar ARCH 2>/dev/null || true)"
  [ -n "$GENTOO_ARCH" ] || case "$(uname -m)" in x86_64) GENTOO_ARCH=amd64 ;; aarch64) GENTOO_ARCH=arm64 ;; *) GENTOO_ARCH="$(uname -m)" ;; esac
}
# every repository you have and where it lives ("NAME PATH" lines)
gentoo_repo_paths() {
  GENTOO_REPO_PATHS=()
  local r p
  for r in $(portageq get_repos / 2>/dev/null); do
    p="$(portageq get_repo_path / "$r" 2>/dev/null || true)"
    [ -n "$p" ] && [ -d "$p" ] && GENTOO_REPO_PATHS+=("$r $p")
  done
}
# gentoo_where CAT/PKG: the repository that has it (nothing when none)
gentoo_where() {
  local e r p
  for e in "${GENTOO_REPO_PATHS[@]}"; do
    r="${e%% *}"; p="${e#* }"
    compgen -G "$p/$1/*.ebuild" >/dev/null 2>&1 && { echo "$r"; return 0; }
  done
  return 0
}
gentoo_installed() { compgen -G "$GENTOO_VDB/$1-[0-9]*" >/dev/null 2>&1; }
gentoo_wanted() {
  local list=("${GENTOO_DESKTOP[@]}" "${GENTOO_SHELL[@]}" "${GENTOO_TOOLS[@]}" "${GENTOO_FONTS[@]}" "${GENTOO_LOOK[@]}")
  if declare -F has_hypr >/dev/null && has_hypr; then list+=("${GENTOO_HYPR[@]}"); fi
  if declare -F has_niri >/dev/null && has_niri; then list+=("${GENTOO_NIRI[@]}"); fi
  [ "$INIT_SYS" = systemd ] || list+=("${GENTOO_NOSYSTEMD[@]}")
  printf '%s\n' "${list[@]}"
}
# sorts what the shell needs into: to emerge, installed already, not in your repositories
gentoo_pick() {
  GENTOO_PICKED=(); GENTOO_HAVE=(); GENTOO_ABSENT=(); GENTOO_OVERLAY=()
  local want alts a hit repo inst
  while IFS= read -r want; do
    [ -n "$want" ] || continue
    IFS='|' read -r -a alts <<<"$want"
    hit=""; inst=""
    for a in "${alts[@]}"; do gentoo_installed "$a" && { inst="$a"; break; }; done
    if [ -n "$inst" ]; then GENTOO_HAVE+=("$inst"); continue; fi
    for a in "${alts[@]}"; do
      repo="$(gentoo_where "$a")"
      if [ -n "$repo" ]; then
        hit="$a"
        case "$repo" in gentoo) : ;; *) GENTOO_OVERLAY+=("$a") ;; esac
        break
      fi
    done
    if [ -n "$hit" ]; then GENTOO_PICKED+=("$hit"); else GENTOO_ABSENT+=("${want//|/ or }"); fi
  done < <(gentoo_wanted)
  return 0
}

# the repositories: eselect repository (and git, to sync them), then GURU and hyproverlay turned on
gentoo_repos() {
  local need=() r on
  command -v eselect >/dev/null 2>&1 && eselect repository list >/dev/null 2>&1 || need+=(app-eselect/eselect-repository)
  command -v git >/dev/null 2>&1 || need+=(dev-vcs/git)
  if [ "${#need[@]}" -gt 0 ]; then
    live "Installing ${need[*]} (to add ebuild repositories)" sudo emerge --noreplace --quiet-build=y "${need[@]}" || {
      fail "Could not install ${need[*]}"; return 1; }
  fi
  for r in "${GENTOO_REPOS[@]}"; do
    on="$(portageq get_repo_path / "$r" 2>/dev/null || true)"
    if [ -n "$on" ]; then
      ok "The $r repository is on"
    else
      task "Turning on the $r ebuild repository" sudo eselect repository enable "$r" || warn "Could not turn on $r: eselect repository enable $r"
    fi
  done
  return 0
}
# the package lists: GURU and hyproverlay always (they change daily), the main tree when it is older than a week
gentoo_sync() {
  local r ts age
  for r in "${GENTOO_REPOS[@]}"; do
    live "Reading the $r repository (emaint sync)" sudo emaint sync -r "$r" || warn "Syncing $r failed: sudo emaint sync -r $r"
  done
  if [ "${NO_UPGRADE:-0}" = 1 ]; then note "Not syncing the main Gentoo tree (--no-upgrade)"; return 0; fi
  ts="$(portageq get_repo_path / gentoo 2>/dev/null)/metadata/timestamp.chk"
  age=999
  [ -f "$ts" ] && age=$(( ($(date +%s) - $(date -r "$ts" +%s)) / 86400 ))
  if [ "$age" -gt 7 ]; then
    live "Reading the Gentoo tree (it is $age days old)" sudo emaint sync -r gentoo || warn "Syncing the Gentoo tree failed: sudo emaint sync -r gentoo"
  else
    ok "The Gentoo tree is fresh ($age days)"
  fi
  return 0
}

# the keywords and USE flags, in their own files (removing them takes the shell's settings out again)
gentoo_config() {
  local kw ufile kfile a tmp d
  kfile=$GENTOO_ETC/package.accept_keywords/darkshadow-shell
  ufile=$GENTOO_ETC/package.use/darkshadow-shell
  # package.use / package.accept_keywords as one file (an old setup) cannot get our file next to it
  for d in "$GENTOO_ETC/package.accept_keywords" "$GENTOO_ETC/package.use"; do
    if [ -f "$d" ]; then
      warn "$d is a file, not a folder: the shell's lines are added at its end"
    else
      sudo mkdir -p "$d" || return 1
    fi
  done
  [ -f "$GENTOO_ETC/package.accept_keywords" ] && kfile="$GENTOO_ETC/package.accept_keywords"
  [ -f "$GENTOO_ETC/package.use" ] && ufile="$GENTOO_ETC/package.use"
  tmp="$(mktemp)"
  {
    echo "# DarkShadow's Shell (install/gentoo.sh): packages from GURU and hyproverlay, and the ones Gentoo has only in"
    echo "# testing (~$GENTOO_ARCH), are taken from testing"
    for a in "${GENTOO_OVERLAY[@]}"; do echo "$a ~$GENTOO_ARCH"; done
    for a in "${GENTOO_PICKED[@]}"; do
      case " ${GENTOO_OVERLAY[*]} " in *" $a "*) continue ;; esac
      [ -n "$(portageq best_visible / "$a" 2>/dev/null || true)" ] || echo "$a ~$GENTOO_ARCH"
    done
    # what an earlier run keyworded stays (it is visible now only because of this file)
    [ -f "$kfile" ] && [ "$kfile" != "$GENTOO_ETC/package.accept_keywords" ] && grep -v '^#' "$kfile"
  } | awk '!seen[$0]++' >"$tmp"
  if [ "$kfile" = "$GENTOO_ETC/package.accept_keywords" ]; then
    # one file: add only the lines it does not have
    while IFS= read -r kw; do grep -qxF "$kw" "$kfile" 2>/dev/null || echo "$kw"; done <"$tmp" | sudo tee -a "$kfile" >/dev/null
  else
    sudo install -m 644 "$tmp" "$kfile"
  fi
  {
    printf '%s\n' "$GENTOO_USE"
    # PipeWire as the sound server, unless PulseAudio's own daemon is installed (they block each other)
    if ! gentoo_installed media-sound/pulseaudio-daemon; then printf '%s\n' "$GENTOO_PIPEWIRE_USE"; fi
  } >"$tmp"
  if [ "$ufile" = "$GENTOO_ETC/package.use" ]; then
    while IFS= read -r kw; do [ -z "$kw" ] || grep -qxF "$kw" "$ufile" 2>/dev/null || echo "$kw"; done <"$tmp" | sudo tee -a "$ufile" >/dev/null
  else
    sudo install -m 644 "$tmp" "$ufile"
  fi
  rm -f "$tmp"
  # Portage writes its own changes (--autounmask) into the last file of each folder: this one, so a later run of
  # this script can rewrite darkshadow-shell without losing them
  for d in package.accept_keywords package.use package.license; do
    [ -f "$GENTOO_ETC/$d" ] && continue
    sudo mkdir -p "$GENTOO_ETC/$d"
    [ -e "$GENTOO_ETC/$d/zz-darkshadow-autounmask" ] ||
      echo "# DarkShadow's Shell: what Portage's --autounmask found the shell's packages need" | sudo tee "$GENTOO_ETC/$d/zz-darkshadow-autounmask" >/dev/null
  done
  echo "keywords: $kfile, USE flags: $ufile"
}

# Portage's own answer to "what else has to change": --autounmask writes it as ._cfg files (config protection).
# Only the ones for the package.* settings are put in place; anything else stays for you (etc-update)
gentoo_take_autounmask() {
  local f dir base target n=0
  while IFS= read -r -d '' f; do
    dir="$(dirname "$f")"; base="$(basename "$f")"
    target="$dir/${base#._cfg[0-9][0-9][0-9][0-9]_}"
    case "$target" in
      "$GENTOO_ETC"/package.*) sudo mv -f "$f" "$target" && n=$((n + 1)) ;;
    esac
  done < <(sudo find "$GENTOO_ETC" -maxdepth 2 -name '._cfg[0-9][0-9][0-9][0-9]_*' -print0 2>/dev/null | sort -z)
  echo "$n settings files updated"
}
GENTOO_EMERGE_OPTS=()
gentoo_emerge_opts() {
  GENTOO_EMERGE_OPTS=(--noreplace --verbose --quiet-build=y --keep-going=y --with-bdeps=n)
  # binary packages when you have a binhost (Gentoo's own is set up in /etc/portage/binrepos.conf)
  if compgen -G "$GENTOO_ETC/binrepos.conf/*.conf" >/dev/null 2>&1 || [ -s "$GENTOO_ETC/binrepos.conf" ]; then
    GENTOO_EMERGE_OPTS+=(--getbinpkg=y)
  fi
}
gentoo_autounmask() {
  # --autounmask-only writes Portage's changes (as ._cfg files) and merges nothing; --pretend then says whether
  # everything can be installed with them. Up to three rounds: a change can show the need for another one
  local out moved
  out="$(mktemp)"
  for _ in 1 2 3; do
    sudo emerge --autounmask=y --autounmask-write=y --autounmask-only=y --autounmask-keep-masks=y \
         --autounmask-backtrack=y "${GENTOO_EMERGE_OPTS[@]}" "${GENTOO_PICKED[@]}" >>"$LOG" 2>&1
    moved="$(gentoo_take_autounmask)"; echo "$moved"
    if sudo emerge --pretend "${GENTOO_EMERGE_OPTS[@]}" "${GENTOO_PICKED[@]}" >"$out" 2>&1; then
      cat "$out" >>"$LOG"; rm -f "$out"; return 0
    fi
    cat "$out" >>"$LOG"
    [ "${moved%% *}" = 0 ] && break      # nothing more Portage can change by itself
  done
  # what Portage said, shortened: the reason is in these lines
  grep -E "^!!!|^- |conflict|blocked|masked by|required by|^>=|^[a-z0-9-]+/[a-zA-Z0-9_+-]+ " "$out" | head -24
  rm -f "$out"
  return 1
}

# ------------------------------------------------------------------ the services
gentoo_services() {
  local default=""
  [ "$INIT_SYS" = openrc ] && default="$(rc-update show default 2>/dev/null || true)"
  if [ "$INIT_SYS" = openrc ]; then
    svc_on "D-Bus (OpenRC)" dbus dbus
    if gentoo_installed sys-auth/elogind; then
      task "elogind at boot (the seat Hyprland and niri need)" sudo rc-update add elogind boot || true
    fi
  fi
  if gentoo_installed net-misc/networkmanager; then
    # two network managers fight: dhcpcd or netifrc (net.eth0 ...) keep your network then
    if printf '%s\n' "$default" | grep -qE '^[[:space:]]*(dhcpcd|net\.[a-z0-9]+|connman|iwd)[[:space:]]'; then
      warn "Your network runs with $(printf '%s\n' "$default" | grep -oE '^[[:space:]]*(dhcpcd|net\.[a-z0-9]+|connman|iwd)' | head -1 | tr -d ' '): NetworkManager is not turned on, so nothing breaks."
      note "The Wi-Fi menu needs NetworkManager: turn that one off and NetworkManager on, then reboot"
    else
      svc_on "Turning on NetworkManager" NetworkManager NetworkManager
    fi
  fi
  gentoo_installed net-wireless/bluez && svc_on "Turning on the Bluetooth service" bluetooth "bluetooth|bluetoothd"
  if gentoo_installed sys-power/power-profiles-daemon && ! gentoo_installed sys-power/tlp && ! gentoo_installed sys-power/auto-cpufreq; then
    svc_on "Turning on power modes (power-profiles-daemon)" power-profiles-daemon power-profiles-daemon
  fi
  # PipeWire: systemd starts it per user (these units); without systemd the shell's session starts it
  if [ "$INIT_SYS" = systemd ] && gentoo_installed media-video/pipewire; then
    task "PipeWire for your user (systemd)" systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service || true
  fi
  # the groups for the brightness keys and Infinite Desktop's mouse
  local g add=() me="${USER:-$(id -un)}"
  for g in video input; do getent group "$g" >/dev/null && ! id -nG "$me" | grep -qw "$g" && add+=("$g"); done
  if [ "${#add[@]}" -gt 0 ]; then task "Adding you to the groups ${add[*]} (from the next login)" sudo usermod -aG "$(IFS=,; echo "${add[*]}")" "$me" || true; fi
  return 0
}

# ------------------------------------------------------------------ all of it
gentoo_packages() {
  command -v emerge >/dev/null 2>&1 || { fail "emerge not found: this is not a Gentoo system"; return 1; }
  sudo_keepalive || return 0
  gentoo_arch
  local prof; prof="$(eselect profile show 2>/dev/null | tail -1 | tr -d ' ' || true)"
  info "Gentoo ($GENTOO_ARCH, ${prof:-unknown profile}, $INIT_SYS)"
  case "$prof" in
    */desktop*) : ;;
    *) warn "Your profile is not a desktop one: Qt, PipeWire and GTK miss USE flags they need, and much more compiles."
       note "A desktop profile is best:  eselect profile list  then  sudo eselect profile set NUMBER  (…/desktop or …/desktop/systemd)" ;;
  esac
  local mk; mk="$(portageq envvar MAKEOPTS 2>/dev/null || true)"
  [ -n "$mk" ] || note "MAKEOPTS is not set: add  MAKEOPTS=\"-j$(nproc)\"  to /etc/portage/make.conf to compile on every core"
  if [ "$DRY_RUN" = 1 ]; then
    gentoo_repo_paths; gentoo_pick
    info "would turn on the repositories ${GENTOO_REPOS[*]} and emerge ${#GENTOO_PICKED[@]} packages: ${GENTOO_PICKED[*]}"
    [ "${#GENTOO_ABSENT[@]}" -gt 0 ] && note "not in your repositories yet (before syncing GURU / hyproverlay): ${GENTOO_ABSENT[*]}"
    return 0
  fi
  if pgrep -x emerge >/dev/null 2>&1; then
    warn "Another emerge is running: this one waits for Portage's lock"
  fi
  # an update with everything installed: nothing to sync or emerge (only the services are checked)
  gentoo_repo_paths; gentoo_pick
  local r all_on=1
  for r in "${GENTOO_REPOS[@]}"; do [ -n "$(portageq get_repo_path / "$r" 2>/dev/null || true)" ] || all_on=0; done
  if [ "${#GENTOO_PICKED[@]}" = 0 ] && [ "$all_on" = 1 ]; then
    :
  else
    gentoo_repos || return 0
    gentoo_sync
    # the repositories may be new or changed: look again
    gentoo_repo_paths; gentoo_pick
  fi
  note "${#GENTOO_HAVE[@]} installed already, ${#GENTOO_PICKED[@]} to emerge${GENTOO_ABSENT[0]:+, not in your repositories: ${GENTOO_ABSENT[*]}}"
  local m must=("${GENTOO_MUST[@]}")
  if declare -F has_hypr >/dev/null && has_hypr; then must+=(gui-wm/hyprland); fi
  for m in "${must[@]}"; do
    case " ${GENTOO_ABSENT[*]} " in *" $m "*) fail "$m is in none of your repositories: are GURU and hyproverlay on? (eselect repository list -i)" ;; esac
  done
  if [ "${#GENTOO_PICKED[@]}" -gt 0 ]; then
    task "Keywords and USE flags for the shell's packages" gentoo_config
    gentoo_emerge_opts
    local why; why="$(mktemp)"
    if task "Asking Portage what else has to change (autounmask)" gentoo_autounmask_to "$why"; then :; else
      warn "Portage cannot install everything together yet:"
      sed 's/^/        /' "$why"
      note "The packages it can are emerged now, the rest one by one; the full answer is in $LOG"
    fi
    rm -f "$why"
    note "Compiling takes long the first time (Qt 6 and Hyprland: an hour or more). The bars below show where it is."
    if ! live "Emerging ${#GENTOO_PICKED[@]} packages: desktop, shell, tools and fonts" sudo emerge "${GENTOO_EMERGE_OPTS[@]}" "${GENTOO_PICKED[@]}"; then
      warn "Emerging them together did not finish, trying one by one"
      local p failed=()
      for p in "${GENTOO_PICKED[@]}"; do
        gentoo_installed "$p" && continue
        live "  $p" sudo emerge "${GENTOO_EMERGE_OPTS[@]}" "$p" || failed+=("$p")
      done
      if [ "${#failed[@]}" -gt 0 ]; then
        warn "Could not emerge: ${failed[*]}"
        note "See why:  sudo emerge -pv ${failed[*]}   (the log: $LOG)"
      fi
    fi
  else
    ok "Every package the shell uses is installed"
  fi
  # matugen (the colors from the wallpaper): its GitHub release when no repository has it
  if ! command -v matugen >/dev/null 2>&1 && declare -F matugen_download >/dev/null; then
    if task "matugen (theme colors) from its GitHub releases" matugen_download; then ok "matugen is in ~/.local/bin"
    else warn "matugen could not be installed: colors from the wallpaper will not change (cargo install matugen works too)"; fi
  fi
  gentoo_services
  # without systemd: a login session that starts its own D-Bus (install.sh's)
  if [ "$INIT_SYS" != systemd ] && declare -F nosystemd_sessions >/dev/null; then
    task "Login sessions with their own D-Bus (no systemd)" nosystemd_sessions
  fi
  if ! pgrep -x elogind-daemon >/dev/null 2>&1 && ! pgrep -x elogind >/dev/null 2>&1 && ! pgrep -x seatd >/dev/null 2>&1 && [ "$INIT_SYS" != systemd ]; then
    warn "elogind is not running yet: reboot once before starting Hyprland (it needs a seat)"
  fi
  return 0
}
# task runs a function and keeps its output for the log; this one also leaves Portage's reasons in a file
gentoo_autounmask_to() { local out; out="$(gentoo_autounmask)"; local rc=$?; printf '%s\n' "$out" | grep -v 'settings files updated$' >"$1"; printf '%s\n' "$out"; return $rc; }

if [ "$GENTOO_ALONE" = 1 ]; then
  [ "$FAMILY" = gentoo ] || { fail "This is $DISTRO_NAME, not Gentoo: use ./install.sh"; exit 1; }
  gentoo_packages
  rc=$?
  [ -n "${SUDO_PID:-}" ] && kill "$SUDO_PID" 2>/dev/null
  echo
  ok "Done. Now ./install.sh sets up the shell itself (it skips what is installed)."
  exit "$rc"
fi
