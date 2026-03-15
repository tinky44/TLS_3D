# plan_by_agent.md — AIエージェントのメモ帳

更新日: 2026-03-15

---

## chair_sit 改善設計：椅子高さ依存の座りシステム

### 問題の整理

現在の `chair_sit` は `y_crotch = -shin_l`（すねの長さ固定）で計算している。
実際には以下が必要：

1. **椅子高さへの追従** ─ 尻（股関節）の位置 = 椅子の座面高さ
2. **足の床 IK** ─ すねの長さと座面高さから、膝の曲げ角を自動計算
3. **机の制約** ─ 机がある場合に膝が机より上に来ないよう脚を伸ばす

---

### 幾何学的根拠

```
座面高 H, すね長 shin_l の関係（横から見た図）

  hip (H) ───────── knee
              thigh (水平)
                       │
                       │ shin (角度 θ)
                       │
            ankle ─────┘  ← 足が床 (Y=0) にある条件

  shin_y_component = sin(θ) × shin_l = H  →  θ = asin(H / shin_l)
```

- `shin_l >= H` のとき: θ = `asin(H / shin_l)` — すねが前方に傾いて床に届く（高身長の典型）
- `shin_l < H` のとき: θ = `PI/2`（垂直）— 足が床に届かず宙に浮く（幼児が高い椅子に座る等）

---

### 実装フェーズ

#### Phase 1 ─ 座面高さの受け渡し

**目的**: 椅子インタラクション時に座面高さを player に伝える。

**追加データ（SkeletalPlayer.gd）**

```gdscript
# 座りコンテキスト（-1 = 未設定、固定値にフォールバック）
var sit_context: Dictionary = {
    "seat_h_cm": -1.0,   # 座面高さ [cm]
    "desk_h_cm": -1.0,   # 机の高さ [cm]（-1 = 机なし）
}
```

**椅子オブジェクト（StageBuilder.gd）**

```gdscript
# 椅子ノードにメタを付与
chair_node.set_meta("seat_height_cm", 40.0)   # 小学校の椅子 = 40cm
chair_node.set_meta("desk_height_cm", 60.0)   # 対応する机の高さ
```

**インタラクション時（MainScene.gd または椅子スクリプト）**

```gdscript
func _on_sit_interacted(chair_node: Node) -> void:
    player.sit_context["seat_h_cm"] = float(chair_node.get_meta("seat_height_cm", 40.0))
    player.sit_context["desk_h_cm"] = float(chair_node.get_meta("desk_height_cm", -1.0))
    player.set_pose_immediately("chair_sit")
```

**PoseCalculator の変更（CharacterPoseCalculator.gd）**

```gdscript
elif pose == "chair_sit":
    var raw_seat_h_cm: float = player.get("sit_context", {}).get("seat_h_cm", -1.0)
    var seat_h_px: float = (raw_seat_h_cm if raw_seat_h_cm > 0 else m["leg"] * 0.45) * p

    waist_angle = 0.1
    leg_l_angle = -90
    leg_r_angle = -90
    knee_l = PI * 0.5  # とりあえず垂直（Phase 2 で計算式に置き換え）
    knee_r = PI * 0.5
    arm_l_angle = -50
    arm_r_angle = -50
    y_crotch = -seat_h_px
```

---

#### Phase 2 ─ 足の床 IK（すね角度の自動計算）

**目的**: すねの長さと座面高さから `knee_l` を計算して、足を床に届かせる。

```gdscript
elif pose == "chair_sit":
    # ... (Phase 1 の y_crotch, waist_angle, leg_angle は同じ)

    # すね IK
    var ratio: float = clampf(seat_h_px / shin_l, 0.0, 1.0)
    if ratio <= 1.0:
        # 足が床に届く: アークサインでかかとを床に合わせる
        knee_l = asin(ratio)          # 高身長ほど小さな角度（すねが前方傾斜）
    else:
        # 足が宙に浮く（座面が高すぎ or 身長が低い）
        knee_l = PI * 0.5             # すな垂直・宙ぶらりん
    knee_r = knee_l
```

**高身長への影響のイメージ**

| 身長 | shin_l | 座面 40cm | knee_l | 見え方 |
|------|--------|-----------|--------|--------|
| 150cm | 32.4cm | 40 > shin → 宙 | PI/2 | 足が浮く |
| 170cm | 36.7cm | 40 > shin → 宙 | PI/2 | ギリギリ浮く |
| 185cm | 39.9cm | 40 ≈ shin | ≈PI/2 | ほぼ垂直 |
| 200cm | 43.2cm | 40 < shin | asin(40/43.2)≈68° | すねが前傾 |
| 220cm | 47.5cm | 40 < shin | asin(40/47.5)≈57° | 脚が大きく前に出る |

---

#### Phase 3 ─ 机の制約（脚の前方伸ばし）

**目的**: 机がある場合に、膝が机の天板より上に来ないよう太ももを前傾させる。

現状の設計（`leg_l_angle = -90`、太もも水平）では：
- 膝の高さ = 座面高さ H
- 机の高さ D > H であれば膝は机より下 → 問題なし
- ただし太ももが完全水平のため、極端に長い場合は机に膝が当たる演出になる

**制約チェック式**

```gdscript
var desk_h_cm: float = player.sit_context.get("desk_h_cm", -1.0)
if desk_h_cm > 0.0:
    var knee_h_px = seat_h_px  # 太もも水平の場合、膝高さ = 座面高さ
    var desk_h_px = desk_h_cm * p
    if knee_h_px > desk_h_px:
        # 膝が机より上: 太ももを下げ気味にして膝を机の下に収める
        # Δangle = asin((knee_h_px - desk_h_px) / thigh_l)
        var delta = asin(clampf((knee_h_px - desk_h_px) / thigh_l, 0.0, 0.9))
        leg_l_angle = -90 + rad_to_deg(delta)  # 太ももを少し下向きに
        leg_r_angle = leg_l_angle
        # 連動: y_crotch も再調整が必要
```

---

### 変更ファイルまとめ

| ファイル | 変更内容 |
|---|---|
| `SkeletalPlayer.gd` | `sit_context` 辞書を追加 |
| `StageBuilder.gd` | 椅子ノードに `seat_height_cm`・`desk_height_cm` メタ付与 |
| `MainScene.gd` | インタラクション時に `sit_context` をセット |
| `CharacterPoseCalculator.gd` | `chair_sit` ブランチで Phase 1→2→3 の計算を使用 |

---

### 実装順

| Phase | 内容 | 難度 | 対応 issue |
|---|---|---|---|
| **1** | 座面高さの受け渡し（`sit_context` + メタ） | 小 | #58 |
| **2** | すね IK（`asin` でかかとを床に合わせる） | 小 | #58 |
| **3** | 机の制約（太もも前傾・膝を机下に収める） | 中 | #58 |

Phase 1・2 は独立して着手可能。Phase 3 は机オブジェクトのメタ設計が前提。
