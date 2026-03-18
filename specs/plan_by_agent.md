# 成長システム改善 設計書

更新日: 2026-03-18

---

## 概要

学期ごとの「自動成長」を廃止し、ストーリー主導の成長体験に刷新する。

**「実際の成長」と「記録上の身長」を分離する：**

| 変数 | 意味 | 使用箇所 |
|---|---|---|
| `Global.height` | 実際の体の高さ。成長イベントで即時更新 | キャラクター描画（人形のサイズ） |
| `Global.recorded_height` | 最後に保健室で「測定した」値 | 成長グラフ・ステータス画面の数値表示 |

- 人形は成長するとリアルタイムで大きくなる
- グラフや数値 UI は測定するまで古い値（`recorded_height`）のまま
- 測定完了で `recorded_height = height` に更新し、`growth_history` に記録される

また、成長ポイントを溜める手段として3つの特別イベントを追加する。

---

## 1. 学期成長フローの刷新

### 現状
- `advance_term()` 内で身長増加が自動計算・即時反映される

### 新フロー

```
学期開始（advance_term）
  ↓
height += calc_growth(...)  ← 人形には即時反映（キャラクターが大きくなる）
recorded_height は更新しない（グラフ・数値は古いまま）
  ↓
学校ステージの廊下ではるかに近づく
  ↓
はるかが声をかける（廊下ホットスポット）
  ↓
強制的に保健室にワープ（_load_stage("infirmary")）
  ↓
身長計に近づくと測定ダイアログ
  ↓
測定完了 → recorded_height = height → growth_history に記録
```

### 実装方針

#### Global.gd の変更

```gdscript
# 追加変数
var recorded_height: float = 0.0       # 最後に測定した身長（グラフ・UI表示用）
var height_measured_this_term: bool = false  # 今学期すでに測定したか

# advance_term() 内の変更
# 旧: height += calc_growth(...)  ← recorded_height も同時更新していた
# 新: height += calc_growth(...)  ← 人形には即時反映
#     # recorded_height は変えない（測定まで古い値を保持）
#     height_measured_this_term = false

# recorded_height の初期化（CharacterCreator でキャラ作成時）
recorded_height = height
```

#### MainScene.gd の変更

**廊下ホットスポット追加**

```gdscript
# school_hallway ステージのホットスポットに追加
{
    "id":           "haruka_hallway",
    "stage_id":     "school_hallway",   # 各学校の廊下ステージ
    "obs_id":       "haruka_npc",        # はるかのNPC位置
    "trigger_radius": 80.0,
    "one_shot":     false,               # 毎学期発動
    "condition":    "_should_trigger_haruka_measurement",
}
```

**条件判定関数**

```gdscript
func _should_trigger_haruka_measurement() -> bool:
    var g = _global()
    return g and g.height > g.recorded_height and not g.height_measured_this_term
```

**ホットスポット発火時の処理**

```gdscript
func _on_haruka_hallway_triggered() -> void:
    # はるかとの会話
    _start_dialogue("haruka_height_check")
    # 会話終了後に保健室へワープ
    await dialogue_finished
    _load_stage("infirmary")
```

**保健室の身長計インタラクト**

```gdscript
# 既存の "height_scale" ホットスポットを拡張
func _on_height_scale_interact() -> void:
    var g = _global()
    var unmeasured: bool = g.height > g.recorded_height and not g.height_measured_this_term
    if unmeasured:
        _start_dialogue("measurement_in_progress")
        await dialogue_finished
        # 記録を実際の身長に合わせる（人形のサイズは既に更新済み）
        var prev_h: float = g.recorded_height
        g.recorded_height = g.height
        g.record_growth_history()   # growth_history に recorded_height を記録
        g.height_measured_this_term = true
        _start_dialogue_dynamic(_build_measurement_result_dialogue(prev_h, g.height))
    else:
        _start_dialogue("term_school_infirmary")  # 通常の保健室ダイアログ
```

---

## 2. 成長イベント発生時の朝演出

### トリガー条件

`height > recorded_height`（未測定の成長がある）状態で「就寝 → 起床」が発生したとき。

### 演出フロー

```
就寝フェードアウト（黒）
  ↓
黒背景のまま（ColorRect alpha=1 維持）
  ↓
通常と同じ画面下部ダイアログで表示：
  「ミシミシ……ミシミシ……膝が音を立てている」
  ↓ 決定キー
フェードイン → 翌朝（myroom）
```

### 実装箇所: `_run_sleep_transition()` の拡張

```gdscript
func _run_sleep_transition(hours_passed: int) -> void:
    # ... 既存フェードアウト処理 ...

    var g = _global()
    if g and g.height > g.recorded_height:
        # 黒背景のまましばらく待機
        await get_tree().create_timer(0.4).timeout
        _start_dialogue("growing_pain_sleep")   # 膝がミシミシ
        await dialogue_finished

    # ... 既存フェードイン・翌朝処理 ...
```

### ダイアログキー `"growing_pain_sleep"`

```gdscript
"growing_pain_sleep": [
    {"speaker": "", "text": "ミシミシ……ミシミシ……"},
    {"speaker": "", "text": "膝が音を立てている。"},
    {"speaker": "主人公（心の声）", "text": "……また、伸びてるのかな。"},
]
```

---

## 3. 特別成長イベント

### ① 牛乳がぶ飲みイベント（無限成長）

**トリガー**: `myroom` ステージの `refrigerator` をインタラクト

**効果**: 1回あたり `height += 1.0`（人形が即時に大きくなる。`recorded_height` は変えない）

**制限**: なし（AP消費なし、時間経過なし）

**実装**

`MainScene.gd` の `refrigerator` ホットスポット処理に追加:

```gdscript
func _on_refrigerator_interact() -> void:
    _start_dialogue("refrigerator_milk")
    await dialogue_finished
    var g = _global()
    if g:
        g.height += 1.0   # 人形に即時反映。recorded_height は変えない
```

**ダイアログキー `"refrigerator_milk"`**

```gdscript
"refrigerator_milk": [
    {"speaker": "主人公", "text": "冷蔵庫を開けると、牛乳がある。"},
    {"speaker": "主人公", "text": "……ぐびぐびぐび。"},
    {"speaker": "主人公（心の声）", "text": "（また伸びる気がする）"},
]
```

---

### ② 突発的・成長期睡眠イベント（ポイントブースト）

**トリガー**: 時間経過アクションのたびに一定確率（15%）で発火。学校外出先でも発生。

**効果**: 強烈な眠気ダイアログ → 「帰って寝る」選択 → フェードアウト → 翌朝。
通常よりも多く `height` が増加する（`calc_growth` の通常成長量 × 0.5 を追加加算）。

**実装**

`MainScene.gd` の時間経過処理内に確率判定を追加:

```gdscript
const GROWTH_SLEEP_CHANCE := 0.15

func _after_action() -> void:
    # ... 既存処理 ...
    if randf() < GROWTH_SLEEP_CHANCE:
        _trigger_growth_sleep_event()

func _trigger_growth_sleep_event() -> void:
    _start_dialogue("growth_sleep_warning")
    # 選択肢: ["今すぐ帰って寝る", "もう少し頑張る"]
    # → 「帰って寝る」選択時: _load_stage("myroom") → _run_sleep_transition(boost=true)
```

**`_run_sleep_transition` にブーストフラグ追加**

```gdscript
func _run_sleep_transition(hours_passed: int, boost: bool = false) -> void:
    var g = _global()
    if g and boost:
        var extra = g.calc_growth(int(g.age)) * 0.5
        g.height += extra   # 人形に即時反映。recorded_height は変えない
    # ... 残り既存処理 ...
```

**ダイアログキー `"growth_sleep_warning"`**

```gdscript
"growth_sleep_warning": [
    {"speaker": "主人公（心の声）", "text": "……急に、どっと眠気が来た。"},
    {"speaker": "主人公（心の声）", "text": "体が重い。目が開かない。"},
    # 選択肢
    {"speaker": "__choice__", "choices": ["今すぐ帰って寝る", "もう少し頑張る"]},
]
```

---

### ③ 怪しい成長サプリイベント（ガチャ要素）

**トリガー**: `station_vending` または `school` ステージ内の `vending_machine` をインタラクトした際、確率 7% で出現。

**効果**: 飲むと `height += 10.0`（人形が即時に急成長。`recorded_height` は変えない）。
翌朝の「ミシミシ」演出は通常より激しいバリアントを使用。

**実装**

`MainScene.gd` のベンダーインタラクト処理に追加:

```gdscript
const GROWTH_SUPP_CHANCE := 0.07

func _on_vending_interact(vending_id: String) -> void:
    if randf() < GROWTH_SUPP_CHANCE:
        _trigger_growth_supplement()
    else:
        _start_dialogue("term_station_vending")  # 通常

func _trigger_growth_supplement() -> void:
    _start_dialogue("growth_supplement_found")
    await dialogue_finished
    var g = _global()
    if g:
        g.height += 10.0   # 人形に即時反映。recorded_height は変えない
        # 激しい演出フラグ
        g.set_meta("growth_pain_intense", true)
```

**`_run_sleep_transition` での激しい演出分岐**

```gdscript
if g.has_meta("growth_pain_intense") and g.get_meta("growth_pain_intense"):
    _start_dialogue("growing_pain_sleep_intense")
    g.set_meta("growth_pain_intense", false)
else:
    _start_dialogue("growing_pain_sleep")
```

**ダイアログキー `"growth_supplement_found"`**

```gdscript
"growth_supplement_found": [
    {"speaker": "主人公", "text": "自動販売機の取り出し口に、何かある……"},
    {"speaker": "主人公", "text": "『怪しい成長サプリ』？"},
    {"speaker": "主人公（心の声）", "text": "……飲むか？"},
    {"speaker": "__choice__", "choices": ["飲む", "捨てる"]},
]
```

**ダイアログキー `"growing_pain_sleep_intense"`**

```gdscript
"growing_pain_sleep_intense": [
    {"speaker": "", "text": "ミシミシ……ミシミシ……"},
    {"speaker": "", "text": "ガキッ……ガキッ……"},
    {"speaker": "主人公（心の声）", "text": "骨が……割れるような音がする……！"},
    {"speaker": "主人公（心の声）", "text": "いたい……いたい……"},
]
```

---

## 4. はるかとのダイアログ

**キー `"haruka_height_check"`**

```gdscript
"haruka_height_check": [
    {"speaker": "はるか", "text": "あ、ちょっと待って！"},
    {"speaker": "はるか", "text": "なんか……また背、伸びてない？"},
    {"speaker": "主人公", "text": "……そう、かな。"},
    {"speaker": "はるか", "text": "絶対伸びてるって！ちょっと保健室行こ、測ってもらおう！"},
]
```

**キー `"measurement_in_progress"`**

```gdscript
"measurement_in_progress": [
    {"speaker": "養護教諭", "text": "はいはい、じゃあ靴を脱いで身長計に乗って。"},
    {"speaker": "養護教諭", "text": "……はい、そこで止まって。"},
]
```

**キー `"measurement_result"`**（コード側で差分を挿入）

```gdscript
# MainScene で動的生成
func _build_measurement_result_dialogue(prev_h: float, new_h: float) -> Array:
    var diff = new_h - prev_h
    return [
        {"speaker": "養護教諭", "text": "%.1fcm。" % new_h},
        {"speaker": "はるか", "text": "前回から%.1fcmも伸びてる！！" % diff},
        {"speaker": "主人公（心の声）", "text": "……%.1fcm、か。" % new_h},
    ]
```

---

## 5. 実装ステップ（推奨順）

1. **Global.gd**: `recorded_height`・`height_measured_this_term` 追加。`advance_term()` は `height` を増やすが `recorded_height` は更新しないように変更。グラフ・ステータス表示を `recorded_height` 参照に変更。
2. **MainScene.gd**: `_run_sleep_transition()` に「ミシミシ演出」分岐を追加。
3. **DialogueDatabase.gd**: 上記ダイアログキーを追加。
4. **MainScene.gd**: `refrigerator` ホットスポットに牛乳イベントを追加。
5. **MainScene.gd**: 時間経過後の成長期睡眠ランダムトリガーを追加。
6. **MainScene.gd**: 自販機インタラクトにサプリガチャを追加。
7. **MainScene.gd**: 廊下の `haruka_hallway` ホットスポット追加 → 保健室ワープ。
8. **MainScene.gd**: 保健室の `height_scale` インタラクトで測定・成長反映ロジック実装。
9. 動作確認（学期進行 → 廊下 → 保健室 → 成長反映の一連フロー）。

---

## 6. 決定事項

| 項目 | 決定 |
|---|---|
| `haruka_npc` の配置座標 | 教室の前 |
| 「帰って寝る」実装方法 | 選択した瞬間にフェードアウト → そのまま翌朝演出。`_load_stage("myroom")` は不要 |
| 牛乳イベントの回数上限 | 上限なし（ズルを楽しむ要素として意図的） |
| サプリ「捨てる」の処理 | 何もしない（ダイアログを閉じるだけ） |
| `measurement_result` の管理場所 | `MainScene.gd` 内の `_build_measurement_result_dialogue()` で動的生成 |

### 「帰って寝る」実装メモ

```gdscript
func _trigger_growth_sleep_event() -> void:
    _start_dialogue("growth_sleep_warning")
    await dialogue_finished
    # 「今すぐ帰って寝る」が選ばれた場合:
    # _load_stage は呼ばない。そのままフェードアウト → 翌朝（myroom）へ
    _run_sleep_transition(8, boost=true)
```
