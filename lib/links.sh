#!/system/bin/sh
# ColorOS-FCM links: open the settings pages a human still has to flip
# on ColorOS (per-app auto-launch and battery exemption live behind the
# app details page; ColorOS has no stable cross-model deep link for
# its auto-launch manager, so we land on app details on purpose).
# Usage: links.sh appdetails <pkg>|battery|bootid

export MODDIR="${MODDIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODDIR/lib/core.sh" || exit 1

case "${1:-}" in
    appdetails)
        [ -n "${2:-}" ] || { echo "usage: links.sh appdetails <pkg>"; exit 1; }
        am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d "package:$2"
        ;;
    battery)
        am start -a android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS
        ;;
    bootid)
        c_boot_count
        ;;
    *)
        echo "usage: links.sh appdetails <pkg>|battery|bootid"
        exit 1
        ;;
esac
