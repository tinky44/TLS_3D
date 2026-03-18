# 成長システム改善 設計書

更新日: 2026-03-18（レビュー指摘反映版）

---

## 0. 設計の前提整理

### 身長変数の役割分担

| 変数 | 型 | 意味 | 使用箇所 |
|---|---|---|---|
| `current_params["height"]` | `float` | 実際の体の高さ（正本）。成長イベントで即時更新 | キャラクター描画（人形のサイズ） |
| `recorded_height` ★新規 | `float` | 最後に保健室で測定した値 | 成長グラフ・測定パネルの数値表示 |
| `prev_height` | `float` | 測定アニメーション用の「前回測定値」。役割を変更する | `_show_measurement_result()` のカウントアップ |

★ `Global.height` というトップレベル変数は**存在しない**。すべて `current_params["height"]` 経由で操作する。

### 「測定するまで記録されない」の成立条件

現行の `advance_term()` 末尾に `record_growth_history("growth")` が呼ばれており、これが設計の前提を崩す。**この呼び出しを削除する** ことが最初の必須変更。

---

## 1. Global.gd の変更

### 1.1 変数追加

```gdscript
# Global.gd のトップレベル変数に追加
var recorded_height: float = 0.0        # 最後に測定した身長（グラフ・UI表示用）
var height_measured_this_term: bool = false  # 今学期のはるか誘導が発火済みか
```

### 1.2 `advance_term()` の変更

```gdscript
func advance_term() -> void:
    # 旧: prev_height = current_params["height"]
    # 新: 前回測定値を prev_height に保存（測定パネルのカウントアップ基点に使う）
    prev_height = recorded_height if recorded_height > 0.0 else current_params["height"]

    # （以下の成長計算はそのまま）
    current_params["height"] += calc_growth()
    # 夏休み急成長、growth_spurt なども現行どおり current_params["height"] を変更する

    # 削除: record_growth_history("growth")  ← この行を消す
    # 追加: 今学期の「はるか誘導」フラグをリセット
    height_measured_this_term = false

    # 残りの処理はすべて現行どおり
```

### 1.3 `save_slot()` への追加

```gdscript
config.set_value(section, "recorded_height", recorded_height)
config.set_value(section, "height_measured_this_term", height_measured_this_term)
```

### 1.4 `load_slot()` への追加

```gdscript
recorded_height = config.get_value(section, "recorded_height", current_params["height"])
height_measured_this_term = bool(config.get_value(section, "height_measured_this_term", false))
```

> 旧セーブデータ互換: `recorded_height` のデフォルト値を `current_params["height"]` にすることで、旧データ読み込み時に「実身長 = 記録身長」から始まる。

### 1.5 キャラクター作成時の初期化

`CharacterCreatorScene.gd` で新しいゲームを開始する際に:

```gdscript
global.recorded_height = global.current_params["height"]
global.height_measured_this_term = false
```

---

## 2. `term_end_measurement` イベントの変更

現行 (`MainScene.gd` L2703〜L2713):

```gdscript
elif ev == "term_end_measurement":
    if stage_id == "myroom":
        await get_tree().create_timer(0.4).timeout
        global.advance_term()
        player.call("update_measurements")
        _show_measurement_result(true)   # ← 削除
        return true
```

変更後:

```gdscript
elif ev == "term_end_measurement":
    if stage_id == "myroom":
        await get_tree().create_timer(0.4).timeout
        global.advance_term()
        if player and player.has_method("update_measurements"):
            player.call("update_measurements")
        # _show_measurement_result は呼ばない
        # advance_term() が queue_event("semester_start") を積むので
        # そのまま学期開始ダイアログへ流れる
        return true
```

---

## 3. 成長イベント発生時の朝演出（ミシミシ）

### トリガー条件

`current_params["height"] > recorded_height`（未測定の成長がある）状態で就寝が発生したとき。

### 実装箇所: `_run_sleep_transition()` の拡張

現行 (`MainScene.gd` L2306〜L2328) は引数なしで `_run_sleep_transition()` を呼ぶ。変更は**フェードアウト完了後・フェードイン開始前**に差し込む:

```gdscript
func _run_sleep_transition() -> void:
    var global = get_node_or_null("/root/Global")
    if not global: return

    var fade = ColorRect.new()
    fade.color = Color(0, 0, 0, 0)
    fade.set_anchors_preset(Control.PRESET_FULL_RECT)
    fade.z_index = 110
    fade.process_mode = Node.PROCESS_MODE_ALWAYS
    ui_layer.add_child(fade)

    var tw = create_tween()
    tw.tween_property(fade, "color:a", 1.0, 0.35)
    await tw.finished

    # ★ 追加: 未測定の成長がある場合、黒背景のままダイアログ表示
    if global.current_params["height"] > global.recorded_height:
        var pain_key: String = "growing_pain_sleep_intense" \
            if global.has_meta("growth_pain_intense") and global.get_meta("growth_pain_intense") \
            else "growing_pain_sleep"
        if global.has_meta("growth_pain_intense"):
            global.set_meta("growth_pain_intense", false)
        _start_dialogue("narrator", pain_key)
        # ダイアログ終了まで待機（_end_dialogue() で _in_dialogue = false になる）
        await _wait_dialogue_end()

    global.current_stage_id = "myroom"
    if player and player.has_method("update_measurements"):
        player.call("update_measurements")
    await _load_stage()
    _update_actions_hud()

    var tw_out = create_tween()
    tw_out.tween_property(fade, "color:a", 0.0, 0.45)
    await tw_out.finished
    fade.queue_free()
```

**`_wait_dialogue_end()` ヘルパー** (新規追加):

```gdscript
func _wait_dialogue_end() -> void:
    while _in_dialogue:
        await get_tree().process_frame
```

**DialogueDatabase に `"narrator"` NPC エントリを追加**:

```gdscript
"narrator": {
    "growing_pain_sleep": [
        {"speaker": "", "text": "ミシミシ……ミシミシ……"},
        {"speaker": "", "text": "膝が音を立てている。"},
        {"speaker": "主人公（心の声）", "text": "……また、伸びてるのかな。"},
    ],
    "growing_pain_sleep_intense": [
        {"speaker": "", "text": "ミシミシ……ミシミシ……"},
        {"speaker": "", "text": "ガキッ……ガキッ……"},
        {"speaker": "主人公（心の声）", "text": "骨が……割れるような音がする……！"},
        {"speaker": "主人公（心の声）", "text": "いたい……いたい……"},
    ],
}
```

> `_start_dialogue("narrator", key)` はダイアログパネルを下部に通常表示するため、演出の位置は既存ダイアログと同じになる。

---

## 4. 廊下ではるかが身長測定に誘導するイベント

### 既存実装の制約

- NPCは `_get_nearby_named_npc()` で検知される（`is_npc` メタ）
- ステージオブジェクト（`is_stage_obj`）とは別系統
- `obs_id: "haruka_npc"` のホットスポット定義は**機能しない**

### 実装方針: NPC会話後処理として組み込む

はるかが近くにいる状態でEキーを押すと `_start_dialogue("haruka", key)` が呼ばれる。
既存の `"measure_invite"` キーと同様に、**`_end_dialogue()` の後処理**でワープを実装する。

#### トリガー条件: どのダイアログキーを使うか

`_start_dialogue("haruka", key)` を呼ぶ際のキー選択ロジックに条件を追加する。
はるかに話しかけたとき (`MainScene.gd` のNPC会話発火箇所) に:

```gdscript
func _start_npc_dialogue(npc_id: String) -> void:
    var global = get_node_or_null("/root/Global")
    var key: String = "default"

    if npc_id == "haruka":
        var unrecorded: bool = global and \
            float(global.current_params["height"]) > global.recorded_height and \
            not global.height_measured_this_term and \
            _is_school_hallway_stage()
        if unrecorded:
            key = "height_check_invite"
        else:
            key = _get_haruka_default_key()   # 既存ロジック
    _start_dialogue(npc_id, key)
```

```gdscript
func _is_school_hallway_stage() -> bool:
    var global = get_node_or_null("/root/Global")
    if not global: return false
    var sid: String = String(global.current_stage_id)
    return sid.begins_with("school") and sid.contains("hallway")
```

#### `_end_dialogue()` への後処理追加

既存の `elif _current_dialogue_npc == "haruka" and _current_dialogue_key == "measure_invite":` の近くに:

```gdscript
elif _current_dialogue_npc == "haruka" and _current_dialogue_key == "height_check_invite":
    var global = get_node_or_null("/root/Global")
    if global:
        global.height_measured_this_term = true
        global.current_stage_id = "infirmary"
    await _load_stage()
```

#### `_load_stage()` のシグネチャ

現行は引数なし。`global.current_stage_id` をセットしてから呼ぶ。
`_load_stage("infirmary")` という呼び方は**誤り**。正しくは:

```gdscript
global.current_stage_id = "infirmary"
await _load_stage()
```

#### DialogueDatabase の `"haruka"` エントリに追加

```gdscript
"height_check_invite": [
    {"speaker": "はるか", "text": "あ、ちょっと待って！"},
    {"speaker": "はるか", "text": "なんか……また背、伸びてない？"},
    {"speaker": "主人公", "text": "……そう、かな。"},
    {"speaker": "はるか", "text": "絶対伸びてるって！ちょっと保健室行こ、測ってもらおう！"},
],
```

---

## 5. 保健室の身長計インタラクト

現行では `_nearby_height_scale == true` の時にEキーを押すと
`_start_dialogue("nurse", "measure_offer")` 等が呼ばれる（既存ロジック参照）。
この箇所に測定処理を組み込む。

```gdscript
# _on_height_scale_pressed() 相当の処理に追加・変更
func _on_height_scale_interact() -> void:
    var global = get_node_or_null("/root/Global")
    if not global: return

    var has_unmeasured: bool = float(global.current_params["height"]) > global.recorded_height
    if has_unmeasured:
        _start_dialogue("nurse", "measurement_in_progress")
        # 後処理は _end_dialogue() で
    else:
        _start_dialogue("nurse", "term_school_infirmary")
```

`_end_dialogue()` に後処理追加:

```gdscript
elif _current_dialogue_npc == "nurse" and _current_dialogue_key == "measurement_in_progress":
    var global = get_node_or_null("/root/Global")
    if global:
        var prev_h: float = global.recorded_height
        global.recorded_height = float(global.current_params["height"])
        global.prev_height = prev_h      # カウントアップアニメーションの基点
        global.record_growth_history("measurement")
    _show_measurement_result(false)      # ストーリー測定なので return_to_myroom=false
```

> `_show_measurement_result()` は `global.prev_height` と `global.current_params["height"]` の差分でカウントアップするため、`prev_height = recorded_height（旧値）` をセットしておけばそのまま動く。

#### DialogueDatabase の `"nurse"` エントリに追加

```gdscript
"measurement_in_progress": [
    {"speaker": "養護教諭", "text": "はいはい、じゃあ靴を脱いで身長計に乗って。"},
    {"speaker": "養護教諭", "text": "……はい、そこで止まって。"},
],
```

---

## 6. 特別成長イベント

### 共通方針

成長イベントはすべて `current_params["height"] += N` で実身長を更新。
`recorded_height` は変えない。NPC会話は `_start_dialogue(npc_id, key)` 形式で呼ぶ。

---

### ① 牛乳がぶ飲みイベント

**トリガー**: `myroom` ステージの `refrigerator` をインタラクト（`obs_id == "refrigerator"`）

**効果**: `current_params["height"] += 1.0`。上限なし。

**実装箇所**: `MainScene.gd` の `obs_id == "refrigerator"` ブランチ（Eキー処理内）

```gdscript
elif obs_id == "refrigerator":
    _start_dialogue("narrator", "refrigerator_milk")
    # 後処理は _end_dialogue() で
```

`_end_dialogue()` に追加:

```gdscript
elif _current_dialogue_npc == "narrator" and _current_dialogue_key == "refrigerator_milk":
    var global = get_node_or_null("/root/Global")
    if global:
        global.current_params["height"] += 1.0
        if player and player.has_method("update_measurements"):
            player.call("update_measurements")
```

**DialogueDatabase `"narrator"` に追加**:

```gdscript
"refrigerator_milk": [
    {"speaker": "主人公", "text": "冷蔵庫を開けると、牛乳がある。"},
    {"speaker": "主人公", "text": "……ぐびぐびぐび。"},
    {"speaker": "主人公（心の声）", "text": "（また伸びる気がする）"},
],
```

---

### ② 突発的・成長期睡眠イベント

**トリガー**: 時間経過アクション後に 15% で発火（学校外でも発生）

**効果**: `_run_sleep_transition()` を呼びつつ、実行前に `current_params["height"]` を追加加算。

**「帰って寝る」選択時の動作**: `_load_stage` は呼ばない。選択直後にそのままフェードアウト → 翌朝（`_run_sleep_transition()` を呼ぶ）。

**実装箇所**: 時間経過処理（既存の `_after_action()` 相当）内:

```gdscript
const GROWTH_SLEEP_CHANCE := 0.15

func _after_action() -> void:
    # ... 既存処理 ...
    if randf() < GROWTH_SLEEP_CHANCE:
        _start_dialogue("narrator", "growth_sleep_warning")
        # 後処理は _end_dialogue() で
```

`_end_dialogue()` に追加:

```gdscript
elif _current_dialogue_npc == "narrator" and _current_dialogue_key == "growth_sleep_warning":
    # 選択結果は _last_choice_index で判定（0=帰って寝る, 1=頑張る）
    if _last_choice_index == 0:
        var global = get_node_or_null("/root/Global")
        if global:
            var extra := global.calc_growth() * 0.5
            global.current_params["height"] += extra
        await _run_sleep_transition()
    # else: 何もしない
```

**DialogueDatabase `"narrator"` に追加**:

```gdscript
"growth_sleep_warning": [
    {"speaker": "主人公（心の声）", "text": "……急に、どっと眠気が来た。"},
    {"speaker": "主人公（心の声）", "text": "体が重い。目が開かない。"},
    {"speaker": "__choice__", "choices": ["今すぐ帰って寝る", "もう少し頑張る"]},
],
```

---

### ③ 怪しい成長サプリイベント

**トリガー**: `station_vending` または `vending_machine` のインタラクト時、7% で出現

**効果**: 「飲む」選択 → `current_params["height"] += 10.0` + 激しいミシミシフラグ。「捨てる」→ 何もしない。

**実装箇所**: Eキー処理の `obs_id == "vending_machine"` or `"station_vending"` ブランチ:

```gdscript
elif obs_id == "vending_machine" or obs_id == "station_vending":
    if randf() < 0.07:
        _start_dialogue("narrator", "growth_supplement_found")
    else:
        _start_dialogue("narrator", "term_station_vending")   # 既存キー
```

`_end_dialogue()` に追加:

```gdscript
elif _current_dialogue_npc == "narrator" and _current_dialogue_key == "growth_supplement_found":
    if _last_choice_index == 0:   # 「飲む」
        var global = get_node_or_null("/root/Global")
        if global:
            global.current_params["height"] += 10.0
            global.set_meta("growth_pain_intense", true)
            if player and player.has_method("update_measurements"):
                player.call("update_measurements")
    # 「捨てる」は何もしない
```

**DialogueDatabase `"narrator"` に追加**:

```gdscript
"growth_supplement_found": [
    {"speaker": "主人公", "text": "自動販売機の取り出し口に、何かある……"},
    {"speaker": "主人公", "text": "『怪しい成長サプリ』？"},
    {"speaker": "主人公（心の声）", "text": "……飲むか？"},
    {"speaker": "__choice__", "choices": ["飲む", "捨てる"]},
],
```

---

## 7. 実装ステップ（推奨順）

1. **Global.gd**
   - `recorded_height`・`height_measured_this_term` 変数を追加
   - `advance_term()` の `record_growth_history("growth")` を削除し `height_measured_this_term = false` を追加
   - `prev_height` の設定を `recorded_height` 基点に変更
   - `save_slot()` / `load_slot()` に2変数を追加
   - `CharacterCreatorScene.gd` の新規開始時に初期化を追加

2. **MainScene.gd: `term_end_measurement` イベント変更**
   - `_show_measurement_result(true)` の呼び出しを削除

3. **DialogueDatabase.gd: `"narrator"` エントリ追加**
   - `growing_pain_sleep` / `growing_pain_sleep_intense` / `refrigerator_milk` / `growth_sleep_warning` / `growth_supplement_found`
   - `"haruka"` エントリに `height_check_invite` を追加
   - `"nurse"` エントリに `measurement_in_progress` を追加

4. **MainScene.gd: `_run_sleep_transition()` にミシミシ演出を追加**
   - `_wait_dialogue_end()` ヘルパーも追加

5. **MainScene.gd: Eキー処理に各インタラクト追加**
   - `refrigerator`（牛乳）
   - `vending_machine` / `station_vending`（サプリガチャ）

6. **MainScene.gd: `_after_action()` に成長期睡眠ランダムトリガー追加**

7. **MainScene.gd: はるかNPC会話のキー選択ロジック追加**
   - `_is_school_hallway_stage()` ヘルパー追加

8. **MainScene.gd: `_end_dialogue()` に後処理追加**
   - `height_check_invite` → 保健室ワープ
   - `measurement_in_progress` → 測定反映・`_show_measurement_result(false)`
   - `refrigerator_milk` → 身長加算
   - `growth_sleep_warning` → 選択肢判定・睡眠遷移
   - `growth_supplement_found` → 選択肢判定・身長加算

9. **MainScene.gd: `_on_height_scale_interact()` の測定ロジック実装**

10. 動作確認（学期進行 → ミシミシ → 廊下 → 保健室ワープ → 測定パネル表示）

---

## 8. 決定事項

| 項目 | 決定 |
|---|---|
| `haruka_npc` の配置 | 教室の前 |
| 「帰って寝る」実装方法 | 選択直後にそのまま `_run_sleep_transition()` を呼ぶ。`_load_stage` は呼ばない |
| 牛乳イベントの回数上限 | 上限なし（ズルを楽しむ要素として意図的） |
| サプリ「捨てる」の処理 | 何もしない（ダイアログを閉じるだけ） |
| `measurement_result` の管理 | `_show_measurement_result(false)` をそのまま流用。`prev_height` を事前にセットして対応 |
