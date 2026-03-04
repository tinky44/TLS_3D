extends Node2D

# const STAGES = ["room", "train", "outdoor", "school"]
var p: float = 2.0

@onready var player: Node = $Player

# UI用
var ui_layer: CanvasLayer
var status_label: Label
var bubble_panel: PanelContainer
var bubble_label: Label

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
    _setup_bubble()
    _load_stage()

func _setup_bubble():
    bubble_panel = PanelContainer.new()
    var style = StyleBoxFlat.new()
    style.bg_color = Color(1.0, 1.0, 1.0, 0.5)
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color(0.2, 0.2, 0.2, 0.5)
    style.corner_radius_top_left = 12
    style.corner_radius_top_right = 12
    style.corner_radius_bottom_right = 12
    style.corner_radius_bottom_left = 12
    style.content_margin_left = 16
    style.content_margin_right = 16
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    bubble_panel.add_theme_stylebox_override("panel", style)
    
    bubble_label = Label.new()
    bubble_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
    bubble_label.add_theme_font_size_override("font_size", 14)
    # 改行対応
    bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    bubble_label.custom_minimum_size = Vector2(200, 0)
    
    bubble_panel.add_child(bubble_label)
    add_child(bubble_panel)
    bubble_panel.hide()


func _process(_delta: float) -> void:
    _update_ui()
    _update_bubble()
    
func _update_bubble():
    if not player or not bubble_panel: return
    
    var m = player.get("m")
    if not m: return
    
    var px = player.global_position.x / p
    var hit_dist = 60.0 # 60cm以内に近づいたら表示
    var closest_obs: Node2D = null
    var min_dist = INF
    
    for child in get_children():
        if child.has_meta("is_stage_obj") and child.has_meta("obs_x"):
            # AABBチェックのようなもの。
            var ox1 = float(child.get_meta("obs_x"))
            var ox2 = float(child.get_meta("obs_x2"))
            var dist = 0.0
            if px < ox1: dist = ox1 - px
            elif px > ox2: dist = px - ox2
            
            if dist < hit_dist and dist < min_dist:
                min_dist = dist
                closest_obs = child
                
    if closest_obs:
        var obs_id = closest_obs.get_meta("obs_id")
        var oh = closest_obs.get_meta("obs_height_cm")
        var h = m["height"]
        
        bubble_label.text = StageBuilder.get_obstacle_comment(obs_id, h, oh)
        bubble_panel.show()
        
        # プレイヤーの少し上、画面から見切れない位置にパネルを配置
        var offset_y = player.visual_height_cm * p + 80
        bubble_panel.global_position = player.global_position + Vector2(-bubble_panel.size.x / 2.0, -offset_y)
    else:
        bubble_panel.hide()
    
    pass

func _setup_ui():
    ui_layer = CanvasLayer.new()
    
    # サイドバー全体を覆うパネル
    var sidebar = PanelContainer.new()
    sidebar.set_anchors_preset(Control.PRESET_LEFT_WIDE)
    sidebar.custom_minimum_size = Vector2(320, 0)
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color("#f8f9fa") # 明るい背景
    style.border_width_right = 2
    style.border_color = Color("#dee2e6")
    sidebar.add_theme_stylebox_override("panel", style)
    
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_bottom", 20)
    sidebar.add_child(margin)
    
    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 20)
    margin.add_child(vbox)
    
    status_label = Label.new()
    status_label.add_theme_color_override("font_color", Color("#212529"))
    status_label.add_theme_font_size_override("font_size", 16)
    vbox.add_child(status_label)
    
    # 線のセパレータ
    var sep = HSeparator.new()
    vbox.add_child(sep)
    
    # ステージ選択画面に戻るボタンなどを追加
    var back_btn = Button.new()
    back_btn.text = "ステージ選択に戻る"
    back_btn.custom_minimum_size = Vector2(0, 50)
    back_btn.add_theme_font_size_override("font_size", 16)
    back_btn.focus_mode = Control.FOCUS_NONE
    back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/StageSelectScene.tscn"))
    vbox.add_child(back_btn)

    ui_layer.add_child(sidebar)
    add_child(ui_layer)


func _update_ui():
    if not player or not status_label: return
    
    var global = get_node_or_null("/root/Global")
    var stage_id = global.current_stage_id if global else "room"
    var stage_name = StageBuilder.STAGES[stage_id]["name"] if StageBuilder.STAGES.has(stage_id) else "Unknown"
    var m = player.get("m")
    if not m: return
    
    var params = global.current_params if global else m
    
    var text = "【基本情報】\n"
    text += "Stage: %s\n" % stage_name
    text += "身長: %.1f cm  頭身: %.1f  股下: %.1f%%\n" % [params["height"], params["ratio"], params["legRatio"]]
    text += "Pose: %s ([1]-[5], [S]キー)\n" % player.pose
    if player.pose == "crouch":
        text += "  ↳ 目標高さ: %.1f cm\n" % player.target_crouch_cm
    
    text += "\n【操作方法】\n"
    text += "矢印キー左右: 移動\n"
    text += "矢印キー下: 正面向き\n"
    text += "矢印キー上: 後ろ向き\n"
    
    status_label.text = text

func _load_stage():
    var global = get_node_or_null("/root/Global")
    var stage_id = global.current_stage_id if global else "room"
    
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
                # キャラクターの身長の40〜50%あたり（腰〜胸付近）を中心にする
                # X軸に -160 を指定し、キャラクターを画面右側に寄せる（左側のUI領域を確保）
                cam.offset = Vector2(-160, -m["height"] * p * 0.4)
            # 地面は y=50 のため、足元＋少しの余白だけ映るように余裕を持たせる
            cam.limit_bottom = 250
