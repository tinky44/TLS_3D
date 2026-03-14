# 側面スカート：下半身シルエット追従ポリゴン実装計画

## 目的

- 現在の側面スカートは **台形（`draw_trapezoid`）** で描画している
- 屈みや歩行で、膝・脛・足首が前に出たときにスカートを突き抜けて見える
- ただし、現行の「脚角 0.7 倍 + 腰角追従」による**スカート全体の傾き**は残したい

今回の方針は、**既存のスカート軸と裾幅補正は維持したまま**、
前後輪郭だけを非対称ポリゴン化して、下半身シルエットの最外点を包むようにする。

---

## 基本方針

### 残すもの

- `waist_pos`
- `skirt_length`
- `skirt_ang`
- `waist_lean`
- `p_bottom`
- `side_hem_w`

つまり、現行の側面スカートが持っている
「全体としてどちらに傾くか」「どれくらい裾を広げるか」はそのまま使う。

### 置き換えるもの

- `draw_trapezoid()` による左右対称な側面シルエット
- 「前側制約点 = 膝固定」という前提

前側は**膝ではなく、下半身人体の一番外側の点**を使う。
足首が最前面なら足首、脛途中が最前面なら脛途中、膝が最前面なら膝を採用する。

背面側も同様に、臀部固定ではなく**後方シルエットの最外点**を使う。
ただし、立位で後方シルエットが臀部になるケースが多いため、臀部候補は必ず含める。

---

## 変更対象ファイル

- **`godot-project/scripts/CharacterBodyDrawer.gd`**
  - `draw_skirt()` 内 `if facing == "side":` ブロック

---

## 既存の傾きロジックは維持する

以下は現行のまま使う。

```gdscript
var avg_leg_ang = (d["leg_l_angle"] + d["leg_r_angle"]) / 2.0
var skirt_ang = (avg_leg_ang * 0.7) * PI / 180.0 + PI / 2.0

var waist_lean = 0.5 if (is_jumper or is_blouse_bow or is_jumper_skirt) else 0.3
skirt_ang += d["waist_angle"] * waist_lean

var p_bottom = Vector2(
    waist_pos.x + skirt_length * cos(skirt_ang),
    waist_pos.y + skirt_length * sin(skirt_ang)
)
```

この `waist_pos -> p_bottom` を **スカート中心軸** として使い続ける。

---

## 軸ベースの基準点

```gdscript
var axis = p_bottom - waist_pos
var u = axis.normalized() if axis.length() > 0.01 else Vector2(0, 1)
var n = Vector2(-u.y, u.x).normalized() # +n = 背面側, -n = 前面側

var half_top = base_width / 2.0
var half_hem = side_hem_w / 2.0

var belt_back = waist_pos + n * half_top
var belt_front = waist_pos - n * half_top
var hem_back_base = p_bottom + n * half_hem
var hem_front_base = p_bottom - n * half_hem
```

ここでの `n` は、現行 `draw_trapezoid()` と同じく
スカート軸に直交する方向を表す。

---

## 下半身シルエット候補点

「前側制約点」「背面側制約点」は、固定の膝ではなく
**下半身の外形候補群から最外点を選ぶ**。

### 候補に含める点

```gdscript
var crotch_pos = Vector2(d["cx"], d["cy"])

var ang_l = d["leg_l_angle"] * PI / 180.0 + PI / 2.0
var ang_r = d["leg_r_angle"] * PI / 180.0 + PI / 2.0

var knee_l = Vector2(d["cx"] + d["thigh_l"] * cos(ang_l),
                     d["cy"] + d["thigh_l"] * sin(ang_l))
var knee_r = Vector2(d["cx"] + d["thigh_l"] * cos(ang_r),
                     d["cy"] + d["thigh_l"] * sin(ang_r))
```

基本候補:

- `knee_l`, `knee_r`
- `crotch_pos + n * half_top`（臀部寄り候補）
- `crotch_pos - n * half_top`（骨盤前面寄り候補）

追加候補:

- `skirt_long`:
  - `ankle_l`, `ankle_r`
- プリーツ系:
  - 既存で裾幅補正に使っている `shin_l * 0.4` 相当の前後点

要点:

- **足首が最前面なら足首が勝つ**
- **脛途中が最前面なら脛途中が勝つ**
- **臀部より後ろに脚が出ていれば、その脚側が背面候補として勝つ**

---

## 最外点の選び方

候補点を「スカート軸から見てどちら側にどれだけ張り出しているか」で評価する。

```gdscript
func side_proj(p: Vector2, origin: Vector2, side_dir: Vector2) -> float:
    return (p - origin).dot(side_dir)

var front_side = -n
var back_side = n
```

前面候補:

- `side_proj(candidate, waist_pos, front_side)` が最大の点

背面候補:

- `side_proj(candidate, waist_pos, back_side)` が最大の点

これにより、「膝」ではなく
**その姿勢で実際にシルエットを作っている最前面/最後面の点**を採れる。

---

## 輪郭線の作り方

### 方針

既存の傾きは消さず、制約点を通過した後も
**鉛直落下ではなく、現在のスカート軸 `u` に沿って残り丈を延長**する。

これで、

- 現行の傾き追従は維持
- そのうえで前後の張り出しだけ非対称化

が両立できる。

### 前面側

```gdscript
var front_outer = ... # 前面最外点
var front_seg1 = belt_front.distance_to(front_outer)
var front_remain = skirt_length - front_seg1

var front_hem_ext = front_outer + u * front_remain
```

### 背面側

```gdscript
var back_outer = ... # 背面最外点
var back_seg1 = belt_back.distance_to(back_outer)
var back_remain = skirt_length - back_seg1

var back_hem_ext = back_outer + u * back_remain
```

### 既存裾幅との統合

新方式でも、現行の `side_hem_w` による裾幅確保は残したい。
そのため最終的な裾端は、基準裾と拡張裾のうち「より外側」を使う。

```gdscript
var front_hem = front_hem_ext
if side_proj(hem_front_base, waist_pos, front_side) > side_proj(front_hem, waist_pos, front_side):
    front_hem = hem_front_base

var back_hem = back_hem_ext
if side_proj(hem_back_base, waist_pos, back_side) > side_proj(back_hem, waist_pos, back_side):
    back_hem = hem_back_base
```

これで、

- 現行補正で確保していた最低限の裾幅は維持
- さらに必要な姿勢では、前後どちらかだけを追加で外へ張り出せる

---

## ポリゴン構築

通常ケースでは 6 点ポリゴンとする。

```gdscript
var pts = PackedVector2Array([
    belt_back,
    back_outer,
    back_hem,
    front_hem,
    front_outer,
    belt_front,
])
ctx.canvas.draw_polygon(pts, PackedColorArray([bottoms_color]))
```

時計回りで並べる。

---

## プリーツ描画

ここは `p_bottom_new` を単純導入するのではなく、
**ポリゴンの内側に確実に収まるコア四辺形**を使う。

```gdscript
var pleat_top_l = belt_back
var pleat_top_r = belt_front
var pleat_bot_l = back_hem
var pleat_bot_r = front_hem
```

```gdscript
for i in range(1, 7):
    var t = float(i) / 7.0
    var top_p = pleat_top_l.lerp(pleat_top_r, t)
    var bot_p = pleat_bot_l.lerp(pleat_bot_r, t)
    ctx.canvas.draw_line(top_p, bot_p, pleat_col, 1.5)
```

これで、

- プリーツ線の始点/終点が常に上端・裾端の内側に乗る
- `front_outer` / `back_outer` の張り出しに引きずられて線が外へ飛び出しにくい

---

## `jumper_skirt` の上端帯

ここで重要なのは「新しいポリゴンでも**スカート上端が正しい角度と位置を保つこと**」。
そのため、上端帯は `p_bottom_new` のような中心点ではなく、
**上端辺そのもの**から作る。

```gdscript
var belt_color = bottoms_color.darkened(0.35)
var belt_h = 7.0
var belt_pts = PackedVector2Array([
    belt_back,
    belt_front,
    belt_front + u * belt_h,
    belt_back + u * belt_h,
])
ctx.canvas.draw_polygon(belt_pts, PackedColorArray([belt_color]))
```

これなら、

- 直立時の上端ラインがそのまま正しく出る
- 屈み時も現行のスカート軸に沿って帯が傾く
- 上衣側の共有アンカーとも整合しやすい

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
