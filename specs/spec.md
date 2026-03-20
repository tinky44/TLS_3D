# Tall Life Simulator 3D — 技術仕様書

## 1. プロジェクト概要

### 1.1 目的
既存の2D版「Tall Life Simulator」のゲームシステム（成長、NPC、ダイアログ、ステージ等）を継承しつつ、
**Godot 4.x の3D機能を活用**して、"身長差の体感"をより直接的に伝えるゲームを構築する。

### 1.2 コアコンセプト
- **一人称視点での身長体験**: カメラの目線高さをキャラクターの身長パラメータと直結させ、
  ドア枠、天井、つり革などが「近い」「当たる」感覚を視覚的に体験できるようにする。
- **2.5D運用によるコスト抑制**: 移動は横スクロール（X軸）を基本とし、奥行き（Z軸）は限定的に使用。
  見た目は3Dだが、ゲームプレイの複雑度は2Dに近い形を維持する。
- **2D撮影モード**: Camera3Dの正投影（オルソグラフィック）で3Dシーンをレンダリングし、
  ViewportTextureを用いてUIを合成。「漫画の一コマ」のようなビジュアルを出力可能にする。

### 1.3 エンジン選定結論

| 優先順位 | エンジン | 評価 |
|---|---|---|
| **第一候補** | **Godot Engine 4.x** | 既存資産を最大限再利用可能。3D APIが2Dと近く移行がスムーズ。MITライセンス。Web書き出し可。 |
| 第二候補 | Unity 6 | 3Dツール・アセット生態系が強力。Web書き出し公式サポートあり。ライセンス閾値に注意。 |
| 第三候補 | Unreal Engine | 高品質3D表現には強いが、Web運用には不向き。 |

→ **Godot 4.x を採用**

---

## 2. アーキテクチャ

### 2.1 シーン構成（3D化後）

```
Main3D (Node3D)
├── WorldEnvironment
├── DirectionalLight3D (太陽光)
├── Stage3D (Node3D)                    ← StageBuilder3D が動的構築
│   ├── Floor (StaticBody3D + MeshInstance3D)
│   ├── Walls (StaticBody3D + MeshInstance3D)
│   ├── Ceiling (StaticBody3D + MeshInstance3D)  ← 天井のあるステージのみ
│   ├── Obstacles[] (StaticBody3D + MeshInstance3D)
│   └── Props[] (背景オブジェクト)
├── Player3D (CharacterBody3D)
│   ├── CollisionShape3D (CapsuleShape3D)
│   ├── PlayerModel (Node3D)            ← ボーン/メッシュ or 簡易プリミティブ
│   ├── FirstPersonCamera (Camera3D)    ← 一人称視点カメラ
│   ├── ThirdPersonCamera (Camera3D)    ← 三人称視点カメラ（2.5D）
│   └── RayCast3D[] (センサー群)
├── NPCs[] (CharacterBody3D)
│   ├── NPCModel (Node3D)
│   └── CollisionShape3D (CapsuleShape3D)
├── OrthoCamera (Camera3D)              ← 2D撮影モード用
└── UILayer (CanvasLayer)               ← 既存UIシステムをほぼそのまま流用
    ├── StatusSidebar
    ├── DialoguePanel
    ├── MeasurementPanel
    └── etc.
```

### 2.2 座標系の設計

| 軸 | 用途 | 備考 |
|---|---|---|
| X | 横移動（左右） | 2D版と同じ方向。1cm = 0.01ユニット（Godot標準の1m = 1ユニット） |
| Y | 高さ（上下） | 身長・天井・障害物すべてこの軸で管理 |
| Z | 奥行き | 2.5Dモードでは限定使用（NPC配置、部屋の奥行き表現） |

**スケール換算**:
- 2D版: `CM_TO_PX = 2.0` (1cm → 2px)
- 3D版: `CM_TO_UNIT = 0.01` (1cm → 0.01ユニット = Godotの1mは100cm)

### 2.3 モジュール構成

```
godot-project/
├── scripts/
│   ├── Global.gd                    ← 【流用】ほぼそのまま使用
│   ├── DialogueDatabase.gd          ← 【流用】そのまま使用
│   ├── AchievementDatabase.gd       ← 【流用】そのまま使用
│   │
│   ├── MainScene3D.gd              ← 【新規】3D版メインシーン
│   ├── StageBuilder3D.gd           ← 【新規】3Dステージ構築
│   ├── Player3D.gd                 ← 【新規】3Dプレイヤー制御
│   ├── NPC3D.gd                    ← 【新規】3D NPC制御
│   ├── CameraController.gd         ← 【新規】視点切替・カメラ制御
│   ├── CharacterModel3D.gd         ← 【新規】3Dキャラクターモデル管理
│   ├── BodyProportionMapper.gd     ← 【新規】身体パラメータ → 3Dボーン変換
│   │
│   ├── CharacterPoseCalculator.gd  ← 【参考】ポーズ計算ロジックの3D移植元
│   ├── CharacterBodyDrawer.gd      ← 【参考】2D描画ロジック（3Dモデル構築の参考）
│   └── ...
├── scenes/
│   ├── Main3D.tscn                 ← 【新規】3Dメインシーン
│   ├── Player3D.tscn               ← 【新規】3Dプレイヤーシーン
│   ├── NPC3D.tscn                  ← 【新規】3D NPCシーン
│   └── ...
└── project.godot                    ← 【修正】3Dレンダリング設定追加
```

---

## 3. 既存システムの流用方針

### 3.1 完全流用（変更不要）

| ファイル | 理由 |
|---|---|
| `Global.gd` | 身体パラメータ、成長システム、セーブ/ロード、NPC定義はUIレイヤーの問題。3D/2Dに依存しない。 |
| `DialogueDatabase.gd` | テキストデータのみ。表示はUIレイヤーが担当。 |
| `AchievementDatabase.gd` | データ定義のみ。 |

### 3.2 部分流用（ロジック参考、3D用に書き直し）

| モジュール | 流用する部分 | 書き直す部分 |
|---|---|---|
| `StageBuilder.gd` | `STAGES` 辞書（ステージ定義データ） | 描画部分を `MeshInstance3D` + `StaticBody3D` に置換 |
| `SkeletalPlayer.gd` | 移動ロジック、オートクラウチ判定 | `CharacterBody2D` → `CharacterBody3D`、センサーを `RayCast3D` に |
| `SkeletalNPC.gd` | NPC行動ロジック | 3D空間内での配置・アニメーション |
| `MainScene.gd` | UI構築、ダイアログ制御、ステージ遷移 | カメラ制御、3Dステージロード |
| `CharacterPoseCalculator.gd` | ポーズ計算数値 | 2D座標 → 3Dボーン回転に変換 |

### 3.3 新規作成

| モジュール | 概要 |
|---|---|
| `CameraController.gd` | 一人称/三人称/正投影（2D撮影）の3モード切替 |
| `StageBuilder3D.gd` | 既存の `STAGES` データを読み、3Dメッシュ+コリジョンで構築 |
| `Player3D.gd` | 3D版プレイヤー。身長連動のカメラ高さ、衝突、自動屈み |
| `CharacterModel3D.gd` | 簡易人体3Dモデル（プリミティブ合成 or glTFモデル） |
| `BodyProportionMapper.gd` | `Global.get_body_measurements()` → 3Dスケール・ボーン変換 |

---

## 4. コア機能の3D実装設計

### 4.1 一人称視点カメラ

```gdscript
# CameraController.gd（概要）
enum ViewMode { FIRST_PERSON, THIRD_PERSON, ORTHO_2D }

var current_mode: ViewMode = ViewMode.FIRST_PERSON
var eye_height_m: float = 1.60  # Global.current_params["height"] * 0.9 * CM_TO_UNIT

func update_camera_height(height_cm: float, head_ratio: float) -> void:
    # 目線の高さ = 身長 × 0.9（おおよそアイレベル）
    eye_height_m = height_cm * 0.9 * CM_TO_UNIT
    first_person_camera.position.y = eye_height_m
```

**身長体感の演出**:
- 170cmのプレイヤー → ドア枠(200cm)は余裕をもって見上げる
- 200cmのプレイヤー → ドア枠がギリギリ目線の高さ
- 240cmのプレイヤー → 天井(240cm)が頭上すれすれ、圧迫感

### 4.2 ステージの3D構築

既存の `StageBuilder.STAGES` データを3Dに変換する。

```gdscript
# StageBuilder3D.gd（概要）
# 既存データ形式:
# {"id": "door_to_outdoor", "x": 100, "x2": 180, "height": 200, "type": "overhead"}
#
# 3D変換:
# x, x2 → X軸の範囲（cm → m）
# height → Y軸の高さ（cm → m）
# type → コリジョンレイヤーとメッシュ形状の決定

static func build_stage_3d(stage_id: String, parent: Node3D) -> void:
    var data = StageBuilder.STAGES[stage_id]
    
    # 床
    _create_floor(parent, data["width"])
    
    # 天井（ある場合）
    if data.get("ceiling_height") != null:
        _create_ceiling(parent, data["width"], data["ceiling_height"])
    
    # 障害物
    for obs in data.get("obstacles", []):
        _create_obstacle_3d(parent, obs)

static func _create_obstacle_3d(parent: Node3D, obs: Dictionary) -> void:
    var x_start = float(obs["x"]) * CM_TO_UNIT
    var x_end = float(obs["x2"]) * CM_TO_UNIT
    var height = float(obs["height"]) * CM_TO_UNIT
    var width = x_end - x_start
    var depth = 0.5  # 奥行き（2.5Dなので固定値）
    
    match obs["type"]:
        "overhead":
            # 上に浮いた障害物（ドア枠、天井灯など）
            _create_overhead_obstacle(parent, obs, x_start, width, height, depth)
        "ground":
            # 地面に置かれた障害物（机、椅子など）
            _create_ground_obstacle(parent, obs, x_start, width, height, depth)
        "background":
            # 背景装飾（衝突なし）
            _create_background_prop(parent, obs, x_start, width, height, depth)
```

### 4.3 プレイヤー3D

```gdscript
# Player3D.gd（概要）
extends CharacterBody3D

var CM_TO_UNIT: float = 0.01
var visual_height_m: float = 1.80
var target_crouch_m: float = -1.0

# 移動は基本X軸のみ（2.5D）
func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= 9.8 * delta  # 重力
    
    var direction := Input.get_axis("ui_left", "ui_right")
    velocity.x = direction * speed
    velocity.z = 0  # 2.5Dモードでは奥行き移動なし
    
    _handle_auto_crouch_3d()
    move_and_slide()
```

### 4.4 「屈む（かがむ）」演出の3D強化

2D版の屈み演出を3Dでリッチにする:

| 演出要素 | 2D版 | 3D版 |
|---|---|---|
| 視覚的な圧迫 | 頭部の角度変更 | **FOV狭窄** + カメラ高さ低下 |
| カメラの揺れ | オフセットシェイク | **頭部バンプ時の3Dシェイク** |
| 移動速度低下 | `crouch_stride_ratio` | 同等のロジック |
| 呼吸音 | なし | **AudioStreamPlayer3D で息苦しさの音響** |
| 周辺視野 | なし | **ポストプロセス: ビネット効果** |

```gdscript
# 屈み中のカメラ演出
func _apply_crouch_camera_effects(crouch_ratio: float) -> void:
    # FOV狭窄（屈むほど視野が狭まる）
    var base_fov = 75.0
    var min_fov = 55.0
    first_person_camera.fov = lerp(base_fov, min_fov, 1.0 - crouch_ratio)
    
    # ビネット強度
    vignette_material.set_shader_parameter("intensity", (1.0 - crouch_ratio) * 0.6)
```

### 4.5 NPCのリアクション（3D版）

```gdscript
# NPC3D.gd
func _update_look_at_player() -> void:
    var player_eye_y = player.global_position.y + player.eye_height_m
    var my_eye_y = global_position.y + eye_height_m
    
    # 身長差による視線角
    var diff_y = player_eye_y - my_eye_y
    var dist_xz = Vector2(
        global_position.x - player.global_position.x,
        global_position.z - player.global_position.z
    ).length()
    
    # NPCの頭を回転（見上げ/見下ろし）
    var look_angle = atan2(diff_y, max(dist_xz, 0.5))
    head_bone.rotation.x = clamp(look_angle, -PI/3.0, PI/3.0)
```

### 4.6 2D撮影モード

```gdscript
# CameraController.gd
func switch_to_ortho_2d() -> void:
    current_mode = ViewMode.ORTHO_2D
    ortho_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    ortho_camera.size = player.visual_height_m * 1.5  # キャラ全体が収まるサイズ
    ortho_camera.position = Vector3(
        player.global_position.x,
        player.visual_height_m * 0.5,
        10.0  # カメラ距離
    )
    ortho_camera.look_at(player.global_position + Vector3.UP * player.visual_height_m * 0.5)
    ortho_camera.current = true
```

---

## 5. ステージデータの3D拡張

既存の `STAGES` 辞書を拡張し、3D固有のプロパティを追加する。

```gdscript
# StageBuilder3D.gd
const STAGE_3D_EXTENSIONS = {
    "room": {
        "depth": 400,  # 部屋の奥行き（cm）
        "wall_material": "wallpaper_cream",
        "floor_material": "flooring_brown",
        "lighting": "indoor_warm",
        "ambient_sound": "home_ambient",
    },
    "train": {
        "depth": 300,
        "wall_material": "train_panel",
        "floor_material": "train_floor",
        "lighting": "fluorescent",
        "ambient_sound": "train_running",
        "window_parallax": true,  # 窓の外の風景スクロール
    },
    "outdoor": {
        "depth": null,  # 屋外は無限遠
        "skybox": "daytime_sky",
        "lighting": "outdoor_sun",
        "ambient_sound": "city_ambient",
    },
    # ...
}
```

---

## 6. 開発フェーズ

### Phase 0: 基盤構築（現在のリポジトリ準備）
- [x] `TLS_3D` リポジトリの作成
- [ ] 既存コードのコピー（Global.gd, DialogueDatabase.gd, AchievementDatabase.gd）
- [ ] `project.godot` の3D設定変更（Forward+レンダラー、3D物理）

### Phase 1: 最小動作プロトタイプ
- [ ] `Main3D.tscn` / `MainScene3D.gd` の基本構造
- [ ] `Player3D.tscn` / `Player3D.gd` — CharacterBody3D + カプセル衝突
- [ ] `StageBuilder3D.gd` — 1ステージ（myroom）の3D構築
- [ ] 一人称カメラの基本実装（身長連動）
- [ ] 基本移動（左右のみ、重力あり）
- [ ] **到達目標**: 3D空間内で身長差を体感しながら歩ける

### Phase 2: ステージ完成
- [ ] 全ステージの3D化（STAGES辞書からの自動生成）
- [ ] ステージ遷移（ドアのインタラクション）
- [ ] 天井/障害物の衝突判定
- [ ] 自動屈みシステムの3D実装
- [ ] **到達目標**: 2D版と同等のステージを3Dで歩ける

### Phase 3: キャラクターモデル
- [ ] 簡易3D人体モデル（プリミティブ合成 or glTF）
- [ ] `BodyProportionMapper.gd` — 身長→モデルスケール変換
- [ ] NPCモデルの配置と基本アニメーション
- [ ] 服装の3D表現（テクスチャ or メッシュ切替）
- [ ] **到達目標**: キャラクターが3Dモデルとして表示される

### Phase 4: 演出強化
- [ ] 屈み演出（FOV変更、ビネット、音響）
- [ ] 頭部バンプ演出の3D化（カメラシェイク + 効果音）
- [ ] NPCの視線追従（見上げ/見下ろし）
- [ ] 三人称カメラ（2.5Dビュー）
- [ ] 2D撮影モード（正投影カメラ）
- [ ] **到達目標**: 身長差の体験が演出込みで完成

### Phase 5: UIとゲームループ統合
- [ ] 既存UI（ダイアログ、ステータス、測定パネル等）の接続
- [ ] 成長・学期進行システムの動作確認
- [ ] セーブ/ロードの動作確認
- [ ] Web書き出しテスト
- [ ] **到達目標**: ゲームとしてプレイ可能な状態

### Phase 6: ポリッシュ
- [ ] マテリアル・テクスチャの品質向上
- [ ] ライティング調整
- [ ] パフォーマンス最適化（LOD、カリング）
- [ ] 効果音・BGM
- [ ] **到達目標**: リリース品質

---

## 7. 技術的な注意点

### 7.1 パフォーマンス（Web ターゲット）
- メッシュ数は最小限に抑える（ステージはプリミティブ合成主体）
- テクスチャは軽量フォーマット（WebP/ASTC）
- 影の品質を段階的に調整可能にする
- Forward+レンダラーを使用（Godot 4.xのWebサポート）

### 7.2 既存データとの互換性
- `Global.gd` のセーブデータ形式は変更しない
- `CM_TO_PX` → `CM_TO_UNIT` の換算はクラス内に閉じる
- 2D版と3D版は `project.godot` レベルで別プロジェクトとして管理

### 7.3 移行のリスク管理
- 既存の2D版は `tall_life_simulator` リポジトリで維持
- 3D版は `TLS_3D` リポジトリで独立開発
- 共有ロジック（Global, DialogueDatabase等）は定期的に同期

---

## 8. 補足: 既存2Dシステムの主要クラス（参照）

| クラス | 行数 | 役割 | 3D版での扱い |
|---|---|---|---|
| `Global.gd` | ~934行 | ゲーム状態管理（パラメータ、成長、セーブ） | **そのまま流用** |
| `MainScene.gd` | ~4142行 | メインゲームループ、UI、ダイアログ制御 | ロジック参考に `MainScene3D.gd` 新規作成 |
| `StageBuilder.gd` | ~4206行 | ステージデータ定義と2D描画 | データ流用、描画を3Dに |
| `SkeletalPlayer.gd` | ~442行 | プレイヤー移動、オートクラウチ、衝突 | ロジック移植 `Player3D.gd` |
| `SkeletalNPC.gd` | ~18184B | NPC行動制御 | ロジック移植 `NPC3D.gd` |
| `CharacterPoseCalculator.gd` | ~11402B | ポーズの数値計算 | 3Dボーン回転に変換 |
| `CharacterBodyDrawer.gd` | ~31213B | 2D人体描画 | 3Dモデルに置換 |
| `DialogueDatabase.gd` | ~27465B | ダイアログテキスト | **そのまま流用** |
| `AchievementDatabase.gd` | ~4193B | 実績定義 | **そのまま流用** |

---

*最終更新: 2026-03-20*
*Co-Authored-By: gemini <218195315+gemini-cli@users.noreply.github.com>*
