# AI 検討メモ (plan_by_agent)

このファイルはAIがアイデアや実装計画、既存コードの分析結果を書き溜めるためのメモ帳です。

---

## 現在のステータス（2026-03-08）

- **完了済み**: 
  - 基盤システム、体の基本描画（横・正面・顔の向き対応）
  - 基本的なUI構築、ゲームフロー（タイトル→キャラクリ→メイン）
  - 自室ステージ・街・学校・駅などのステージ拡張と各ステージ間の双方向な移動アクション（シームレスな遷移基盤実装済み）
  - ESCメニューZ-orderバグ修正、ステータスオーバーレイ化、IntroScene導入
  - 比較対象となるNPCの実装・配置 (SkeletalNPC.tscn)
- **現在のフォーカス（未完了・着手予定）**: 
  - UI/オブジェクトのブラッシュアップ（自販機のリアル化、ステータスUIの改善など）
  - キャラクター描画の洗練（手の形状修正、ジョイントの改善）
  - ゲームフローの構築（学年ごとの身長・服装の変化システム）

---

## 次のステップ（Next Actions）

実装計画: 学校の廊下ステージの追加
ゴールと目的
現在の仕様では「学校＝教室」となっているため、学校の内部構造を広げる第一歩として「学校の廊下（school_hallway）」ステージを実装します。 これにより、屋外 → 廊下（昇降口） → 教室、という段階的な移動導線が確立され、将来的な「保健室（infirmary）」などの追加実装の基盤となります。 

変更前: 屋外(outdoor) ⇔ 教室(school)
変更後: 屋外(outdoor) ⇔ 廊下(school_hallway) ⇔ 教室(school)
変更の提案（Proporsed Changes）
廊下ステージの追加
[MODIFY] 

StageBuilder.gd
STAGES辞書の更新:
新規ステージ "school_hallway" を定義。
幅（width）: 2000〜2500cm 程度（長めの横移動）
天井高（ceiling_height）: 280cm（教室が300cm、少し低めの設定）
障害物:
door_to_outdoor（左端：昇降口/外への扉）
door_to_school（中央付近：教室への引き戸）
※将来的に右側に door_to_infirmary を追加予定。ロッカーや掲示板なども背景オブジェクト（background）として配置予定。
build_stageメソッドの更新:
elif stage_id == "school_hallway": ブロックを追加し、廊下らしい背景（壁紙のツートンカラー、等間隔の窓や柱の表現、掲示板など）をColorRectで描画する。
既存ステージ側のドア（obstacles）変更:
"outdoor" にある door_to_school を door_to_school_hallway にリネーム。
"school"（教室） にある door_to_outdoor を door_to_school_hallway にリネーム。
[MODIFY] 

MainScene.gd
ステージ遷移（_enter_transition_door）のロジックは、「door_to_XX」の名前から自動解決される仕組みが既にできているため、上記の名前変更だけで基本動作する想定です。
NPCの配置（_spawn_npcs）:
特定のNPC（たとえば先生や他学年の生徒など）を、教室だけでなく "school_hallway" にも配置する処理を追加。

---

## 将来的な展望・課題（Backlog）

- **アバターの精細化・デザイン追加**：関節の線引き（Line2D化）、服バリエーション、学年ごとのステージ等（コスト高のため一旦保留）。
- **両親の身長設定と遺伝コンテキストの導入**：「父親」「母親」の身長から主人公への遺伝的影響を決定づくシステム。
- **ローカルセーブ機能**：ゲーム進行状況のセーブ基盤の作成。

---

## 開発メモ

### 身体パラメータの計算式 (`Global.gd`)
- `head = height / ratio`
- `leg = height * legRatio / 100`
- `arm = height - leg - head - (neck * 2)`
- `armLength = head * 2.7`

### 屈みの二分探索 (`CharacterPoseCalculator.gd`)
目標の高さ（px）を満たす最小の `t` (ポーズパラメータ) を反復探索。
- `t` (0~1): 直立からかがみ（背中を丸める）
- `t` (1~2): 更に深く屈む（膝を曲げる）
