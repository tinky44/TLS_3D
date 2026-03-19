# plan_by_agent.md — AIメモ

## 議論: 500cm超の屈みシステム限界問題（2026-03-19）

### 課題
- 屈みシステムはこのゲームのコア演出（天井より高くても膝・腰を曲げて入れる）
- 500cm超になると、家の天井（約240cm）に対して屈んでも物理的に入れない
- 起床時に左に落ちるバグがある
- プレイヤーは巨大化して家を突き抜ける演出を楽しんでいる

### 設計方針: A案「突き抜け演出」路線（採用）

「もうこの家には住めない」体験こそがゲームのコンセプト。
500cm超で家の中を移動不可にするのは仕様として受け入れる。

---

## 詳細設計（2026-03-19）

### 現状把握

| 項目 | 値 |
|---|---|
| myroomの天井 | 240cm |
| ベッド位置 | x=30〜230cm |
| 起床スポーン位置 | x=260cm（既にベッド右隣に修正済み） |
| キャラ衝突形状 | CapsuleShape2D、高さ = visual_height_cm * CM_TO_PX |

**起床バグの真因**: 500cmキャラのカプセル衝突形状（高さ1000px）が
天井（240cm=480px）に当たり、物理エンジンに押し出される。

---

### 実装タスク

#### 【1】起床バグ修正（最優先）
対象: `MainScene.gd` / `_run_sleep_transition()`

スポーン直後に衝突を1フレーム無効化する。

```gdscript
if player:
    player.position = Vector2(260 * p, 0)
    player.collision_shape.disabled = true
    await get_tree().process_frame
    player.collision_shape.disabled = false
```

#### 【2】「屈み不能」フラグの追加
対象: `SkeletalPlayer.gd`

変数追加:
```gdscript
var is_crouch_impossible: bool = false
```

`_handle_auto_crouch()` 末尾に判定追加:
```gdscript
if target_crouch_cm > 0 and target_crouch_cm < visual_height_cm * 0.45:
    is_crouch_impossible = true
else:
    is_crouch_impossible = false
```

`_physics_process()` で移動停止:
```gdscript
if is_crouch_impossible:
    velocity.x = move_toward(velocity.x, 0, SPEED)
```

#### 【3】「家より大きくなった」演出と屋外への強制退出
対象: `MainScene.gd`、`DialogueDatabase.gd`

**トリガー条件:**
- `player.is_crouch_impossible == true`
- 現在のステージが `room` または `myroom`（天井のある家系）
- 1回だけ（フラグで二重起動防止）

**処理の流れ:**
1. `_process()` で `player.is_crouch_impossible` を監視
2. 初回のみ `_trigger_too_big_for_house()` を呼ぶ（`call_deferred`）
3. 暗転（フェードアウト）
4. `global.current_stage_id = "outdoor"` に切り替え
5. `await _load_stage()`
6. プレイヤー位置を outdoor 左端付近（x=80cm）に設定
7. フェードイン
8. ダイアログ `"player"` / `"too_big_for_house"` を表示

**MainScene.gd に追加する変数・関数:**
```gdscript
var _crouch_impossible_notified: bool = false

# _process() 内
if player and player.get("is_crouch_impossible"):
    var sid = String(global.current_stage_id) if global else ""
    if (sid == "room" or sid == "myroom") and not _crouch_impossible_notified:
        _crouch_impossible_notified = true
        call_deferred("_trigger_too_big_for_house")
elif player and not player.get("is_crouch_impossible"):
    _crouch_impossible_notified = false

# 新規関数
func _trigger_too_big_for_house() -> void:
    if _edge_transition_running or _in_dialogue:
        return
    var global = get_node_or_null("/root/Global")
    if not global:
        return
    _edge_transition_running = true
    # フェードアウト
    var fade = ColorRect.new()
    fade.color = Color(0, 0, 0, 0)
    fade.set_anchors_preset(Control.PRESET_FULL_RECT)
    fade.z_index = 110
    ui_layer.add_child(fade)
    var tw = create_tween()
    tw.tween_property(fade, "color:a", 1.0, 0.5)
    await tw.finished
    # outdoorへ遷移
    global.current_stage_id = "outdoor"
    await _load_stage()
    if player:
        player.position = Vector2(80 * p, 0)
    # フェードイン
    var tw_out = create_tween()
    tw_out.tween_property(fade, "color:a", 0.0, 0.5)
    await tw_out.finished
    fade.queue_free()
    _edge_transition_running = false
    # ダイアログ表示
    _start_dialogue("player", "too_big_for_house")
```

**DialogueDatabase.gd の `"player"` セクションに追加:**
```gdscript
"too_big_for_house": [
    {"speaker": "（主人公）", "text": "家より大きくなっちゃった……。"},
],
```

---

### 対応しないこと（仕様として受け入れ）
- 500cm超の家内部での移動 → 不可。ゲームの意図する体験
- ドア方向だけ移動可能にする → 複雑になるので実装しない

---

### フェーズ分け

| 優先 | 内容 | ファイル |
|---|---|---|
| 1 | 起床バグ修正（衝突1フレーム無効化） | MainScene.gd |
| 2 | is_crouch_impossible フラグ + 移動停止 | SkeletalPlayer.gd |
| 3 | 屋外への強制退出 + ダイアログ演出 | MainScene.gd、DialogueDatabase.gd |

### 次のアクション
- [ ] ユーザーの承認を得て実装開始
