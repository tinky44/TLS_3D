# 側面スカート：膝貫通防止ポリゴン実装計画

## 現状と課題

- 現在の側面スカートは **台形（`draw_trapezoid`）** で描画
- 屈んだとき、膝がスカートを突き抜けて見える
- 台形は中心軸を基準に対称に広がるため、前方（膝側）・後方（臀部側）を個別制御できない

---

## 新方式：6点ポリゴン（前後非対称）

### コンセプト

スカートの前後それぞれの輪郭線を物理的に正しい形状で計算する。

| 輪郭 | 制約点 | その後 |
|---|---|---|
| 背面（後ろ側） | ベルト後端 → 臀部（股関節後端） | 鉛直下方向に落下 |
| 前面（前側） | ベルト前端 → 前側の膝位置 | 鉛直下方向に落下 |

**等長制約**: 前面の全長 = 背面の全長 = `skirt_length`

---

## 変更対象ファイル

- **`godot-project/scripts/CharacterBodyDrawer.gd`**
  - `draw_skirt()` 内 `if facing == "side":` ブロック（行 203〜274）

---

## 座標計算

### ①　胴体の前後方向ベクトル

```gdscript
var crotch_pos = Vector2(d["cx"], d["cy"])
var torso_vec = crotch_pos - waist_pos
# CCW回転（左向き = キャラ背面方向）
var n = Vector2(-torso_vec.y, torso_vec.x).normalized()
var half_w = base_width / 2.0
```

> `n` は左方向（＝背面方向）。既存の `draw_trapezoid` と同じ符号規約。

### ②　ベルト前後端

```gdscript
var belt_front = waist_pos - n * half_w  # 右（前面）
var belt_back  = waist_pos + n * half_w  # 左（背面）
```

### ③　臀部座標（背面制約点）

```gdscript
# 股関節の背面端 = crotch_pos を背面方向にオフセット
var butt_pos = crotch_pos + n * half_w
```

### ④　前側膝座標（前面制約点）

```gdscript
var ang_l = d["leg_l_angle"] * PI / 180.0 + PI / 2.0
var ang_r = d["leg_r_angle"] * PI / 180.0 + PI / 2.0
var knee_l = Vector2(d["cx"] + d["thigh_l"] * cos(ang_l),
                     d["cy"] + d["thigh_l"] * sin(ang_l))
var knee_r = Vector2(d["cx"] + d["thigh_l"] * cos(ang_r),
                     d["cy"] + d["thigh_l"] * sin(ang_r))
# 前方（x が大きい方）の膝を使う（キャラが右向きの場合）
var knee_pos = knee_l if knee_l.x > knee_r.x else knee_r
```

---

## ポリゴン頂点の計算

### 背面側（belt_back → butt_pos → back_hem）

```gdscript
var back_seg1 = belt_back.distance_to(butt_pos)
var back_drop = skirt_length - back_seg1

var back_constraint: Vector2
var back_hem: Vector2
if back_drop > 0.0:
    back_constraint = butt_pos
    back_hem = Vector2(butt_pos.x, butt_pos.y + back_drop)
else:
    # スカートが臀部に届かない（ごく短いスカート）
    var dir = (butt_pos - belt_back).normalized()
    back_constraint = belt_back + dir * skirt_length
    back_hem = back_constraint  # 頂点を省略（4点ポリゴンになる）
```

### 前面側（belt_front → knee_pos → front_hem）

```gdscript
var front_seg1 = belt_front.distance_to(knee_pos)
var front_drop = skirt_length - front_seg1

var front_constraint: Vector2
var front_hem: Vector2
if front_drop > 0.0:
    front_constraint = knee_pos
    front_hem = Vector2(knee_pos.x, knee_pos.y + front_drop)
else:
    # スカートが膝に届かない
    var dir = (knee_pos - belt_front).normalized()
    front_constraint = belt_front + dir * skirt_length
    front_hem = front_constraint
```

---

## ポリゴン構築

### 通常ケース（スカートが臀部・膝を超える長さ）

```gdscript
# 時計回りに並べる
var pts = PackedVector2Array([
    belt_back,        # 1: ベルト後端
    butt_pos,         # 2: 臀部（背面制約点）
    back_hem,         # 3: 背面裾
    front_hem,        # 4: 前面裾
    knee_pos,         # 5: 膝（前面制約点）
    belt_front,       # 6: ベルト前端
])
ctx.canvas.draw_polygon(pts, PackedColorArray([bottoms_color]))
```

頂点 6 → 1 の辺でベルト上端が自動的に閉じる。

---

## プリーツ・ベルト描画の対応

既存のプリーツ（行 247〜259）とベルト（行 261〜273）は
`waist_pos` と `p_bottom` を基準にしているため、`p_bottom` を廃止後は
プリーツ中心軸の代替として以下を使う：

```gdscript
# プリーツ用: 前後裾の中点を新しい p_bottom として使用
var p_bottom_new = (front_hem + back_hem) / 2.0
```

ベルト描画は `waist_pos` と `n` をそのまま流用できる。

---

## エッジケース

| ケース | 対処 |
|---|---|
| `back_drop <= 0`（短スカートが臀部未到達） | `butt_pos` 省略、4点ポリゴン |
| `front_drop <= 0`（短スカートが膝未到達） | `knee_pos` 省略、4点ポリゴン |
| 膝が後方に引いている（knee_pos.x < belt_back.x） | 自然に後方に延びるためそのまま計算（スカートが後ろになびく表現） |
| `torso_vec` が零ベクトル | `n = Vector2(-1, 0)` にフォールバック |

---

## 実装ステップ

1. `draw_skirt()` の `if facing == "side":` ブロック全体を上記コードに置き換え
2. `skirt_length` の計算は既存のままを使用（行 180〜198 は変更不要）
3. プリーツ描画の `p_bottom` を `p_bottom_new` に置き換え
4. ベルト描画（is_jumper_skirt）の `p_bottom` を `p_bottom_new` に置き換え
5. 動作確認：立ち / 歩き / 屈み各ポーズでスカートが膝を突き抜けないことを確認
