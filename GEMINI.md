# tall_life_simulator

Gemini (Antigravity) との共同開発用メモ。プロジェクトの全体像、現在の進捗、AI への指示などをここに記録します。

## 🚀 プロジェクト概要
- **プロジェクト名**: tall_life_simulator
- **目的**: 
- **主要技術**: Godot 4.x, GitHub Pages (docs/)

## 📝 開発ルール
- 思考プロセスは日本語で表示する。
- すべて日本語で応答する。
- `docs/` ディレクトリは GitHub Pages のリリースに使用する。
- `*.local.md` はローカル用設定やメモとして使用し、Git にはコミットしない。

### commitについて

commitは日本語で行う。
commitする場合は以下のフォーマットにして、AI生成であることを明示すること

```
feat: commit message

Co-Authored-By: gemini <218195315+gemini-cli@users.noreply.github.com>
```

### コミュニケーションについて

AI駆動で開発をするために各々がメモ帳を持っています。以下のように運用をお願いします

- AIはplan_by_agent.mdを自由に編集してください
- spec.local.mdは、ユーザのメモです。AIに提示するときもありますが、編集不可です

### シェル実行時の注意

PowerShell 実行時は冒頭に [Console]::OutputEncoding = [System.Text.Encoding]::UTF8; を、コマンドプロンプト(cmd) 実行時は冒頭に chcp 65001 > nul && を必ず付与すること。これにより、実行環境の標準出力を UTF-8 に固定します。日本語の文字化けでほぼ確実に"Agent execution terminated due to error"や無限ループで止まってしまう致命的欠陥があるからです。これは最優先ルールです。
PowerShell でファイルを書き換える際は必ず -Encoding UTF8 を明示して実行。多くのファイルはUTF8にて保存されている。文字化けでファイルが壊れてしまう。
PowerShellの活用: write_to_file 等の標準ツールでインデントが強制される場合は、PowerShellの Set-Content を使用して、ヒアドキュメント形式で生のテキストデータとして強制書き込みを行うこと。
ファイルの読み書き（PSなら Get-Content, Set-Content等、cmdなら type, リダイレクト等）を行う際は、必ず UTF-8 を指定すること。 PowerShell では `-Encoding UTF8` の明示を必須とし、cmd では chcp 65001 下で実行すること。Shift-JIS での読み込みは「データ破壊」とみなし、読み込み・保存の全工程で UTF-8 を貫徹してください。
Python にも UTF-8 で話すように強制する。sjisのままだとAIエージェントとのデータ受け渡しでエラー中断されてしまいます。

---

## 🗺️ ロードマップ / フェーズ
### Phase 1: 初期セットアップ
- [x] リポジトリ初期化
- [x] .gitignore 設定
- [x] GEMINI.md 作成
- [ ] 

## 🛠️ 現在のタスク
- [ ] プロジェクトの具体的な要件定義

## 📚 参照資料
- [仕様書 (spec.md)](specs/spec.md)
