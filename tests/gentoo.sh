#!/usr/bin/env bash
# Checks install/gentoo.sh without Gentoo: fake repositories, a fake installed-package database and stand-ins for
# portageq, eselect, emaint, emerge and sudo. Covers picking packages (first name a repository has, installed ones
# left out, missing ones reported), the keywords and USE files (testing-only packages keyworded, earlier keywords
# kept, PipeWire's sound server left off next to PulseAudio), taking only package.* changes from autounmask, the
# distro detection and that install.sh hands Gentoo to this file. Runs anywhere, in CI on every push.
set -Euo pipefail
# shellcheck disable=SC2034
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

n=0
ok() { n=$((n + 1)); printf 'ok %d - %s\n' "$n" "$1"; }
bad() { printf 'not ok %d - %s\n' "$((n + 1))" "$1"; exit 1; }

# ---- a fake Gentoo: three repositories, an installed-package database, /etc/portage
mk() { mkdir -p "$tmp/repos/$1/$2"; : >"$tmp/repos/$1/$2/$(basename "$2")-1.0.ebuild"; }
for p in dev-qt/qtwayland media-video/pipewire app-shells/fish sys-auth/elogind gui-apps/wf-recorder \
         sys-apps/xdg-desktop-portal x11-themes/papirus-icon-theme; do mk gentoo "$p"; done
for p in gui-apps/quickshell gui-apps/awww x11-misc/matugen gui-apps/swaync x11-themes/bibata-xcursors; do mk guru "$p"; done
for p in gui-wm/hyprland gui-apps/hyprlock sys-auth/hyprpolkitagent gui-libs/xdg-desktop-portal-hyprland; do mk hyproverlay "$p"; done
mkdir -p "$tmp/vdb/app-shells/fish-4.9.3" "$tmp/etc" "$tmp/bin"
cat >"$tmp/bin/portageq" <<EOF
#!/bin/bash
case "\$1" in
  get_repos) echo "hyproverlay guru gentoo" ;;
  get_repo_path) [ -d "$tmp/repos/\$3" ] && echo "$tmp/repos/\$3" ;;
  envvar) [ "\$3" = ARCH ] && echo amd64 ;;
  best_visible) [ "\$3" = gui-apps/wf-recorder ] || echo "\$3-1.0" ;;
esac
exit 0
EOF
printf '#!/bin/bash\n[ "$1" = -n ] && shift\nexec "$@"\n' >"$tmp/bin/sudo"
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH" GENTOO_VDB="$tmp/vdb" GENTOO_ETC="$tmp/etc"

# the installer's helpers this file uses
info() { :; }; note() { :; }; warn() { :; }; fail() { :; }
task() { shift; "$@" >/dev/null 2>&1; }
LOG="$tmp/log"; : >"$LOG"; DRY_RUN=0; INIT_SYS=openrc; ROOT="$root"
has_hypr() { return 0; }; has_niri() { return 1; }
# shellcheck source=../install/gentoo.sh
GENTOO_SOURCED=1 . "$root/install/gentoo.sh"

# ---- picking
GENTOO_DESKTOP=(dev-qt/qtwayland "gui-apps/hyprpolkitagent|sys-auth/hyprpolkitagent" gui-apps/hyprlock gui-apps/hyprsunset)
GENTOO_SHELL=(gui-apps/quickshell "gui-apps/awww|gui-apps/swww" app-shells/fish)
GENTOO_TOOLS=(gui-apps/wf-recorder media-video/pipewire)
GENTOO_FONTS=(); GENTOO_LOOK=("x11-themes/bibata-xcursors|x11-themes/bibata-cursor-theme")
gentoo_arch; gentoo_repo_paths; gentoo_pick
[ "$GENTOO_ARCH" = amd64 ] && ok "the architecture comes from Portage" || bad "arch: $GENTOO_ARCH"
[ "${#GENTOO_REPO_PATHS[@]}" = 3 ] && ok "every repository is found" || bad "repos: ${GENTOO_REPO_PATHS[*]}"
case " ${GENTOO_PICKED[*]} " in *" sys-auth/hyprpolkitagent "*) ok "an alternative name is taken when the first is in no repository" ;; *) bad "alternative: ${GENTOO_PICKED[*]}" ;; esac
case " ${GENTOO_PICKED[*]} " in *" app-shells/fish "*) bad "an installed package is emerged again" ;; *) ok "installed packages are left out" ;; esac
[ "${GENTOO_HAVE[*]}" = app-shells/fish ] && ok "installed packages are counted" || bad "have: ${GENTOO_HAVE[*]}"
[ "${GENTOO_ABSENT[*]}" = gui-apps/hyprsunset ] && ok "a package in no repository is reported" || bad "absent: ${GENTOO_ABSENT[*]}"
case " ${GENTOO_PICKED[*]} " in *" gui-wm/hyprland "*" sys-auth/elogind"*) ok "Hyprland is added for Hyprland, elogind without systemd" ;; *) bad "wm/init: ${GENTOO_PICKED[*]}" ;; esac
case " ${GENTOO_OVERLAY[*]} " in *" gui-apps/quickshell "*) case " ${GENTOO_OVERLAY[*]} " in *" gui-apps/awww "*) ok "packages from GURU are marked for keywords" ;; *) bad "overlay awww" ;; esac ;; *) bad "overlay: ${GENTOO_OVERLAY[*]}" ;; esac
case " ${GENTOO_OVERLAY[*]} " in *" dev-qt/qtwayland "*) bad "a main-tree package is marked as overlay" ;; *) ok "main-tree packages are not" ;; esac

# ---- the keywords and USE files
gentoo_config >/dev/null 2>&1 || bad "gentoo_config failed"
kw="$tmp/etc/package.accept_keywords/darkshadow-shell"; use="$tmp/etc/package.use/darkshadow-shell"
grep -qx "gui-apps/quickshell ~amd64" "$kw" && grep -qx "gui-wm/hyprland ~amd64" "$kw" && ok "overlay packages get ~amd64" || bad "keywords: $(cat "$kw")"
grep -qx "gui-apps/wf-recorder ~amd64" "$kw" && ok "a main-tree package with no stable version gets ~amd64" || bad "testing-only keyword"
grep -q "^dev-qt/qtwayland" "$kw" && bad "a stable package was keyworded" || ok "stable packages stay stable"
grep -q "^gui-apps/quickshell .*-crash-handler" "$use" && ok "Quickshell's crash handler (cpptrace[unwind]) is off" || bad "quickshell USE"
grep -q "^media-video/pipewire sound-server" "$use" && ok "PipeWire is the sound server" || bad "pipewire USE"
[ -f "$tmp/etc/package.use/zz-darkshadow-autounmask" ] && [ -f "$tmp/etc/package.accept_keywords/zz-darkshadow-autounmask" ] &&
  ok "Portage's own changes get a file of their own (the last in the folder)" || bad "no zz-darkshadow-autounmask"
echo ">=dev-libs/libdbusmenu-16.04.0-r4 gtk3" | tee -a "$tmp/etc/package.use/zz-darkshadow-autounmask" >/dev/null
# a second run, with wf-recorder now visible because of our file: its keyword stays
GENTOO_PICKED=(gui-apps/quickshell); GENTOO_OVERLAY=(gui-apps/quickshell)
mkdir -p "$tmp/vdb/media-sound/pulseaudio-daemon-17.0"
gentoo_config >/dev/null 2>&1 || bad "gentoo_config (again) failed"
grep -qx "gui-apps/wf-recorder ~amd64" "$kw" && ok "keywords of an earlier run are kept" || bad "kept keywords: $(cat "$kw")"
[ "$(grep -cx "gui-apps/quickshell ~amd64" "$kw")" = 1 ] && ok "no keyword twice" || bad "duplicate keyword"
grep -q "libdbusmenu" "$tmp/etc/package.use/zz-darkshadow-autounmask" && ok "a second run keeps Portage's changes" || bad "autounmask file lost"
grep -q "^media-video/pipewire sound-server" "$use" && bad "sound-server next to pulseaudio-daemon (they block each other)" || ok "no PipeWire sound server next to PulseAudio's daemon"

# ---- autounmask: only package.* files are taken
mkdir -p "$tmp/etc/package.use" "$tmp/etc/conf.d"
echo "new" >"$tmp/etc/package.use/._cfg0000_zz-autounmask"
echo "x" >"$tmp/etc/._cfg0000_make.conf"
echo "y" >"$tmp/etc/conf.d/._cfg0000_hostname"
gentoo_take_autounmask >/dev/null
[ "$(cat "$tmp/etc/package.use/zz-autounmask" 2>/dev/null)" = new ] && ok "autounmask's package.use change is put in place" || bad "autounmask not taken"
[ -f "$tmp/etc/._cfg0000_make.conf" ] && [ ! -f "$tmp/etc/make.conf" ] && ok "make.conf changes are left for you" || bad "make.conf touched"
[ -f "$tmp/etc/conf.d/._cfg0000_hostname" ] && ok "other config updates are left for etc-update" || bad "conf.d touched"

# ---- binhost
gentoo_emerge_opts
case " ${GENTOO_EMERGE_OPTS[*]} " in *--getbinpkg*) bad "binary packages without a binhost" ;; *) ok "no binhost: everything compiles" ;; esac
mkdir -p "$tmp/etc/binrepos.conf"; echo "[gentoo]" >"$tmp/etc/binrepos.conf/gentoobinhost.conf"
gentoo_emerge_opts
case " ${GENTOO_EMERGE_OPTS[*]} " in *--getbinpkg=y*) ok "a binhost is used when you have one" ;; *) bad "binhost ignored" ;; esac

# ---- the distro detection and install.sh
printf 'NAME=Gentoo\nID=gentoo\n' >"$tmp/os-release"
# distro.sh reads only /etc/os-release (never a path from the caller): the test reads a copy pointed at its own file
sed "s#/etc/os-release#$tmp/os-release#g" "$root/install/lib/distro.sh" >"$tmp/distro.sh"
fam="$(bash -c ". '$tmp/distro.sh'; echo \$FAMILY")"
[ "$fam" = gentoo ] && ok "Gentoo is detected" || bad "family: $fam"
printf 'NAME="Calculate Linux"\nID=calculate\nID_LIKE=gentoo\n' >"$tmp/os-release"
fam="$(bash -c ". '$tmp/distro.sh'; echo \$FAMILY")"
[ "$fam" = gentoo ] && ok "a Gentoo-based distro is detected" || bad "family (calculate): $fam"
grep -q 'GENTOO_SOURCED=1 . "$ROOT/install/gentoo.sh"' "$root/install.sh" && grep -q "gentoo_packages" "$root/install.sh" &&
  ok "install.sh hands Gentoo's packages to install/gentoo.sh" || bad "install.sh does not use install/gentoo.sh"
bash -n "$root/install/gentoo.sh" && ok "install/gentoo.sh parses" || bad "syntax"
out="$(bash "$root/install/gentoo.sh" --help 2>&1)"
case "$out" in *"--pretend"*) ok "it runs alone and explains itself (--help)" ;; *) bad "--help: $out" ;; esac
