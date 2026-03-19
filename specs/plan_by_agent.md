# plan_by_agent.md — AIメモ帳

---

## 課題：高身長時の部屋内バグ（400〜500cm+）

### ゲームコンセプトの前提（2026-03-19 更新）

- 低い天井でキャラがかがむシチュエーションがゲームのコア体験
- **入室ブロックはNG** → むしろ入れる方が楽しい。屈みシステムを生かす
- 500cm超で完全に動けなくなるのは許容（仕様として受け入れる）
- 500cm超時の「詰まり」からの脱出演出などは今回スコープ外

---

### 問題の整理（最新）

| 症状 | 発生条件 | 優先度 |
|---|---|---|
| 扉のoverheadコリジョンに引っかかって入室できない | 身長 > 200cm（扉固定高さ）で発生 | 高 |
| 部屋内でコリジョンが詰まり動けなくなる | 約500cm超（天井+壁に挟まれる） | 中（仕様許容） |
| 部屋内でキャラが天井/地面に埋まる（表示） | 400cm〜 | 中 |
| 家の上に立ってしまう | CollisionShape位置のY計算ずれ | 低〜中 |

### ステージ別 天井高さ

| ステージ | 天井高さ(cm) |
|---|---|
| room / myroom | 240 |
| train | 230 |
| school | 300 |
| infirmary | 270 |
| gymnasium | 400 |

---

### アイデア一覧

#### ❌ アイデア B（廃案）：入室ブロック
→ ゲームコンセプト（屈んで入る体験）と真逆。廃案。
**すでに実装したコードは削除が必要。**

---

#### アイデア F：扉のoverheadコリジョンを無効化（最優先）

現在の扉は height=200cm の overhead 型で、頭上に固定の衝突板が置かれている。
これが高身長キャラの進入を物理的にブロックしている。

対策：`StageBuilder._build_obstacle()` で `type == "overhead"` かつ `id` が `door_to_*` の場合、
コリジョンを生成しない（または `is_solid = false` にする）。

```gdscript
# StageBuilder._build_obstacle() 内
if type == "overhead":
    # 扉は視覚のみ。衝突は天井に任せる
    if obs["id"].begins_with("door_to_"):
        is_solid = false
```

- メリット：シンプル。400cmでも扉を通れる。屈みシステムが自然に発動
- デメリット：扉を「頭突き」できてしまう（演出的には問題ない）
- 実装コスト：低

---

#### アイデア H：コリジョン高さをステージ天井にクランプ

`_update_collision()` でコリジョム高さを `min(visual_height_cm, ceiling_height)` にクランプする。
視覚的には頭が天井から飛び出ても、物理コリジョンは天井に収まる → 詰まりにくくなる。

```gdscript
func _update_collision() -> void:
    var ceiling_h_cm = _get_current_ceiling_height_cm()  # ステージの天井高さ取得
    var effective_h_cm = min(visual_height_cm, ceiling_h_cm) if ceiling_h_cm > 0 else visual_height_cm
    var h_px = effective_h_cm * CM_TO_PX
    var shape = collision_shape.shape as CapsuleShape2D
    if shape:
        shape.height = max(40.0, h_px)
        collision_shape.position.y = -h_px / 2.0
```

- メリット：500cm超でも詰まりにくくなる。屈みシステムとの相乗効果
- デメリット：天井高さをSkeletalPlayerが知る必要がある（Global経由等）
- 実装コスト：中

---

#### アイデア I：overhead障害物の高さを天井高さに統一

現在の扉・ceiling_light 等の overhead は height=200cm で固定。
これを各ステージの ceiling_height（240cm等）に合わせることで「天井ライン」で一貫させる。

```gdscript
# StageBuilder で overhead の高さを ceiling_height に統一
if type == "overhead" and obs["id"].begins_with("door_to_"):
    obs["height"] = stage_data["ceiling_height"]
```

ただし視覚的な扉の高さは変えずに、コリジョン位置のみ調整する形が現実的。

- 実装コスト：中

---

#### アイデア C：コリジョン計算の修正（家の上に立つ問題）

`_update_collision()` の `collision_shape.position.y = -h_px / 2.0` の計算を検証。
CapsuleShape2D の下端が地面 Y=0 と正確に一致するかを確認する。
Godot4 では CapsuleShape2D の全高 = height + 2*radius なので、
radius が加算される分だけ足が地面にめり込む。

```gdscript
# 修正案
shape.height = max(40.0, h_px - shape.radius * 2.0)  # radius分を引く
collision_shape.position.y = -h_px / 2.0
```

- 実装コスト：低（要検証）

---

### 現在の実装状況

| 対応 | 状態 | 備考 |
|---|---|---|
| 起床スポーン位置 X=260cm | ✅ 実装済み | `_run_sleep_transition()` |
| ファストトラベルスポーン X=260cm | ✅ 実装済み | `_on_fast_travel_pressed()` |
| 入室ブロック（B） | ⚠️ 要削除 | ゲームコンセプトと矛盾 |
| 扉コリジョン無効化（F） | 未実装 | 最優先 |
| コリジョン高さクランプ（H） | 未実装 | |

---

### 推奨実装順

1. **Bの削除** → `_get_stage_lock_message()` から身長チェックを取り除く
2. **F（扉コリジョン無効化）** → 高身長でも扉を通れるようにする
3. **C（コリジョン計算修正）** → 家の上に立つバグを潰す
4. **H（コリジョン高さクランプ）** → 500cm超の詰まり緩和

---

_最終更新: 2026-03-19_
