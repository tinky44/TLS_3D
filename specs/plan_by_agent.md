## 体育座り問題の原因調査（2026-03-14）

### 現象

- スカートが右方向に尖った三角形になる
- 背中・臀部が露出する

### 原因：3つのバグが連鎖している

体育座りでは胴体が大きく前傾し、`skirt_ang` がほぼ水平になる。
このとき `skirt_u ≈ (1, 0)`（右向き）、`skirt_n ≈ (0, -1)`（上向き）になる。

#### バグ① `front_side` / `back_side` が `skirt_n` 基準

```gdscript
var front_side = -skirt_n
var back_side  =  skirt_n
```

スカートが水平に近いとき `skirt_n ≈ 上向き` になるため：

- `back_side ≈ 上向き` になり、背面候補が「後ろ」ではなく「上の点」から選ばれる
- `front_side ≈ 下向き` になり、前面候補が「前」ではなく「下の点」から選ばれる

その結果、`back_outer` が臀部ではなく脚側、`front_outer` が極端に下の点へ引っ張られる。

#### バグ② `axis_pos` フィルタが `skirt_u` 基準

`_pick_side_outer_candidate(..., skirt_u, ...)` の内部では、
腰から候補点までの進行量を `skirt_u` で判定している。

```gdscript
var axis_pos = (point - waist_pos).dot(axis_dir)
if axis_pos < 0.0 or axis_pos > skirt_length + 12.0:
	continue
```

体育座りのように `skirt_u ≈ (1, 0)` になると、腰より左にある臀部候補が
`axis_pos < 0` で落ちてしまい、背面候補が消えることがある。

#### バグ③ 裾延長方向が `skirt_u`

```gdscript
var front_hem_ext = front_outer + skirt_u * (skirt_length - front_seg1)
var back_hem_ext  = back_outer  + skirt_u * (skirt_length - back_seg1)
```

`skirt_u ≈ 右向き` のまま残り丈を延長すると、裾が前方へ飛ぶ。
結果として、

- `back_hem` が後方を覆えず、臀部が露出する
- `front_hem` が前方へ伸びて尖る

### 以前の修正で起きたデグレ

`top_n = Vector2(-torso_u.y, torso_u.x)` をそのまま前後判定に使うと、
前傾が深くなるほど `back_side` に下向き成分が混ざる。

```
lean 0°  -> top_n = (-1.00, 0.00)
lean 30° -> top_n = (-0.87, 0.50)
lean 54° -> top_n = (-0.59, 0.81)
```

この状態で `back_side` スコアを取ると、臀部よりも足首の方が高得点になりやすく、
`back_outer` が脚先へ飛んでプリーツ線も大きく崩れる。

---

## 修正方針

### 1. 前後判定軸を「側面ローカルの水平軸」に固定する

側面描画のローカル座標では、常に `+X = 前`、`-X = 後` と扱う。
左右反転は `CharacterDrawer` 側の描画 transform に任せる。

```gdscript
var front_side = Vector2(1, 0)
var back_side  = Vector2(-1, 0)
```

これで姿勢に関係なく、前面候補は右側、背面候補は左側から選ばれる。

### 2. 候補点の進行判定は `torso_u` で行う

候補の「腰からどれだけ下流か」は、スカート中心線ではなく
腰から股への進行方向 `torso_u` を使う。

```gdscript
var front_pick = _pick_side_outer_candidate(..., torso_u, skirt_length)
var back_pick  = _pick_side_outer_candidate(..., torso_u, skirt_length)
```

これで、体育座りでも腰より後ろの臀部候補を不必要に捨てにくくなる。

### 3. ベクトルの役割を分離する

今回の修正では、各ベクトルを次の用途に固定する。

- `skirt_u`: スカート中心線の傾き追従、`p_bottom` の決定
- `top_n`: 腰上端の厚み方向、`belt_front/back` の配置
- `extend_u = Vector2(0, 1)`: 残り丈の延長方向
- `front_side` / `back_side`: 前後判定スコア
- `torso_u`: 候補点の進行量判定と、`jumper_skirt` 上端帯の向き

特に `jumper_skirt` の上端帯は、従来どおり `torso_u * belt_h` で描く。
スカートの残り丈延長にだけ `extend_u` を使う。

### 3.5. `outer` は「膝帯まで」の中間制約点として選ぶ

9点ポリゴンの `front_peak`, `front_outer/back_outer`, `front_lower/back_lower` は、
それぞれ「膝山」「中間折れ点」「下側折れ点」の役割を持つ。
足首側の深い候補まで上側折れ点に含めると、体育座りでは `front_outer` が下へ落ちすぎて
膝の張り出しを拾えなくなる。

- `peak` 候補: 太腿終端、膝、すね上端
- `outer` 候補: 臀部、太腿、膝帯上部、すね上部のごく近傍
- `lower` 候補: 膝下からすね中部まで
- `hem`: `lower` 通過後に `extend_u` 方向へ残り丈を延長して決める

### 4. 不正な6点ポリゴンは台形へフォールバックする

候補点を前後独立に選ぶ都合上、歩きと屈みの中間姿勢では
前後点が入れ替わったり、自己交差したりする可能性がある。

そのため、以下のいずれかを満たした場合は従来の側面台形へ戻す。

- `back_outer.x > front_outer.x`
- `back_hem.x > front_hem.x`
- `back_hem.y < back_outer.y` または `front_hem.y < front_outer.y`
- 6点ポリゴンが自己交差する

---

## 修正対象箇所

| 修正 | ファイル | 変更内容 |
|---|---|---|
| ① | `CharacterBodyDrawer.gd` | `front_side/back_side` を `Vector2(1,0)` / `Vector2(-1,0)` に固定 |
| ② | `CharacterBodyDrawer.gd` | `_pick_side_outer_candidate()` の `axis_dir` を `torso_u` に変更 |
| ③ | `CharacterBodyDrawer.gd` | 残り丈延長用に `extend_u = Vector2(0, 1)` を導入 |
| ④ | `CharacterBodyDrawer.gd` | 9点ポリゴン破綻時の fallback ガードを追加 |

---

## スコープ

### 今回の実装に含む

- 側面スカートの前後非対称9点ポリゴン化
- 前後制約点を「膝固定」ではなく「下半身シルエット最外点」にする
- 現行の `skirt_ang` と `side_hem_w` の補正を維持する
- プリーツ線と `jumper_skirt` 上端帯を、新ポリゴンに整合する形へ保つ

### 今回はスコープ外

- 短スカート時の4点ポリゴン最適化
- 正面・背面スカートの形状見直し

短丈や候補点不足で 9 点ポリゴンが安定しないケースは、
初版では従来の側面台形ロジックへフォールバックしてよい。

---

## 実装ステップ

1. `draw_skirt()` の側面分岐で、現行の `skirt_ang` / `p_bottom` / `side_hem_w` 計算を残す
2. `skirt_u`, `torso_u`, `top_n`, `extend_u`, `front_side/back_side` の役割を分離する
3. 太腿終端・膝・すね上端候補から、前面膝山 `front_peak` を選ぶ
4. 臀部・太腿・膝帯寄り候補から、中間制約点 `front_outer/back_outer` を選ぶ
5. 膝下〜すね中部候補から、下側折れ点 `front_lower/back_lower` を選ぶ
6. 制約点通過後は `extend_u` 方向へ残り丈を延長し、前後裾を決める
7. 不正ポリゴン判定を通ったときだけ 9 点ポリゴンで本体を描画する
8. フォールバック時は従来の側面台形と既存プリーツ処理を使う
9. `jumper_skirt` の上端帯は `torso_u * belt_h` を維持する
10. 立ち / 歩き / 屈み / 体育座りで、膝・脛・足首の貫通と臀部露出を確認する
