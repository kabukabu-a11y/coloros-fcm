#!/system/bin/sh
# ColorOS-FCM Action: full check -> fix -> post-verify, streaming report.
# Runs from the module card Action button.

export MODDIR="${MODDIR:-$(cd "$(dirname "$0")" && pwd)}"
. "$MODDIR/lib/core.sh" || exit 1

echo "ColorOS-FCM Guardian (shell-only)"
b_mode="${SHIZUKU_MODULE_MODE:-unknown}"
c_log "module=${SHIZUKU_MODULE_ID:-coloros_fcm} mode=$b_mode trusted=${SHIZUKU_MODULE_TRUSTED:-?}"

c_identity_guard || exit 1
c_log "uid OK · boot_count=$(c_boot_count) · 対象=$(c_load_targets | wc -l | tr -d ' ')件"

sh "$MODDIR/lib/check.sh" || exit 1

sh "$MODDIR/lib/fix.sh"; rc=$?

c_head "修復後チェック"
sh "$MODDIR/lib/check.sh" | grep -E 'JSON:|stopped=|\[x\]|\[!\]' || true

exit $rc
