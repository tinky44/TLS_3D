# GitHub Issueレビューとアクション計画

このコマンドは、tall_life_simulator の GitHub issueとプロジェクトボードを取得し、
現在のブランチや仕様メモと照らし合わせて優先順位とアクション計画を提案します。

## 手順

1. リモートリポジトリと現在のブランチを確認する
```bash
git remote -v
git branch --show-current
```

2. issueをJSON形式で取得する（tinky44/tall_life_simulator）
```bash
gh issue list --repo tinky44/tall_life_simulator --state open --json number,title,labels,assignees,body,milestone,state --limit 50
```

3. GitHubプロジェクト一覧とアイテムを取得する（read:projectスコープが必要）
```bash
gh project list --owner tinky44
gh project item-list 1 --owner tinky44 --format json
```
※ スコープエラーが出た場合は `gh auth refresh -s read:project` を案内する

4. 取得したissue一覧とプロジェクトステータスを突合して整理する：
   - **テーブル形式**でissueを一覧表示（番号・タイトル・プロジェクトステータス・ラベル）
   - **プロジェクト未登録のissue**を識別して報告する
   - **優先順位の提案**：現在のブランチ名・specs/spec.local.mdのメモ・issueの内容から判断
   - **今すぐ着手できるissue**を1〜3件ピックアップ
   - **大規模・後回し推奨のissue**も識別する

5. specs/spec.local.md を参照してユーザのメモと突合する

## 出力フォーマット

```
## オープンissue一覧
| # | タイトル | プロジェクト | ラベル |
|---|---|---|---|
...

## 今後のアクション提案
### 今すぐ着手（現ブランチ・直近タスク）
- #XX ...

### 次フェーズ
- #XX ...

### 大規模・要設計
- #XX ...
```

## 注意事項
- `read:project` スコープが必要な場合は `gh auth refresh -s read:project` を案内する
- wontfixラベルのissueは一覧に含めるが優先度リストからは除外する
- issueの内容が空のものは「要確認」として記載する
