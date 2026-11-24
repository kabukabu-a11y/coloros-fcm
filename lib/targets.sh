#!/system/bin/sh
# ColorOS-FCM targets: manage the guardian target list.
# Usage: targets.sh list|add <pkg>|remove <pkg>|reset
# GMS is always guarded and is not stored in the file.

export MODDIR="${MODDIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODDIR/lib/core.sh" || exit 1

mkdir -p "$CONFIG_DIR"
[ -f "$TARGETS_FILE" ] || : > "$TARGETS_FILE"

case "${1:-list}" in
    list)
        c_load_targets
        ;;
    add)
        [ -n "${2:-}" ] || { echo "usage: targets.sh add <pkg>"; exit 1; }
        if [ "$2" = "$GMS" ]; then
            echo "$GMS は常時対象です（追加不要）"
            exit 0
        fi
        if grep -qx "$2" "$TARGETS_FILE"; then
            echo "$2 は登録済みです"
        else
            echo "$2" >> "$TARGETS_FILE"
            echo "$2 を追加しました"
        fi
        ;;
    remove)
        [ -n "${2:-}" ] || { echo "usage: targets.sh remove <pkg>"; exit 1; }
        if [ "$2" = "$GMS" ]; then
            echo "$GMS は対象から外せません"
            exit 1
        fi
        grep -vx "$2" "$TARGETS_FILE" > "$TARGETS_FILE.tmp" 2>/dev/null || : > "$TARGETS_FILE.tmp"
        mv "$TARGETS_FILE.tmp" "$TARGETS_FILE"
        echo "$2 を削除しました"
        ;;
    reset)
        : > "$TARGETS_FILE"
        echo "対象を GMS のみにリセットしました"
        ;;
    *)
        echo "usage: targets.sh list|add <pkg>|remove <pkg>|reset"
        exit 1
        ;;
esac
