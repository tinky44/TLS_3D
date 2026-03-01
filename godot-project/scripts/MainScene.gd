extends Node2D

const STAGES = ["room", "train", "outdoor", "school"]
var current_stage_index = 0
var p: float = 2.0

@onready var player: Node = $Player

# UI用
var ui_layer: CanvasLayer
var status_label: Label

func _ready() -> void:
    # 既存のテスト用古いノード群があれば削除
    if has_node("Floor"): get_node("Floor").queue_free()
    if has_node("ObstacleHigh"): get_node("ObstacleHigh").queue_free()
    if has_node("ObstacleLow"): get_node("ObstacleLow").queue_free()
    
    # Globalスケール取得
    var global = get_node_or_null("/root/Global")
    if global:
        p = global.CM_TO_PX
        
    _setup_ui()
    _load_stage()

func _process(_delta: float) -> void:
    _update_ui()
    
    # ステージ切り替え (数字キー 6, 7, 8, 9)
    # Player.tscn内で1~5はポーズ切り替えに使われているため
    if Input.is_key_pressed(KEY_6): _change_stage(0)
    elif Input.is_key_pressed(KEY_7): _change_stage(1)
    elif Input.is_key_pressed(KEY_8): _change_stage(2)
    elif Input.is_key_pressed(KEY_9): _change_stage(3)

func _setup_ui():
    ui_layer = CanvasLayer.new()
    status_label = Label.new()
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0.5)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    
    status_label.add_theme_stylebox_override("normal", style)
    status_label.position = Vector2(20, 20)
    status_label.add_theme_font_size_override("font_size", 16)
    
    ui_layer.add_child(status_label)
    add_child(ui_layer)

func _update_ui():
    if not player or not status_label: return
    
    var stage_id = STAGES[current_stage_index]
    var stage_name = StageBuilder.STAGES[stage_id]["name"]
    var m = player.get("m")
    if not m: return
    
    var text = "【基本情報】\n"
    text += "Stage: %s ([6]-[9] で切替)\n" % stage_name
    text += "身長: %.1f cm\n" % m["height"]
    text += "Pose: %s ([1]-[5], [S]キー)\n" % player.pose
    if player.pose == "crouch":
        text += "  ↳ 目標高さ: %.1f cm\n" % player.target_crouch_cm
    
    text += "\n【操作方法】\n"
    text += "矢印キー左右: 移動\n"
    text += "矢印キー下: 正面向き\n"
    text += "矢印キー上: 後ろ向き\n"
    
    status_label.text = text

func _change_stage(index: int):
    if current_stage_index == index:
        return
    current_stage_index = index
    _load_stage()

func _load_stage():
    var stage_id = STAGES[current_stage_index]
    
    # 床や障害物を生成
    StageBuilder.build_stage(stage_id, self , p)
    
    # プレイヤーの初期位置をリセット
    if player:
        # 少し上に配置して落とす
        player.position = Vector2(100 * p, 0)
        
        # --- カメラの調整 ---
        var cam = player.get_node_or_null("Camera2D")
        if cam:
            var m = player.get("m")
            if m and m.has("height"):
                # キャラクターの身長の60%くらいをオフセットにして、胸〜顔あたりを中心にする
                cam.offset = Vector2(0, -m["height"] * p * 0.6)
            # 地面は y=50 あたりのため、画面下部にそこまで余白が必要ない
            # (limit_bottom を小さくすることで見えすぎを防ぐ)
            cam.limit_bottom = 200
