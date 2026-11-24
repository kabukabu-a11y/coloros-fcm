#!/system/bin/sh
# ColorOS-FCM check: read-only health report for GMS + targets.
# Prints a human report and a final one-line JSON, and persists both to
# state/ so the WebUI can show the latest state.

export MODDIR="${MODDIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODDIR/lib/core.sh" || exit 1

c_identity_guard || exit 1

mkdir -p "$STATE_DIR"

_j_targets=""
_j_first=1
_j_gms_stopped=false
_j_gcm_alive=false
_j_restric="$(c_restric_info)"

c_head "ColorOS-FCM 診断 (check)"
echo "boot_count=$(c_boot_count) · google_restric_info=$_j_restric （0=制限オフが正常）"
if [ "$_j_restric" != "0" ]; then
    echo "[!] ColorOS の GMS WakeLock 制限が有効です (google_restric_info=$_j_restric)"
fi

for pkg in $(c_load_targets); do
    if ! c_pkg_installed "$pkg"; then
        echo "[!] $pkg : 未インストール"
        _st="missing"; _wl="false"
    else
        if c_pkg_stopped "$pkg"; then
            echo "[x] $pkg : stopped=true（放送を受け取れません）"
            _st="true"
            [ "$pkg" = "$GMS" ] && _j_gms_stopped=true
        else
            echo "[o] $pkg : stopped=false"
            _st="false"
        fi
        if c_whitelisted "$pkg"; then
            _wl="true"
        else
            _wl="false"
            echo "    - Doze ホワイトリスト未登録"
        fi
    fi
    [ "$_j_first" = "1" ] || _j_targets="$_j_targets,"
    _j_first=0
    _j_targets="$_j_targets{\"pkg\":\"$pkg\",\"stopped\":$_st,\"whitelisted\":$_wl}"
done

if c_gcm_service_alive; then
    _j_gcm_alive=true
    echo "[o] GcmService : 稼働中"
else
    echo "[x] GcmService : 応答なし（プッシュ経路が落ちている可能性）"
fi

_json="{\"boot_count\":$(c_boot_count),\"restric_info\":\"$_j_restric\",\"gms_stopped\":$_j_gms_stopped,\"gcm_alive\":$_j_gcm_alive,\"targets\":[$_j_targets]}"
echo "JSON: $_json"
printf '%s\n' "$_json" > "$STATE_DIR/last-check.json"
