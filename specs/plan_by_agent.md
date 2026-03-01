# AI 検討メモ (plan_by_agent)

このファイルはAIがアイデアや実装計画、既存コードの分析結果を書き溜めるためのメモ帳です。

## grep_simulatorからGodotへの本格移植プラン

バグの多かったプロトタイプを破棄し、`grep_simulator`（TypeScript + Canvas実装）と同じ計算モデルと物理演算の精密さを持つGodotのプロジェクトとして作り直します。

### 1. スケール統一とシステム設計
- `grep_simulator` では `CM_TO_PX = 2.2` が使用されていた。
- Godotでも `1cm = 2px` などの倍率をグローバル変数（`GameManager` などのオートロード）で持つ。
- プレイヤーの物理身長や頭頂高さはすべて「1cm単位の現実のモデル」として計算し、Godotのワールド座標に乗算して描画・当たり判定を行う。

### 2. キャラクター（SkeletalPlayer）
- Godotの `Skeleton2D` ではなく、あえて「**_draw関数を使ったフルプロシージャル・スケルタルアニメーション**」をメインの実装とする。（Canvas版で完成されていた計算式をそのまま持ってくるのが最も確実で美しい）
- Node構成:
  - `CharacterBody2D` (`Player`)
    - `CollisionShape2D` (動的に高さを変える物理コリジョン)
    - `Node2D` (`CharacterDrawer`): 骨格を描画。`_draw()`でsin波と二分探索を用いたフルIKアニメーションを実行。
    - `RayCast2D`複数 (あるいは `ShapeCast2D`）を使用した前方の障害物検知用センサー群。

### 3. オブジェクトとステージの自動生成 (StageManager)
- 各ステージ（Room, Train, Outdoor, School）の定義は、GDScriptの辞書配列として移植。
- `Obstacle` 構造体を読み込み、ゲーム開始時に `StaticBody2D` と `CollisionShape2D`、そして簡単な描画用の `ColorRect` または `_draw()` でステージを動的生成する仕組みとする。
- 「overhead（頭上にぶつかる）」「background（背景のみ）」「ground（足元の障害物）」のタイプをきちんとGodotのCollisionMask（レイヤー）で区別する。
  - `overhead`: プレイヤーの頭側のセンサーや胴体と衝突する。
  - `ground`: プレイヤーの足元のセンサーや胴体と衝突する。
  - `background`: コリジョンなし（`Area2D`で監視し、コメント表示だけ行う）。

### 4. 自動かがみ（Auto-Crouch）と物理判定の再構築
- キャラクターの進行方向（例: +40cm）に向けて `ShapeCast2D` (キャラクターと同じサイズの四角形やカプセル) を「立ち状態」「屈み状態」の2レイヤーで飛ばし、安全に入れれば屈むなどのスマートな判定を実装。
- Canvas版と同じく、「もっとも低い障害物に合わせて `t` (0.0~2.0) を二分探索し、頭頂高さが障害物スレスレになるポーズを逆算」するロジックを GDScript に完全に移植する。

---

---

**→ 直近の実装作業手順：**

1. **[済] スケール係数やBodyモデルを持つプレーンなGDScriptを作成** (`Global.gd`)
2. **[進行中] プレイヤーのリファクタリング**: 
   - `SkeletalPlayer.gd` から描画ロジックを `CharacterDrawer.gd` (Node2D) へ分離。
   - 物理・入力・センサー管理を本体に残す。
3. **[済] `StageBuilder.gd` の実装**:
   - `grep_simulator` の `stages.ts` にあるデータを Godot の Dictionary または Resource 形式で定義。
   - `type: 'overhead'` は CollisionLayer 2 (頭上)
   - `type: 'ground'` は CollisionLayer 1 (足元)
   - `type: 'background'` は CollisionLayer なしの表示用。
4. **[済] メインシーン (`MainScene.gd`) の改修**:
   - `StageBuilder` を呼び出してステージを入れ替える機能。
   - UI（現在の身長やステージ名表示）の構築。

### 次のステップ: カメラ設定とコメント機能
- **Camera2Dの追従と拡大率**: 全体が見えるようにしていますが、本番では主人公を中心に置き、身長に合わせたスケールで表示したい。
- **背景オブジェクトとのインタラクション**: 各障害物に定義された `comment` を Godot 上の吹き出しUIで表示させる。

### ステージデータの移植用メモ
`grep_simulator` から取得したデータ構造：
- `id`: identifier
- `x`, `x2`: 範囲 (cm)
- `height`: 地面からの高さ (cm)
- `type`: 'overhead' | 'background' | 'ground'
- `comment`: 身長に応じたメッセージ（Godotでは `Callable` か辞書の文字列フォーマットで対応予定）
