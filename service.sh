#!/system/bin/sh
# ColorOS-FCM Service: guarded one-shot recovery per Shizuku binder
# session, with a per-boot ledger. Intervenes at most once per package
# per boot so it never fights the system. Quiet by design: any failure
# exits 0 silently.
# Gate note: only runs in Full access + Allow background actions
# (or Full Trust); Safe mode blocks it by design.

export MODDIR="${MODDIR:-$(cd "$(dirname "$0")" && pwd)}"
. "$MODDIR/lib/core.sh" || exit 0

c_identity_guard || exit 0

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
BC="$(c_boot_count)"

if [ ! -f "$STATE_DIR/boot_count" ] || [ "$(cat "$STATE_DIR/boot_count" 2>/dev/null)" != "$BC" ]; then
    printf '%s' "$BC" > "$STATE_DIR/boot_count"
    rm -f "$STATE_DIR"/recovered_* "$STATE_DIR/restric_done" 2>/dev/null
    echo "[$(date '+%F %T')] new boot_count=$BC, ledger reset"
fi

FIXED=0

# ColorOS GMS wakelock restriction: lift once per boot.
if [ ! -f "$STATE_DIR/restric_done" ]; then
    if [ "$(c_restric_info)" != "0" ]; then
        if c_restric_off && [ "$(c_restric_info)" = "0" ]; then
            FIXED=$((FIXED + 1))
            echo "[$(date '+%F %T')] google_restric_info -> 0"
        fi
    fi
    : > "$STATE_DIR/restric_done"
fi

for pkg in $(c_load_targets); do
    [ -f "$STATE_DIR/recovered_$pkg" ] && continue
    if c_pkg_installed "$pkg"; then
        if c_pkg_stopped "$pkg"; then
            echo "[$(date '+%F %T')] $pkg stopped=true -> one-shot unstop"
            if c_unstop "$pkg" && ! c_pkg_stopped "$pkg"; then
                FIXED=$((FIXED + 1))
                echo "[$(date '+%F %T')] $pkg unstopped (verified)"
            else
                echo "[$(date '+%F %T')] $pkg unstop failed/unverified, giving up this boot"
            fi
        fi
        if ! c_whitelisted "$pkg"; then
            if c_whitelist_add "$pkg" && c_whitelisted "$pkg"; then
                FIXED=$((FIXED + 1))
                echo "[$(date '+%F %T')] $pkg added to Doze whitelist"
            fi
        fi
    fi
    # ledger regardless of outcome: one intervention per package per boot
    : > "$STATE_DIR/recovered_$pkg"
done

if [ "$FIXED" -gt 0 ]; then
    c_heartbeat >/dev/null 2>&1
    echo "[$(date '+%F %T')] heartbeat sent after recovery"
fi

echo "[$(date '+%F %T')] service done: fixed=$FIXED"

# refresh the persisted report so the WebUI reflects post-recovery state
sh "$MODDIR/lib/check.sh" >/dev/null 2>&1 || true
exit 0
