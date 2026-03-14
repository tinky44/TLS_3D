
## 体育座り問題の原因調査（2026-03-14）

### 現象

- スカートが右方向に尖った三角形になる
- 背中・臀部が露出する

### 原因：3つのバグが連鎖している

体育座りでは胴体が大きく前傾し、`skirt_ang` がほぼ水平になる。
このとき `skirt_u ≈ (1, 0)`（右向き）、`skirt_n ≈ (0, -1)`（上向き）になる。

#### バグ① `front_side` / `back_side` が `skirt_n` 基準（行 315–316）

```gdscript
var front_side = -skirt_n  # 現行：スカート軸の垂直方向
var back_side  =  skirt_n
```

スカートが水平に近いとき `skirt_n ≈ 上向き` になるため：
- `back_side ≈ 上向き` → "背面"が「上にある点」に変わる
- `front_side ≈ 下向き` → "前面"が「下にある点」になる

結果として、`back_outer` は脚候補から「最も上にある点（股関節付近）」、
`front_outer` は「最も下にある点（足首）」が選ばれてしまう。

#### バグ② `axis_pos` フィルタが `skirt_u` 基準（行 333–334）

`_pick_side_outer_candidate(... skirt_u ...)` の内部フィルタ：

```gdscript
var axis_pos = (point - waist_pos).dot(axis_dir)  # axis_dir = skirt_u
if axis_pos < 0.0 or axis_pos > skirt_length + 12.0:
    continue
```

`skirt_u ≈ (1, 0)` のとき、腰より左（後方）にある臀部候補は
`axis_pos < 0` でフィルタアウトされ、有効な背面候補がゼロになることがある。

#### バグ③ 裾延長方向が `skirt_u`（行 358–359）

```gdscript
var front_hem_ext = front_outer + skirt_u * (skirt_length - front_seg1)
var back_hem_ext  = back_outer  + skirt_u * (skirt_length - back_seg1)
```

`skirt_u ≈ 右向き` なので、裾延長が右（前方）に伸びる。
`back_hem` まで右に行くため、後方（左側）が完全に露出する。
`front_hem` はさらに右に飛び出して「尖り」になる。

### デグレの原因（修正①の設計ミス）

`top_n = Vector2(-torso_u.y, torso_u.x)` は torso_u の CCW 回転で、
胴体が前傾するにつれ **下方向成分が大きくなる**。

```
lean 0°  → top_n = (-1,  0)     back_side が 左 ✓
lean 30° → top_n = (-0.87, +0.5) back_side が 左+下
lean 54° → top_n = (-0.59, +0.81) back_side が ほぼ下 ← 問題
```

`back_side ≈ 下方向` になると、脚候補の中で
**最も y が大きい点（足首）** がスコア最大で `back_outer` に選ばれる。

```
lean = 54° での back_side = (-0.59, 0.81) のスコア
  足首 ( +5, +130): score = -2.95 + 105.3 = 102  ← 勝つ
  臀部 ( -8,  +57): score =  4.72 +  46.2 =  51
```

→ `back_outer = 足首`（腰から 130px 下）
→ プリーツ線の `mid_p = back_outer.lerp(...)` が画面外まで伸びる = デグレ

### 修正方針（再設計）

#### 修正①（再設計）：スクリーン水平軸に固定する

前後方向を **画面の横軸（常に水平）** に固定する。
側面描画ではキャラクターは常に右向きなので：

```gdscript
# 誤（lean に引きずられる）
var front_side = -top_n
var back_side  =  top_n

# 正：右 = 前面、左 = 背面（姿勢によらず不変）
var front_side = Vector2(1, 0)
var back_side  = Vector2(-1, 0)
```

| 姿勢 | back_side スコア（足首 +5, +130） | back_side スコア（臀部 -8, +57） |
|---|---|---|
| 旧 top_n (lean 54°) | **102**（足首が勝つ） | 51 |
| 新 (-1, 0) | **-5**（足首は負 = 除外） | **8**（臀部が勝つ）✓ |

#### 修正②：`axis_dir` を `torso_u` に変える（維持）

```gdscript
# 済・維持
var front_pick = _pick_side_outer_candidate(..., torso_u, skirt_length)
var back_pick  = _pick_side_outer_candidate(..., torso_u, skirt_length)
```

#### 修正③（再設計）：裾延長を純粋な重力方向に変更

`normalize(skirt_u + gravity)` にも前方成分が残るため、
extreme lean では `back_hem` が前方へ飛ぶ。純粋な `(0, 1)` に変更する。

```gdscript
# 誤（前方成分が残る）
var extend_u = _normalized_or(skirt_u + Vector2(0, 1), Vector2(0, 1))

# 正：重力方向のみ
var extend_u = Vector2(0, 1)
```

通常姿勢では `skirt_u ≈ (0, 1)` なので見た目の変化はゼロ。

### 修正対象箇所（再設計後）

| 修正 | ファイル | 変更内容 |
|---|---|---|
| ① | CharacterBodyDrawer.gd:315–316 | `Vector2(1,0)` / `Vector2(-1,0)` に変更 |
| ② | CharacterBodyDrawer.gd:333–334 | `torso_u`（済・維持） |
| ③ | CharacterBodyDrawer.gd:358 | `extend_u = Vector2(0, 1)` に変更 |

---

## スコープ

### 今回の実装に含む

- 側面スカートの前後非対称ポリゴン化
- 前後制約点を「膝固定」ではなく「下半身シルエット最外点」に変更
- 現行の傾き追従と裾幅補正の維持
- プリーツ線と上端帯を、新ポリゴンに整合する形へ変更

### 今回はスコープ外

- 短スカート時の 4 点ポリゴン最適化

初版では、`front_seg1` または `back_seg1` が `skirt_length` を超えるような短丈ケースは
**従来の側面台形ロジックへフォールバック**してよい。

---

## 実装ステップ

1. `draw_skirt()` の側面分岐で、現行の `skirt_ang` / `p_bottom` / `side_hem_w` 計算を残す
2. `u`, `n`, `belt_front/back`, `hem_front/back_base` を導入する
3. 膝・脛・足首・臀部寄り候補から、前後シルエット最外点を選ぶ
4. 制約点通過後は `u` 方向へ残り丈を延長し、前後裾を決める
5. 6 点ポリゴンで側面スカート本体を描画する
6. プリーツ線は `belt_back/front` と `back_hem/front_hem` の間で引き直す
7. `jumper_skirt` の上端帯は上端辺 + `u * belt_h` で描き直す
8. 立ち / 歩き / 屈みで、膝・脛・足首の貫通が減っているか確認する
