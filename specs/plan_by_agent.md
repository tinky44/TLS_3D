# plan_by_agent.md — AI 作業メモ

> 最終更新: 2026-03-13

---

## 今回のスコープ

**アニメーション・屈みシステムのバグ修正と改善**
issue #36, #35, #40, spec.local.md のバグ一覧に基づく。

---

## 課題の優先順位

| 優先度 | 課題 | issue | 種別 |
|--------|------|-------|------|
| 🔴 高 | 屈み時スカート上端がベルト位置からずれる | #36 / spec | bug |
| 🔴 高 | 側面サスペンダーが屈んだとき位置ずれする | spec | bug |
| 🟡 中 | 背面セーラー服が正面と同じになっている | spec | bug |
| 🟡 中 | 屈み時スカート裾が膝を突き抜ける | #36 / spec | 改善 |
| 🟢 低 | 猫背機能（感情連動） | #35 | 新機能 |
| 🟢 低 | 高身長アニメーション全般改善 | #40 | 改善 |

---

## バグ詳細と実装案

---

### Bug-1: 屈み時スカート上端がベルト位置からずれる

**原因（コード解析済み）**

`CharacterBodyDrawer.gd` の `draw_skirt` 内、ジャンパースカート正面処理：

```gdscript
# 現在の実装（問題あり）
waist_pos.y = d["front_sy"] + u_arm
```

`front_sy`（肩のY座標）に固定の `u_arm`（上腕長）を加算しているだけ。
屈んだとき胴体が前傾するが、正面ビューではその傾きが反映されない。

**修正案**

正面ビューでも胴体傾きを考慮してウエスト位置を計算する。
PoseCalculator がすでに `front_hip_y` を計算しているので活用できる。

ただし `front_hip_y` は骨盤中心位置なので、
ジャンパースカートの場合「上腕終端（ベルト位置）」に合わせる必要がある。

```gdscript
# 修正案: 肩から「胴体方向に u_arm だけ進んだ点」をベルト位置とする
var torso_front_dir = Vector2(0, 1)  # 正面ビューでは常に下向き（= 腰傾きの Y 成分のみ）

# 屈み量に応じて傾き補正を入れる
var waist_angle = d.get("waist_angle", 0.0)
var waist_lean_px = u_arm * sin(waist_angle) * 0.25  # 前傾で前方向にシフト

waist_pos = Vector2(d["front_sx"] + waist_lean_px, d["front_sy"] + u_arm * cos(waist_angle * 0.25))
```

**注意点**
- cos(0) = 1 なので通常立ちでは変化なし
- `front_sx` は正面ビューで body center X

---

### Bug-2: 側面サスペンダーが屈んだとき位置ずれ

**原因**

`CharacterClothingDrawer.gd` の `draw_suspenderSkirt_side` では
ストラップ下端を以下で計算：

```gdscript
var p_front_bot = p_sh_front + torso_down + torso_dir * 10.0
```

`draw_skirt` のスカート上端は：

```gdscript
var torso_vec = Vector2(d["navel_x"] - s_x, d["navel_y"] - s_y)
var torso_dir = torso_vec.normalized()
waist_pos = Vector2(s_x, s_y) + torso_dir * u_arm
```

両者が同じ `s_x, s_y`（肩位置）と同じ `u_arm` を基準にしているように見えるが、
`torso_down` の定義と `u_arm` の倍率が一致していない可能性が高い。

**修正案**

スカートのウエスト位置計算ロジックを関数化し、
サスペンダーもその関数を呼び出す形にする。

```gdscript
# CharacterBodyDrawer.gd に追加
static func _get_jumper_waist_pos(d: Dictionary, ctx, is_side: bool) -> Vector2:
    var p = ctx.p
    var u_arm = ctx.m["armLength"] * p * 0.5 + 10.0
    if is_side:
        var s_x = d["shoulder_x"]
        var s_y = d["shoulder_y"]
        var torso_vec = Vector2(d["navel_x"] - s_x, d["navel_y"] - s_y)
        return Vector2(s_x, s_y) + torso_vec.normalized() * u_arm
    else:
        # 正面: Bug-1 の修正案を適用
        var waist_angle = d.get("waist_angle", 0.0)
        return Vector2(d["front_sx"], d["front_sy"] + u_arm * cos(waist_angle * 0.25))
```

`draw_suspenderSkirt_side` 側で `draw_skirt` と同じ関数を呼ぶことで一致を保証。

---

### Bug-3: 背面セーラー服が正面と同じ

**調査が必要な箇所**

```
CharacterClothingDrawer.gd の draw_sailor 系関数
```

- セーラー服の衿（えり）描画が `direction == "back"` の場合に分岐しているかを確認
- 背面の衿は「V字が逆になる」「白い大きな正方形布」が背中に来るはず

**実装案**

1. `draw_sailor_front/back` の分岐ロジックを確認
2. `direction == "back"` のとき：
   - 前側の V字衿は描画しない
   - 背中に大きな白い四角（sailor flap）を追加描画する

```gdscript
if direction == "back":
    # セーラー背面の大きな四角い布
    var flap_top_y = shoulder_y + 5.0
    var flap_bot_y = shoulder_y + torso_h * 0.45
    var flap_w = body_w * 0.85
    draw.draw_rect_part(cx, flap_top_y, flap_w, flap_bot_y - flap_top_y, sailor_white)
    # 下端は三角形に
    ...
```

---

### 改善-1: 屈み時スカート裾の膝考慮計算

**現状の問題**

側面スカートは台形の頂点数が固定で、膝が前に突き出るとスカートを突き抜ける。

**段階的実装案**

**フェーズ1（今会話でも着手可能）**: 裾の広がり下限を膝X位置に合わせる

現在の実装では `side_hem_w` が膝スプレッドから計算されているが、
膝の突き出し方向（前方向）が考慮されていない。

```gdscript
# 膝の「前方向」への突き出し量を計算
var knee_fwd = max(knee_l_x - p_bottom.x, 0.0)  # 前に出た膝
var fwd_margin = knee_fwd * 1.2  # 20% マージン付き

# 裾の前端を膝前に合わせる
p_bottom_front = Vector2(p_bottom.x + fwd_margin, p_bottom.y)
```

**フェーズ2（後の会話）**: Verlet 物理シミュレーション
- 裾の点群を verlet 粒子として管理
- 重力 + 脚との衝突判定
- `SkeletalPlayer.gd` に物理ステップを追加

---

### 新機能: 猫背機能（感情連動）

**設計案**

`CharacterPoseCalculator.gd` に `cat_back_factor: float` (0.0〜1.0) パラメータを追加。

```gdscript
# 猫背 = 上体の waist_angle と反対方向に spine を曲げる
# 首が前に出て、肩が落ちる表現

var spine_curve = cat_back_factor * 0.4  # 最大 0.4rad（約23度）

# 首を前傾させる
var neck_lean = cat_back_factor * 0.3

# 肩を下げる（腕の取り付け位置を lower に）
var shoulder_drop = cat_back_factor * (p * 8.0)
```

`SkeletalPlayer.gd` で `stress_level` や感情変数から `cat_back_factor` を計算して渡す。

---

## 実装順序（推奨）

1. Bug-3（背面セーラー服）: 視覚的インパクト大、調査→修正
2. Bug-1（スカート上端）: 正面ビューの計算式修正のみ
3. Bug-2（サスペンダー位置）: ウエスト計算を関数化してから修正
4. 改善-1 フェーズ1（裾の膝考慮）: Bug-1/2 修正後に実施
5. 猫背機能: 新規追加（低優先）

---

## 作業ログ

- 2026-03-13: コードベース解析完了。実装案記述。
