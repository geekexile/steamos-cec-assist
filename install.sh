#!/bin/sh
# Install cec-assist for the current user. No root needed; everything lives in
# your home directory, so it survives SteamOS updates.
set -e
cd "$(dirname "$0")"

command -v cecd >/dev/null 2>&1 || {
    echo "cecd not found: this needs SteamOS with Valve's CEC daemon." >&2; exit 1; }
systemctl --user cat cecd.service >/dev/null 2>&1 || {
    echo "cecd.service user unit not found." >&2; exit 1; }

install -Dm755 cec-assist "$HOME/.local/bin/cec-assist"
install -Dm644 cec-assist.service "$HOME/.config/systemd/user/cec-assist.service"
mkdir -p "$HOME/.config/cec-assist"
[ -e "$HOME/.config/cec-assist/config.ini" ] || \
    install -m644 config.example.ini "$HOME/.config/cec-assist/config.example.ini"

systemctl --user daemon-reload
systemctl --user enable --now cec-assist.service

echo
echo "cec-assist installed and running."
echo "  status:  $HOME/.local/bin/cec-assist status"
echo "  logs:    journalctl --user -u cec-assist -f"
echo "  remap:   $HOME/.local/bin/cec-assist remap --help"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *)
    echo "Note: ~/.local/bin is not on your PATH; use the full path above." ;; esac
