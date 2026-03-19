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
x=260cmに置いても衝突形状が天井を突き抜けるため左に落ちる。

---

### 実装タスク

#### 【1】起床バグ修正（最優先）
対象: `MainScene.gd` / `_run_sleep_transition()`

スポーン直後に衝突を1フレーム無効化する。

```gdscript
if player:
    player.position = Vector2(260 * p, 0)
    # 500cm超のとき天井と衝突して押し出されるため、1フレーム衝突を切る
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
# 天井高さに対して自身の身長が1.5倍超 = 屈んでも物理的に入れない
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

#### 【3】「詰まり演出」メッセージ
対象: `MainScene.gd`

既存の `mood_feedback_label` を流用し、初回詰まり時のみ表示:
```gdscript
var _crouch_impossible_notified: bool = false

# _process() 内で監視
if player.is_crouch_impossible and not _crouch_impossible_notified:
    _crouch_impossible_notified = true
    _show_mood_feedback("大きくなりすぎて、身動きが取れない...")
elif not player.is_crouch_impossible:
    _crouch_impossible_notified = false
```

---

### 対応しないこと（仕様として受け入れ）
- 500cm超の家内部での移動 → 不可。ゲームの意図する体験
- 衝突形状が天井を突き抜ける見た目 → 演出として許容
- ドア方向だけ移動可能にする → 複雑になるので実装しない

---

### フェーズ分け

| フェーズ | 内容 | 難易度 |
|---|---|---|
| 今すぐ | 起床バグ修正（衝突1フレーム無効化） | 低 |
| 今すぐ | is_crouch_impossible フラグ + 移動停止 | 低 |
| 今すぐ | 詰まりメッセージ表示 | 低 |
| 後で | きしみ音・頭が天井を突き破る視覚演出 | 中 |

### 次のアクション
- [ ] ユーザーの承認を得て実装開始
