# キャラクターポーズ仕様書（現行実装準拠）

本書は、`CharacterPoseCalculator.gd` と `SkeletalPlayer.gd` の実装を基準に、ポーズ計算・屈み計算・高さ決定ロジックを最新化した仕様です。

## 0. 対象ファイル

- `godot-project/scripts/CharacterPoseCalculator.gd`
- `godot-project/scripts/SkeletalPlayer.gd`

## 1. 座標系と単位

- Godot 2D座標系（+Yが下、-Yが上）を使う。
- `p = CM_TO_PX`（cm→px変換係数）。
- 身体寸法 `m` は cm。描画用座標は px。
- 股座標を `(cx, cy)` とし、`cx=0`、`cy=y_crotch` を基点に全座標を展開する。

## 2. 入力値と主要変数

### 2.1 プレイヤー状態

- `pose`: `"normal" | "taiiku_suwari" | "chair_sit" | "sleep"`
- `is_walking`
- `walk_phase`
- `visual_height_cm`（この値に合わせて屈み量を逆算）

### 2.2 ストレス姿勢入力

- `receives_global_stress == true` のときのみ Global の `stress` を姿勢に反映。
- `stress_ratio = clampf(Global.stress / 100.0, 0.0, 1.0)`

### 2.3 部位長（px）

`CharacterPoseCalculator` 内で以下を計算する。

```gdscript
head_h  = m["head"] * p
navel_l = m["arm"] * 0.40 * p
chest_l = m["arm"] * 0.60 * p
thigh_l = m["leg"] * 0.55 * p
shin_l  = m["leg"] * 0.45 * p
```

## 3. ポーズ分岐（実装順）

`calculate_pose_data()` は次の優先順で分岐する。

1. `pose == "taiiku_suwari"`
2. `pose == "chair_sit"`
3. `pose == "sleep"`
4. `is_crouching`（`pose=="normal"` かつ `visual_height_cm < m["height"] - 0.1`）
5. それ以外（通常立ち + ストレス姿勢）

## 4. 各ポーズの角度・高さ

### 4.1 通常立ち（非屈み）

- 初期脚振り（歩行）:
  - `walk_amp = 12.0 if is_walking else 0.0`
  - `leg_l_angle = walk_amp * sin(walk_phase)`
  - `leg_r_angle = walk_amp * sin(walk_phase + PI)`（脚痛時は右脚振幅0.3倍）
  - `arm_l/r_angle = -walk_amp * 0.6 * sin(...)`
- 初期腰高: `y_crotch = -m["leg"] * p`

#### ストレス姿勢（通常立ち時のみ）

```gdscript
stress_pose = stress_ratio * (0.35 if is_walking else 1.0)
waist_angle = 0.20 * stress_pose
arm_l_angle += 8.0 * stress_pose
arm_r_angle += 8.0 * stress_pose
```

補足:

- 最大でも `waist_angle=0.20rad`（約11.5度）なので、軽い猫背表現。
- 歩行中は 35% に減衰するため、立ち止まり時の方が姿勢変化が大きい。

### 4.2 しゃがみ（normal中の可変屈み）

#### 4.2.1 目的

`visual_height_cm` に合う姿勢を二分探索で解く。

```gdscript
target_px = visual_height_cm * p
t in [0.0, 2.0] を15回二分探索
```

#### 4.2.2 `t -> (waist_angle, leg_fold)` 変換

`_get_crouch_params(t)`:

```gdscript
MAX_W = 1.3
KNEE_START = 0.7 / 1.3  # 約0.53846

if t <= KNEE_START:
    w = t * 1.3
    l = 0.0
elif t <= 1.0:
    w = t * 1.3
    l = ((t - KNEE_START) / (1 - KNEE_START)) * 0.4
else:
    w = 1.3
    l = 0.4 + (t - 1.0) * 0.6
```

- 前半: まず腰を曲げる。
- 後半: 腰角を上限固定し、膝折りを増やす。

#### 4.2.3 しゃがみ時の角度

```gdscript
knee_l = knee_r = PI * 0.7 * l_fac
base_leg = -100.0 * l_fac
leg_l_angle = base_leg + walk_amp * sin(walk_phase)
leg_r_angle = base_leg + walk_amp * sin(walk_phase + PI)

arm_drop = waist_angle / 1.3
base_arm = -45.0 * arm_drop
arm_l/r_angle = base_arm - walk_amp * 0.4 * sin(...)
```

#### 4.2.4 股の高さ

```gdscript
dy1 = thigh_l * cos(leg_l) + shin_l * cos(leg_l + knee_l)
dy2 = thigh_l * cos(leg_r) + shin_l * cos(leg_r + knee_r)
y_crotch = -max(dy1, dy2)
```

### 4.3 体育座り

```gdscript
waist_angle = 0.3
leg_l/r_angle = -130
knee_l/r = PI * 0.72
arm_l/r_angle = -60
y_crotch = -15.0 * p
```

### 4.4 椅子座り

```gdscript
waist_angle = PI * 0.5
leg_l/r_angle = -90
knee_l/r = PI * 0.5
arm_l/r_angle = -30
thigh_down = thigh_l * cos(leg_l_angle * PI / 180)
y_crotch = -max(thigh_down, 5.0 * p)
```

### 4.5 睡眠

```gdscript
waist_angle = PI * 0.85
leg_l/r_angle = -120
knee_l/r = PI * 0.65
arm_l/r_angle = -80
y_crotch = -12.0 * p
```

## 5. 側面座標の算出式

```gdscript
cx = 0
cy = y_crotch

navel_ang = waist_angle * 0.5
navel_x = cx + navel_l * sin(navel_ang)
navel_y = cy - navel_l * cos(navel_ang)

sx = navel_x + chest_l * sin(waist_angle)
sy = navel_y - chest_l * cos(waist_angle)

nx = sx + 2.0 * (m["neck"] * p) * sin(waist_angle)
ny = sy - 2.0 * (m["neck"] * p) * cos(waist_angle)

hx = nx + (head_h / 2.0) * sin(waist_angle)
hy = ny - (head_h / 2.0) * cos(waist_angle)
```

## 6. 正面・背面座標の算出式

正面・背面は「背骨Xを中心固定」「Yのみ圧縮」で計算する。

```gdscript
front_navel_x = cx
front_navel_y = cy - navel_l * cos(navel_ang)

front_sx = cx
front_sy = front_navel_y - chest_l * cos(waist_angle)

front_nx = cx
front_ny = front_sy - 2.0 * (m["neck"] * p) * cos(waist_angle)

front_hx = cx
front_hy = front_ny - (head_h / 2.0) * cos(waist_angle * 0.5)
```

補足:

- 頭だけ `cos(waist_angle*0.5)` を使うため、上体の潰れを少し緩和している。

## 7. 腰（骨盤）座標

パンツ・スカート基準点として別途計算。

```gdscript
hip_l = (m["arm"] * 0.20) * p
hip_ang = waist_angle * 0.25

hip_x = cx + hip_l * sin(hip_ang)
hip_y = cy - hip_l * cos(hip_ang)

front_hip_x = cx
front_hip_y = cy - hip_l * cos(hip_ang)
```

## 8. `visual_height_cm` の決まり方（SkeletalPlayer）

`_update_visual_height()` が毎フレーム目標高さを更新し、姿勢計算側はその値を参照する。

- 通常: `target_h_cm = m["height"]`
- 体育座り: `height * 0.5`
- 椅子座り: `height * 0.55`
- 睡眠: `height * 0.35`
- 通常 + 障害物: `target_crouch_cm = min_obs_h_cm - 8.0`
- 通常 + 手動屈み（`S`）: `height * 0.8`
- 天井制約: `target_h_cm <= ceil_h_cm - 8.0`
- 補間: `visual_height_cm = lerp(visual_height_cm, target_h_cm, 15.0 * delta)`

## 9. 実数例（180cm, `p=2.0`, 初期比率）

`Global` 初期値（180cm, ratio 7.5, legRatio 48）から:

- `head=24.0cm`, `leg=86.4cm`, `arm=59.04cm`, `neck=5.28cm`
- `head_h=48.0px`, `navel_l=47.232px`, `chest_l=70.848px`
- `thigh_l=95.04px`, `shin_l=77.76px`

### 9.1 通常立ち（waist=0）

- `y_crotch = -172.8`
- `navel_y = -220.032`
- `sy = -290.88`
- `hy = -336.0`
- 頭頂 `= hy - head_h/2 = -360.0`（地面0から約360px = 180cm相当）

### 9.2 最大ストレス立ち（非歩行, `stress=100`）

- `waist_angle = 0.20rad`
- 側面の頭頂: 約 `-357.45px`
- 正面の頭頂: 約 `-357.81px`

=> 通常立ちより約2px低く見える（軽い猫背）。

### 9.3 しゃがみ中間（例: `t=1.0`）

- `waist_angle=1.3rad`
- `knee=PI*0.28`
- `y_crotch ≈ -149.29`
- 頭頂（側面）`≈ -241.91px`（約121cm相当）

### 9.4 深い屈み（例: `t=2.0`）

- `waist_angle=1.3rad`（上限固定）
- `knee=PI*0.7`
- `y_crotch ≈ -53.39`
- 頭頂（側面）`≈ -146.01px`（約73cm相当）

## 10. 注意点（実装依存）

- しゃがみ解の評価関数 `_eval_crouch_height()` は「足先厚み」などを簡略化しているため、`visual_height_cm * p` と描画上の頭頂高さは厳密一致しないフレームがある。
- ただし、二分探索で高さを追従し、`SkeletalPlayer` 側の補間により視覚的には連続的に変化する設計。
