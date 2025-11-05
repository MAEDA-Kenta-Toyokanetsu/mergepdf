# PDF Merge（Windows／バッチ配布版）

Windowsで「フォルダ内のPDFを名前順で結合」できる軽量ツールです。

* **ダブルクリック**：`merge.bat` と同じフォルダのPDFを結合 → `merged.pdf` を出力
* **ドラッグ＆ドロップ**：掴んでいるPDF（同一フォルダのみ）を結合 → その**同じフォルダ**に `merged.pdf` を出力
* 実行ログは毎回 `scripts/logs/merge_YYYYMMDD_HHMMSS.log` に保存（画面にも表示）

---

## フォルダ構成

```
pdfmerge/
├─ merge.bat
├─ README.md
└─ scripts/
   ├─ merge.py
   ├─ python0313/
   │  ├─ python.exe
   │  └─ python313._pth
   ├─ site-packages/
   │  └─ pypdf/, pypdf-5.x.y.dist-info/
   └─ logs/                  ← 自動生成。ログ保存先
```
---

## 使い方

### 1) ダブルクリックで結合

1. `merge.bat` を **結合したいPDFと同じフォルダ**に置く
2. `merge.bat` を **ダブルクリック**
3. 同フォルダ内のPDFが**名前の自然順**で結合され、`merged.pdf` が出力されます

### 2) ドラッグ＆ドロップで結合

1. 結合したいPDF（**同一フォルダ**に限る）を複数選択
2. `merge.bat` に**ドラッグ＆ドロップ**
3. PDFをドロップした**そのフォルダ**に `merged.pdf` が出力されます

> 実行ログは `scripts/logs/merge_YYYYMMDD_HHMMSS.log` に保存され、画面にも表示されます。

---

## 動作要件

* Windows 10/11
* 同梱の Python 3.13 embeddable（`scripts/python0313/python.exe`）
* `pypdf` 5.x（`scripts/site-packages/` に同梱）

---

## 内部仕様

* 並び順は **自然順**（例：`2` の前に `10` は来ない）

  * 結合順に`1`, `2`, `3`, ...とインデックスをつけることを推奨します。
* 出力ファイル名はデフォルトで `merged_YYYYMMDD_HHMMSS.pdf`
* `merged` から始まるpdfファイルは自動的に結合対象から除外
* 暗号化PDFはスキップ（ログに `[SKIP] encrypted` と出力）

---

## よくある質問（FAQ）

**Q1. 文字化けするログがある**
A. コンソールのフォントやコードページ依存の見た目だけです。`scripts/logs/*.log` を UTF-8 対応エディタで開けば正しく読めます。

**Q2. 何も結合されない／`merged.pdf` が出ない**

* `scripts/python0313/python.exe` と `scripts/merge.py` が存在するか
* `scripts/python0313/python313._pth` の設定（`import site` 有効化／末尾 `..\site-packages`）
* ドラッグ＆ドロップ時：**異なるフォルダのPDFを混在**させていないか
* フォルダに書き込み権限があるか（セキュリティソフトの隔離ログも確認）
* ログ（`scripts/logs/merge_*.log`）の最後にエラーが出ていないか

**Q3. 並び順を手動で変えたい**
A. ドラッグ＆ドロップで「結合したい順に」選んで落としてください。
（※既定は自然順。ドラッグ＆ドロップはファイル名順で結合されます）

**Q4. 出力先を変えたい**
A. ドラッグ＆ドロップでは**落としたPDFと同じフォルダ**、ダブルクリックでは **`merge.bat` と同じフォルダ**です。固定先を変えたい場合は `merge.bat` の `OUT` を編集してください。

---

## メンテナンス（任意）

* **ログの保管期間**を制御したい場合は、バッチ起動時に `forfiles` 等で古いファイルを削除してください。

---

## ライセンス

本ツール一式は社内配布を想定しています。外部公開する場合は別途[前田](maeda022@toyokanetsu.co.jp)までご相談ください。
同梱の `pypdf` は各依存ライセンスに従います。

---

## 付録：コマンドラインで直実行（デバッグ用）

```bat
REM フォルダ内をドライラン（順序のみ表示）
scripts\python0313\python.exe -X utf8 scripts\merge.py --dir "%CD%" --out "%CD%\merged.pdf" --dry-run

REM 実際に結合
scripts\python0313\python.exe -X utf8 scripts\merge.py --dir "%CD%" --out "%CD%\merged.pdf"
```
