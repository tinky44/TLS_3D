# Claude Code カスタムコマンド

このディレクトリは、tall_life_simulator プロジェクト専用の Claude Code カスタムコマンド（スキル）を管理します。

Claude Code のチャット欄で `/コマンド名` と入力することで呼び出せます。

---

## 利用可能なコマンド

### `/review-issues`

**ファイル:** [review-issues.md](review-issues.md)

GitHub の issue一覧とプロジェクトボードを取得し、現在のブランチや仕様メモと照らし合わせて
優先順位・アクション計画を提案します。

**使うタイミング:**
- 会話の冒頭で「今何をやるべきか」を整理したいとき
- issueを見ながら次のタスクを決めたいとき

**前提条件:**
- `gh` CLI がインストール済みで認証済みであること
- `read:project` スコープが付与されていること（`gh auth refresh -s read:project`）

---

## コマンドの追加方法

このディレクトリに `.md` ファイルを追加するだけで新しいコマンドが使えるようになります。

```
.claude/commands/
├── README.md          ← このファイル
├── review-issues.md   ← /review-issues
└── your-command.md    ← /your-command として呼び出せる
```

ファイルの中身はコマンド実行時に Claude へ渡されるプロンプトです。
手順・出力フォーマット・注意事項を自然言語で記述してください。
