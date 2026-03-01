extends Node2D

const STAGES = ["room", "train", "outdoor", "school"]
var current_stage_index = 0
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
    style.bg_color = Color(1.0, 1.0, 1.0, 0.9)
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
    
    # ステージ切り替え (数字キー 6, 7, 8, 9)
    # Player.tscn内で1~5はポーズ切り替えに使われているため
    if Input.is_key_pressed(KEY_6): _change_stage(0)
    elif Input.is_key_pressed(KEY_7): _change_stage(1)
    elif Input.is_key_pressed(KEY_8): _change_stage(2)
    elif Input.is_key_pressed(KEY_9): _change_stage(3)

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
    
    _build_sliders(vbox)
    
    ui_layer.add_child(sidebar)
    add_child(ui_layer)

func _build_sliders(parent_vbox: VBoxContainer):
    var global = get_node_or_null("/root/Global")
    if not global: return
    var params = global.current_params
    
    # 身長
    var h_lbl = Label.new()
    h_lbl.text = "身長 (100 - 300cm)"
    h_lbl.add_theme_color_override("font_color", Color("#495057"))
    parent_vbox.add_child(h_lbl)
    var h_slider = HSlider.new()
    h_slider.min_value = 100.0
    h_slider.max_value = 300.0
    h_slider.step = 0.5
    h_slider.value = params["height"]
    h_slider.focus_mode = Control.FOCUS_NONE
    h_slider.value_changed.connect(_on_height_changed)
    parent_vbox.add_child(h_slider)
    
    # 頭身
    var r_lbl = Label.new()
    r_lbl.text = "頭身 (5.0 - 10.0)"
    r_lbl.add_theme_color_override("font_color", Color("#495057"))
    parent_vbox.add_child(r_lbl)
    var r_slider = HSlider.new()
    r_slider.min_value = 5.0
    r_slider.max_value = 10.0
    r_slider.step = 0.1
    r_slider.value = params["ratio"]
    r_slider.focus_mode = Control.FOCUS_NONE
    r_slider.value_changed.connect(_on_ratio_changed)
    parent_vbox.add_child(r_slider)
    
    # 股下
    var l_lbl = Label.new()
    l_lbl.text = "股下比率 (30% - 60%)"
    l_lbl.add_theme_color_override("font_color", Color("#495057"))
    parent_vbox.add_child(l_lbl)
    var l_slider = HSlider.new()
    l_slider.min_value = 30.0
    l_slider.max_value = 60.0
    l_slider.step = 0.5
    l_slider.value = params["legRatio"]
    l_slider.focus_mode = Control.FOCUS_NONE
    l_slider.value_changed.connect(_on_leg_ratio_changed)
    parent_vbox.add_child(l_slider)

func _on_height_changed(val: float):
    var global = get_node_or_null("/root/Global")
    if global:
        global.current_params["height"] = val
        global.save_settings()
        if player and player.has_method("update_measurements"):
            player.update_measurements()

func _on_ratio_changed(val: float):
    var global = get_node_or_null("/root/Global")
    if global:
        global.current_params["ratio"] = val
        global.save_settings()
        if player and player.has_method("update_measurements"):
            player.update_measurements()

func _on_leg_ratio_changed(val: float):
    var global = get_node_or_null("/root/Global")
    if global:
        global.current_params["legRatio"] = val
        global.save_settings()
        if player and player.has_method("update_measurements"):
            player.update_measurements()


func _update_ui():
    if not player or not status_label: return
    
    var stage_id = STAGES[current_stage_index]
    var stage_name = StageBuilder.STAGES[stage_id]["name"]
    var m = player.get("m")
    if not m: return
    
    var global = get_node_or_null("/root/Global")
    var params = global.current_params if global else m
    
    var text = "【基本情報】\n"
    text += "Stage: %s ([6]-[9] で切替)\n" % stage_name
    text += "身長: %.1f cm  頭身: %.1f  股下: %.1f%%\n" % [params["height"], params["ratio"], params["legRatio"]]
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
                # キャラクターの身長の40〜50%あたり（腰〜胸付近）を中心にする
                # X軸に -160 を指定し、キャラクターを画面右側に寄せる（左側のUI領域を確保）
                cam.offset = Vector2(-160, -m["height"] * p * 0.4)
            # 地面は y=50 のため、足元＋少しの余白だけ映るように余裕を持たせる
            cam.limit_bottom = 250
