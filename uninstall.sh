#!/bin/sh
# Remove cec-assist. Pass --purge to also remove button remaps and config.
set -e
systemctl --user disable --now cec-assist.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/cec-assist.service"
systemctl --user daemon-reload

if [ "$1" = "--purge" ]; then
    if [ -e "$HOME/.config/cecd/config.d/50-cec-assist-mappings.toml" ]; then
        rm -f "$HOME/.config/cecd/config.d/50-cec-assist-mappings.toml"
        systemctl --user restart cecd || true
        echo "Removed button remaps; cecd is back to its defaults."
    fi
    rm -rf "$HOME/.config/cec-assist"
fi
rm -f "$HOME/.local/bin/cec-assist"
echo "cec-assist uninstalled."
[ "$1" = "--purge" ] || echo "(Button remaps and config kept; run with --purge to remove them.)"
