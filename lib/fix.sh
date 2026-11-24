#!/system/bin/sh
# ColorOS-FCM fix: clear stopped flags, lift the ColorOS GMS restriction,
# add targets to the Doze whitelist, then wake the push chain.
# Every write is verified read-only afterwards where the platform allows.

export MODDIR="${MODDIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODDIR/lib/core.sh" || exit 1

c_identity_guard || exit 1

c_head "ColorOS-FCM 修復 (fix)"
_fixed=0

# 1) ColorOS GMS wakelock restriction
if [ "$(c_restric_info)" != "0" ]; then
    if c_restric_off && [ "$(c_restric_info)" = "0" ]; then
        echo "[o] google_restric_info を 0 にしました（制限オフ・確認済み）"
        _fixed=$((_fixed + 1))
    else
        echo "[x] google_restric_info の変更に失敗/未確認"
    fi
else
    echo "[o] google_restric_info=0（制限オフのまま）"
fi

# 2) per-target: unstop + Doze whitelist
for pkg in $(c_load_targets); do
    c_pkg_installed "$pkg" || continue
    if c_pkg_stopped "$pkg"; then
        if c_unstop "$pkg" && ! c_pkg_stopped "$pkg"; then
            echo "[o] $pkg : unstop 成功（確認済み）"
            _fixed=$((_fixed + 1))
        else
            echo "[x] $pkg : unstop 失敗/未確認"
        fi
    fi
    if ! c_whitelisted "$pkg"; then
        if c_whitelist_add "$pkg" && c_whitelisted "$pkg"; then
            echo "[o] $pkg : Doze ホワイトリストに追加（確認済み）"
            _fixed=$((_fixed + 1))
        else
            echo "[x] $pkg : ホワイトリスト追加に失敗/未確認"
        fi
    fi
done

# 3) wake the push chain if anything was wrong or GcmService is down
_need_hb=0
[ "$_fixed" -gt 0 ] && _need_hb=1
c_gcm_service_alive || _need_hb=1
if [ "$_need_hb" = "1" ]; then
    if c_heartbeat; then
        echo "[o] GCM ハートビート送信（result=0）"
    else
        echo "[!] GCM ハートビートの応答を確認できませんでした"
    fi
fi

echo "fix done: changes=$_fixed"
exit 0
