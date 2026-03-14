# plan_by_agent.md — AIエージェントのメモ帳

---

## アクション計画（2026-03-14）

---

## エンディングの作成

**`#49 エンディング実装` と紐づく。**

### 画面レイアウト

```
┌─────────────────────────────────────────┐
│  [成長記録テキスト]                       │
│  小学1年 120cm → 高校3年 185cm (+65cm)   │
│  平均より +25cm                           │
├──────────────┬──────────────────────────┤
│ 初期シルエット │    現在の主人公           │
│ (α=0.3)      │    (フルカラー)            │
│  +友人NPC     │                           │
│              │                           │
├──────────────┴──────────────────────────┤
│              [タイトルへ戻る]             │
└─────────────────────────────────────────┘
```

### シーン構成

```
EndingScene (Node2D)
├── CanvasLayer
│   ├── ColorRect         ← 黒背景
│   ├── VBoxContainer     ← 成長記録テキスト（上部）
│   ├── Label (subtitle)  ← 「--- おわり ---」等
│   └── Button            ← 「タイトルへ戻る」→ TitleScene.tscn
├── PlayerCurrent         ← SkeletalPlayer、右寄り配置
└── ComparisonGroup       ← Node2D、左寄り
    ├── PlayerInitial     ← SkeletalPlayer、modulate.a = 0.3
    └── PlayerNPC         ← SkeletalPlayer（ほのか等）、フルカラー
```

### 前提データの追加（Global.gd 改修）

**問題:** 初期外見（キャラメイク直後の状態）が保存されていない。現在の `current_appearance` はゲーム中に制服等で上書きされる。

**解決:** `Global.gd` に以下を追加し、新規ゲーム開始時に一度だけセット：

```gdscript
# Global.gd に追加
var initial_params: Dictionary = {}      # キャラメイク確定時の身長・頭身
var initial_appearance: Dictionary = {}  # キャラメイク確定時の外見

# 新規ゲーム開始時（CharacterCreatorScene の確定ボタン押下後）に呼ぶ
func lock_initial_state() -> void:
    initial_params = current_params.duplicate(true)
    initial_appearance = current_appearance.duplicate(true)
```

`save_slot()` / `load_slot()` にも `initial_params` / `initial_appearance` の保存・復元を追加。

**訪問ステージ・体験イベントのログ（思い出レポート用）**

`growth_history` は身長のみ、`term_memory_note` は毎学期リセット。
エンディングで「思い出」を表示するには以下を追加：

```gdscript
var visited_stages: Dictionary = {}    # {stage_id: true}
var experienced_events: Array = []     # ["semester_start", "summer_growth", ...]

func record_stage_visit(stage_id: String) -> void:
    visited_stages[stage_id] = true

func record_event(event_id: String) -> void:
    if not event_id in experienced_events:
        experienced_events.append(event_id)
```

記録タイミング:
- `visited_stages`: `MainScene.gd` のステージ遷移時（`_on_stage_changed()` 等）
- `experienced_events`: ダイアログ発火時（`_start_dialogue()` 内）

### EndingScene.gd の処理

```gdscript
func _ready() -> void:
    # 現在のキャラを右に配置
    setup_player(player_current, Global.current_params, Global.current_appearance)
    player_current.position = Vector2(viewport_w * 0.65, floor_y)

    # 初期シルエットを左に配置（initial_params が空なら growth_history[0] で代用）
    var init_p = Global.initial_params if not Global.initial_params.is_empty() \
                 else _params_from_history(Global.growth_history[0])
    setup_player(player_initial, init_p, Global.initial_appearance)
    player_initial.position = Vector2(viewport_w * 0.2, floor_y)
    player_initial.modulate.a = 0.3

    # NPC（ほのか）を左中央に配置
    setup_player(player_npc, NPC_PROFILES["honoka"], NPC_PROFILES["honoka"]["appearance"])
    player_npc.position = Vector2(viewport_w * 0.35, floor_y)

    # 成長記録テキスト
    _build_growth_text()

func _build_growth_text() -> void:
    var h0 = growth_history[0]["height"]
    var h1 = Global.current_params["height"]
    var avg = Global.get_avg_height(Global.age)
    label_record.text = (
        "%.0fcm → %.0fcm（+%.0fcm）\n平均より %+.0fcm" % [h0, h1, h1 - h0, h1 - avg]
    )
```

### NPC プロフィール定数（Global.gd に追加）

```gdscript
const NPC_PROFILES = {
    "honoka": {
        "params": {"height": 160.0, "ratio": 7.0, "legRatio": 48.0, "sex": "female"},
        "appearance": {"hair_style": "long", "hair_color": "#5c3a1e",
                       "tops_type": "t_shirt", "tops_color": "#f0e0d0", ...}
    }
}
```

### 遷移元

`MainScene.gd` の進級選択ダイアログで「エンディングへ」を選択したとき：
```gdscript
get_tree().change_scene_to_file("res://scenes/EndingScene.tscn")
```

---

## イントロダクションの見直し

### 現状

`IntroScene.tscn` は root の `Control` ノードだけで、子ノードはなし。`IntroScene.gd` が
`ColorRect`（黒背景）と `Label`（「おはよう」）を動的生成し、Tween でフェードしてから
`get_tree().change_scene_to_file("res://Main.tscn")` へ遷移する。カメラ・キャラ描画はなし。

### 採用演出：身長計ズームアウト

```
[起動直後] 身長計の目盛りがドアップ（zoom=4） → キャラがフェードイン →
[Tween 2s] zoom が 1.0 まで引く → 身長計の前にキャラが立っている全体像 →
[テキスト] 「〇〇歳、身長〇〇cm。――ここから私の生活が始まる。」→
[暗転] → Main.tscn へ遷移
```

### シーン構成変更

`IntroScene.tscn` の root を **`Node2D`** に変更し、以下を追加：

```
IntroScene (Node2D)   ← root を Control → Node2D に変更
├── Camera2D           ← zoom アニメ用。初期 zoom = Vector2(4, 4)
├── HeightChart        ← Node2D、_draw() で目盛りを描画
├── SkeletalPlayer     ← res://scenes/SkeletalPlayer.tscn をインスタンス化
└── CanvasLayer        ← カメラに影響されない UI 層
    ├── ColorRect      ← 黒背景フェード用（α アニメ）
    └── Label          ← テキスト表示
```

### IntroScene.gd の処理フロー

```gdscript
func _ready() -> void:
    # Camera2D: zoom=(4,4)、キャラの頭上あたりを初期注視点に
    camera.zoom = Vector2(4, 4)
    var h = Global.current_params["height"]
    camera.position.y = -(h * Global.CM_TO_PX)  # 頭部の高さ

    # SkeletalPlayer: Global から外見を読み込む
    player.call_deferred("update_measurements")
    player.modulate.a = 0.0  # 最初は非表示

    # 0.5s 後にキャラをフェードイン、その後 zoom アウト開始
    await get_tree().create_timer(0.5).timeout
    _tween_alpha(player, 0.0, 1.0, 0.6)
    await get_tree().create_timer(0.6).timeout
    _tween_zoom(Vector2(4,4), Vector2(1,1), 2.0)
    await get_tree().create_timer(2.0).timeout

    # テキスト表示
    var age = Global.age
    var cm = snappedf(h, 0.1)
    label.text = "%d歳、身長%.1fcm。\n――ここから私の生活が始まる。" % [age, cm]
    _tween_alpha(label, 0.0, 1.0, 0.5)
    await get_tree().create_timer(2.5).timeout
    _tween_alpha(label, 1.0, 0.0, 0.5)

    # 暗転して遷移
    _tween_alpha(bg_rect, 0.0, 1.0, 0.5)
    await get_tree().create_timer(0.5).timeout
    get_tree().change_scene_to_file("res://Main.tscn")
```

### HeightChart（目盛り描画）

```gdscript
extends Node2D
# _draw() で 100cm〜220cm の目盛りを描画
func _draw() -> void:
    var p = Global.CM_TO_PX      # ≈ 2.0 px/cm
    var h_now = Global.current_params["height"]
    for cm in range(100, 230, 10):
        var y = -(cm * p)
        var is_major = cm % 50 == 0
        var line_len = 30.0 if is_major else 15.0
        draw_line(Vector2(-line_len, y), Vector2(0, y), Color.WHITE, 1.5)
        if is_major or cm % 20 == 0:
            draw_string(font, Vector2(-line_len - 40, y + 5), "%dcm" % cm, ...)
    # キャラの現在身長マーカーを強調（黄色）
    var mark_y = -(h_now * p)
    draw_line(Vector2(-40, mark_y), Vector2(0, mark_y), Color.YELLOW, 2.5)
```

### 注意点

- `SkeletalPlayer` は `CharacterCreatorScene` のあとに呼ばれるため `Global.current_appearance` と `Global.current_params` は確定済み
- `CM_TO_PX` は `Global.gd` のシングルトンで一元管理（`SkeletalPlayer` 経由でなく直接参照）
- スコープ外（今回は実装しない）: キャラが歩く動的演出、作品説明テキスト画面

---

## 受動的ストーリーの追加

**現状の問題**
- 保健室で身長を測る（能動的アクション）でしか学期が進まない
- `advance_term()` は `MainScene.gd:2286` で呼ばれており接続済み

**設計方針**

### B. 授業イベント（教室での時間スキップ）
- 教室ステージに入る → 既存の `semester_start` ダイアログ
- ダイアログ後: 「授業が始まった。」→ 暗転（0.5s）→ 「放課後。」テキスト → 家ステージへ自動遷移
- `StageBuilder.is_school_classroom_stage()` がすでにあるので条件分岐はそれを流用

### C. NPC自動声かけ（身長依存）

| 条件 | NPCの反応例 |
|---|---|
| 身長 ≥ 170cm（中学生〜） | 「背が高いね！」「バスケ部来てよ〜」（ポジティブ） |
| 身長 ≥ 180cm | 「上の棚取ってもらえる？」「モデルみたい！」（ユーモラス） |
| 身長 ≥ 190cm | 子どもNPCが「すごい！○○cm！？」と駆け寄ってくる |
| 特定ステージ初訪問 | ステージ固有のNPC一言（驚き・感心・無遠慮） |

**ブランチ候補:** `feat/passive-story`

---

## 会話イベントのトーン改善

**現状:** ネガティブな反応（「しんどい」「つらい」）が大半

**改善方針**
- `DialogueDatabase.gd` にポジティブ・ユーモラス・中立バリエーションを追加
- 目標比率: ネガティブ3 : 中立4 : ポジティブ3

**台詞例（追加候補）**
- ポジティブ: 「モデルさんみたい！」「バスケ向いてそう」「高いところ楽そうだね」
- ユーモラス: 「天井に頭ぶつけないの？」「棚の上何がある？」「ドア通れる？」
- 受動的声かけ（NPC側から）: 「ちょっと〜！写真撮っていい？」「え、何年生？」

**ブランチ候補:** `feat/npc-dialogue-balance`

---

## 身体と環境の干渉表現

**実装候補**
- **椅子に座る**: 椅子オブジェクトへのインタラクション追加、「脚が机に収まらない」「体育座りがきつい」などのテキスト
- **NPC自動声かけ**: 受動的ストーリーの「C. NPC自動声かけ」と統合
- **後回し**: ドア・天井・電車との接触シーン

**ブランチ候補:** `feat/body-environment-interaction`

---

## バグ修正

| # | 内容 | 場所（コード調査済み） | 修正方針 | 優先 |
|---|---|---|---|---|
| B-1 | 駅→電車のつながりが不自然 | `StageBuilder.gd` ステージ遷移定義 | 駅→電車の遷移ロジックを確認・整理 | ★★☆ |
| B-2 | 屋外に家のドアが出る | `StageBuilder.gd` ドア配置ロジック | 屋外判定フラグを追加してドアを非表示 | ★★☆ |
| B-3 | 吹き出しが顔に被る | `MainScene.gd:1091` `_get_bubble_screen_pos()` | 下記参照 | ★★★ |

**B-3 詳細（コード調査済み）**

現在の計算: `offset_y = player.visual_height_cm * p + 80`

問題: 高身長時に `visual_height_cm * p` が画面上の頭位置と合っておらず、吹き出しが頭部と重なる。

修正方針:
- `offset_y` の固定オフセット `80` を `bubble_panel.size.y + 20` など吹き出しサイズ依存に変更し、頭の上に確実に出るようにする
- または `SkeletalPlayer` に `get_head_screen_y_offset()` を追加して実際の頭部Y座標を返す方式に変更

---

## 優先順位まとめ

| 優先 | タスク | 規模 | ブランチ |
|---|---|---|---|
| ★★★ | B-3 吹き出しが顔に被る | 小 | `fix/bubble-position` |
| ★★☆ | Global.gd: initial_state / visited_stages / experienced_events 追加 | 小 | エンディングの前提 |
| ★★☆ | B-1 駅→電車の遷移が不自然 | 小〜中 | `fix/stage-transition` |
| ★★☆ | B-2 屋外に家のドアが出る | 小 | `fix/stage-door` |
| ★★☆ | #47 進級選択ダイアログ | 中 | `feat/grade-select-dialog` |
| ★★☆ | 受動的ストーリー（授業暗転・NPC自動声かけ） | 中 | `feat/passive-story` |
| ★★☆ | 会話トーン改善（ポジティブ台詞追加） | 中 | `feat/npc-dialogue-balance` |
| ★★☆ | 椅子・干渉表現 | 中 | `feat/body-environment-interaction` |
| ★☆☆ | イントロ見直し（身長計ズームアウト） | 中 | `feat/intro-revamp` |
| ★☆☆ | エンディング（最終比較画面） | 大 | `feat/ending-report` |

## レビュー結果

High: エンディングの初期シルエット復元案は、そのままだと正確に実装できません。plan_by_agent.md:93 plan_by_agent.md:95 では growth_history[0] を代用に使っていますが、現行の保存内容は Global.gd:198 Global.gd:204 の通り height と平均差分系だけで、ratio / legRatio / 外見が入っていません。初期体型を並べたいなら initial_params と initial_appearance を必須保存に寄せた方が安全です。
High: NPC プロフィールの使用例が定義と食い違っています。plan_by_agent.md:101 では setup_player(player_npc, NPC_PROFILES["honoka"], ...) になっていますが、定義は plan_by_agent.md:121 のように params 配下へ体型値を入れる形です。このままだと呼び出し側が params ではなくプロファイル全体を渡すことになります。
Medium: Intro のプレイヤー scene パスが現行 repo にありません。plan_by_agent.md:162 は res://scenes/SkeletalPlayer.tscn を前提にしていますが、今ある再利用 scene は Player.tscn:1 で、スクリプトも Player.tscn:3 にぶら下がっています。新規 scene を作る前提なら、その作成タスクを計画に明記した方がよいです。
Medium: visited_stages の記録フック名が現行コードとズレています。plan_by_agent.md:82 では _on_stage_changed() を例示していますが、今の実装でステージ切替の中心になっているのは _load_stage() / MainScene.gd:1815 です。実装者がそのまま追うと存在しないフックを探すことになります。
Medium: 学校の強制イベントの遷移先が最新実装と食い違っています。plan_by_agent.md:240 では「家ステージへ自動遷移」ですが、現行コードは MainScene.gd:1137 で school_hallway にしています。ここは計画書を最新化しておいた方が後続作業で迷いません。