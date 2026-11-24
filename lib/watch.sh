#!/system/bin/sh
# ColorOS-FCM watch: timed monitoring loop.
# Usage: watch.sh [seconds] [interval] [heartbeat_every_rounds]
# Defaults: 90 15 4. Unstops targets when they are found stopped and
# sends a GCM heartbeat every N rounds.

export MODDIR="${MODDIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODDIR/lib/core.sh" || exit 1

c_identity_guard || exit 1

_total="${1:-90}"; _interval="${2:-15}"; _hb_every="${3:-4}"
_round=0
_elapsed=0

echo "watch: total=${_total}s interval=${_interval}s heartbeat_every=${_hb_every}"

while [ "$_elapsed" -le "$_total" ]; do
    _round=$((_round + 1))
    for pkg in $(c_load_targets); do
        if c_pkg_installed "$pkg" && c_pkg_stopped "$pkg"; then
            echo "[$(date '+%T')] $pkg stopped=true -> unstop"
            c_unstop "$pkg" >/dev/null 2>&1
        fi
    done
    if [ $((_round % _hb_every)) -eq 0 ]; then
        if c_heartbeat; then
            echo "[$(date '+%T')] heartbeat ok (round $_round)"
        else
            echo "[$(date '+%T')] heartbeat unconfirmed (round $_round)"
        fi
    fi
    [ "$_elapsed" -ge "$_total" ] && break
    sleep "$_interval"
    _elapsed=$((_elapsed + _interval))
done

echo "watch done: rounds=$_round"
