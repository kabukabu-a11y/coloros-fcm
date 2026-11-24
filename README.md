# ColorOS-FCM

**FCM push guardian for Chinese ColorOS** — a Shizuku / Shevery ADB module. Shell-only, no root: it runs as the ADB shell identity (uid 2000) and refuses any other uid.

Chinese ColorOS kills Google push through three main routes. This module guards all of them with a detect → fix → verify cycle:

1. **Stopped state** — an app marked "stopped" receives no broadcasts, and if GMS itself is stopped the whole FCM chain dies → cleared with `cmd package unstop`, then re-read to verify
2. **GMS wakelock restriction** — ColorOS blocks GMS from holding wakelocks via the secure setting `google_restric_info` → set to `0` (restriction off)
3. **Doze battery optimization** — GMS and the guarded apps are kept on the deviceidle whitelist

After a fix, a GCM heartbeat broadcast (MCS_HEARTBEAT) wakes the push chain.

## Requirements

- Shevery (or Shizuku-Next) activated via **wireless debugging / ADB** (does not run as root: uid 2000 is required)
- Module settings: **Access mode = Full access** and **Allow background actions** on (needed for the service.sh auto-guard; Safe mode blocks it by design)
- `unstop` needs Android 13+ (`cmd package`); ColorOS 16/17 qualify

## Installation

1. Download `dist/ColorOS-FCM-0.1.0.zip`
2. Shevery → Modules → Install from ZIP
3. Apply the Access mode settings above, then run the module card's Action once

## Usage

- **Action button** = check → fix → post-verify (results are shown in a dialog and saved to `state/last-check.json`)
- **WebUI** = shows the last saved state; on managers that provide a shell bridge, the re-check / fix buttons also work
- **Auto-guard (service.sh)**: once per Shizuku session, with a per-boot ledger — at most one intervention per package per boot, so it never fights the system
- **Command line** (from any Shizuku shell):

```
sh <MODDIR>/lib/check.sh            # read-only check (one-line JSON at the end)
sh <MODDIR>/lib/fix.sh              # unstop + lift restriction + whitelist + heartbeat
sh <MODDIR>/lib/watch.sh 90 15 4    # watch 90s / 15s interval / heartbeat every 4 rounds
sh <MODDIR>/lib/targets.sh list|add <pkg>|remove <pkg>|reset
sh <MODDIR>/lib/links.sh appdetails <pkg>|battery|bootid
```

Only GMS is guarded by default. Add apps such as Telegram with `targets.sh add org.telegram.messenger` (GMS is always guarded and cannot be removed).

## Limitations

- Within shell privileges this is a *guardian*: it repairs state after the system breaks it. It cannot hook and disable Hans freezing or `com.oplus.battery` behavior itself — that is what the Root + LSPosed **FCMFix ColorOS** does (preventive). This module is for devices without (or not wanting) root
- Writes are standard shell commands only, with a budget of 12 commands per fix run
- Problems where FCM servers themselves are unreachable (DNS pollution, blocked ports 5228–5230) are out of scope

## Layout

```
module.prop        # id=coloros_fcm
action.sh          # Action: check -> fix -> verify
service.sh         # per-session auto-guard (per-boot ledger)
lib/core.sh        # shared library: identity guard, probes, unstop, heartbeat, budget, ColorOS specifics
lib/check.sh       # read-only check -> human report + JSON (saved to state/)
lib/fix.sh         # fixes (each write verified read-only afterwards)
lib/watch.sh       # timed watch loop
lib/targets.sh     # guardian target list (config/targets.txt)
lib/links.sh       # settings deep links (app details / battery optimization)
webui/index.html   # offline single-file WebUI
config/targets.txt # extra guarded packages
```

## Credits

Module format and the "guardian" design follow Berry-FCM (a shell port of OriginOS FCM Guardian). This implementation is original code. MIT License.

---

# ColorOS-FCM（日本語）

**中国版 ColorOS 向け FCM プッシュ守護モジュール** —— Shizuku / Shevery の ADB モジュール形式。純 shell のみ、root 不要（ADB の shell uid 2000 で動作し、それ以外の uid は拒否）。

中国版 ColorOS が Google プッシュを止める経路は主に3つ。本モジュールはその全部を「検出 → 修復 → 再確認」で守る：

1. **stopped 化**：システムに「已停止」にされたアプリは放送を受け取れず、GMS 本体が stopped になると FCM 経路全体が死ぬ → `cmd package unstop` で解除し、書き込み後に再読して確認
2. **GMS WakeLock 制限**：ColorOS は secure 設定 `google_restric_info` で GMS の WakeLock 保持を阻む → `0` にして制限オフ（ColorOS 固有の既知設定）
3. **Doze の電池最適化**：GMS と対象アプリを deviceidle ホワイトリストに維持

修復時には GCM ハートビート放送（MCS_HEARTBEAT）でプッシュ経路を叩き起こす。

## 要件

- Shevery（または Shizuku-Next）を**無線デバッグ / ADB** で有効化（root では動かない：uid 2000 が前提）
- モジュール設定：**Access mode = Full access**、**Allow background actions** オン（service.sh の自動守護に必要。Safe モードでは設計上ブロックされる）
- `unstop` は Android 13+ の `cmd package` が必要（ColorOS 16/17 は充足）

## インストール

1. `dist/ColorOS-FCM-0.1.0.zip` をダウンロード
2. Shevery → Modules → Install from ZIP で入れる
3. 上記の Access mode 設定をして、モジュールカードの Action を一度実行

## 使い方

- **Action ボタン** = 診断 → 修復 → 再確認（結果はダイアログと `state/last-check.json` に保存）
- **WebUI** = 保存済み状態の表示。管理アプリがシェルブリッジを提供する場合は再チェック／一括修復ボタンも動く
- **自動守護（service.sh）**：Shizuku のセッションごとに、boot 単位の台帳で「各パッケージにつき1起動1回まで」の保守的な自愈。システムと競合しない設計
- **コマンドライン**（任意の Shizuku シェルから）：

```
sh <MODDIR>/lib/check.sh            # 読み取り専用診断（末尾に JSON）
sh <MODDIR>/lib/fix.sh              # unstop + 制限解除 + whitelist + ハートビート
sh <MODDIR>/lib/watch.sh 90 15 4    # 90秒監視 / 15秒間隔 / 4ラウンド毎にハートビート
sh <MODDIR>/lib/targets.sh list|add <pkg>|remove <pkg>|reset
sh <MODDIR>/lib/links.sh appdetails <pkg>|battery|bootid
```

対象は既定で GMS のみ。Telegram 等を守りたい場合は `targets.sh add org.telegram.messenger` のように追加する（GMS は常時対象で削除不可）。

## 限界

- shell 権限の範囲でできるのは「止められたら直す」守護まで。ColorOS の Hans 凍結や `com.oplus.battery` の挙動そのものをフックで無効化はできない。それができるのは Root + LSPosed の **FCMFix ColorOS**（予防型）。本モジュールは root を持たない／持ちたくない端末向けの対処
- 書き込みは標準 shell コマンドのみ、単回修復のコマンド予算は 12 本（超えたら止まる）
- FCM サーバー自体へ繋がらない問題（DNS 汚染、5228–5230 ポート封鎖など）は対象外

## 構成

```
module.prop        # id=coloros_fcm
action.sh          # Action: check → fix → 再確認
service.sh         # セッション毎の守護自愈（boot 台帳）
lib/core.sh        # 共有ライブラリ：身份ガード、探針、unstop、心拍、予算、ColorOS 固有処理
lib/check.sh       # 読み取り専用診断 → 人向け報告 + JSON（state/ に保存）
lib/fix.sh         # 修復（書き込み後は読み取りで確認）
lib/watch.sh       # 時間制限つき監視ループ
lib/targets.sh     # 守護対象の管理（config/targets.txt）
lib/links.sh       # 設定画面への深リンク（アプリ詳細 / 電池最適化）
webui/index.html   # オフライン単一ファイル WebUI
config/targets.txt # 追加の守護対象
```

## クレジット

モジュール形式と「守護」設計は Berry-FCM（OriginOS FCM Guardian の shell 移植）に倣った。コードは独自実装。MIT License。
