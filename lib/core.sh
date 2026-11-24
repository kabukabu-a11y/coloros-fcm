# ColorOS-FCM shared library. Sourced by action.sh / service.sh / lib/*.sh.
# Shell-only (uid 2000 via Shizuku/Shevery). No root, no binaries, no reflection.
# Every write is a standard shell command and is counted against FIX_BUDGET.

GMS="com.google.android.gms"
STATE_DIR="$MODDIR/state"
CONFIG_DIR="$MODDIR/config"
TARGETS_FILE="$CONFIG_DIR/targets.txt"
FIX_BUDGET=12
_BUDGET_LEFT=$FIX_BUDGET

c_log() { echo "[coloros-fcm] $*"; }

c_head() { echo ""; echo "== $* =="; }

# Only the adb shell identity (uid 2000) is accepted, mirroring the
# Shizuku module contract: root or app uids are refused.
c_identity_guard() {
    _uid="$(id -u 2>/dev/null)"
    if [ "$_uid" != "2000" ]; then
        echo "[x] uid=$_uid : Shizuku(ADB) 経由の shell uid 2000 で実行してください"
        return 1
    fi
    return 0
}

c_boot_count() {
    _bc="$(settings get global boot_count 2>/dev/null)"
    case "$_bc" in ''|null) echo 0 ;; *) echo "$_bc" ;; esac
}

# Targets = GMS (fixed, always first) + user list in config/targets.txt.
c_load_targets() {
    echo "$GMS"
    if [ -f "$TARGETS_FILE" ]; then
        while IFS= read -r _line; do
            case "$_line" in ''|'#'*) continue ;; esac
            [ "$_line" = "$GMS" ] && continue
            echo "$_line"
        done < "$TARGETS_FILE"
    fi
}

c_pkg_installed() {
    cmd package path "$1" >/dev/null 2>&1
}

# stopped=true in the "User 0:" line of dumpsys package.
c_pkg_stopped() {
    dumpsys -t 3 package "$1" 2>/dev/null | grep -m 1 'User 0:' | grep -q 'stopped=true'
}

c_unstop_supported() {
    cmd package help 2>/dev/null | grep -q 'unstop'
}

c_spend() {
    if [ "$_BUDGET_LEFT" -le 0 ]; then
        echo "[!] コマンド予算($FIX_BUDGET)を使い切りました。以降の書き込みはしません"
        return 1
    fi
    _BUDGET_LEFT=$((_BUDGET_LEFT - 1))
    return 0
}

c_unstop() {
    c_unstop_supported || return 1
    c_spend || return 1
    cmd package unstop --user 0 "$1" >/dev/null 2>&1
}

# GCM heartbeat: MCS_HEARTBEAT broadcast to GMS, success = "result=0".
c_heartbeat() {
    _ok=1
    _i=1
    while [ "$_i" -le 3 ]; do
        _out="$(am broadcast -a com.google.android.intent.action.MCS_HEARTBEAT -p "$GMS" 2>/dev/null)"
        case "$_out" in *'result=0'*) _ok=0; break ;; esac
        _i=$((_i + 1))
        sleep 1
    done
    # second documented wake action; failure is not fatal
    am broadcast -a com.google.android.intent.action.ACTION_HEARTBEAT_NOW -p "$GMS" >/dev/null 2>&1
    return $_ok
}

c_gcm_service_alive() {
    dumpsys -t 2 activity services "$GMS" 2>/dev/null | grep -q 'GcmService'
}

# --- ColorOS specific -------------------------------------------------

# ColorOS restricts GMS wakelocks while secure setting google_restric_info
# is unset/1. "0" means the restriction is off.
c_restric_info() {
    _v="$(settings get secure google_restric_info 2>/dev/null)"
    case "$_v" in ''|null) echo "null" ;; *) echo "$_v" ;; esac
}

c_restric_off() {
    c_spend || return 1
    settings put secure google_restric_info 0 >/dev/null 2>&1
}

# Doze whitelist (deviceidle). dumpsys prints one package per line.
c_whitelisted() {
    dumpsys deviceidle whitelist 2>/dev/null | grep -qx "$1"
}

c_whitelist_add() {
    c_spend || return 1
    cmd deviceidle whitelist "+$1" >/dev/null 2>&1
}
