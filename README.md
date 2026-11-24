# ColorOS-FCM

**ColorOS（国行）向け FCM プッシュ守護モジュール** —— Shizuku / Shevery の ADB モジュール形式。純 shell のみ、root 不要（shell uid 2000 で動作し、それ以外の uid は拒否）。

中国版 ColorOS が Google プッシュを止める経路は主に3つ。本モジュールはその全部を「検出 → 修復 → 再確認」で守る：

1. **stopped 化**：システムに「已停止」にされたアプリは放送を受け取れず、GMS 本体が stopped になると FCM 経路全体が死ぬ → `cmd package unstop` で解除し、書き込み後に再読して確認
2. **GMS WakeLock 制限**：ColorOS は secure 設定 `google_restric_info` で GMS の WakeLock 保持を阻む → `0` にして制限オフ（既知の ColorOS 固有設定）
3. **Doze の電池最適化**：GMS と対象アプリを deviceidle ホワイトリストに維持

加えて、修復時には GCM ハートビート放送（MCS_HEARTBEAT）でプッシュ経路を叩き起こす。

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
- **WebUI** = 保存済み状態の表示（4つの状態ランプ＋対象一覧）。管理アプリがシェルブリッジを提供する場合は再チェック／一括修復ボタンも動く
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

## 限界（正直なところ）

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
