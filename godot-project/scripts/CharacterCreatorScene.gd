extends Node2D

@onready var player = $Player

func _ready() -> void:
    _setup_ui()
    # プレビューが見えやすいように初期ポーズを調整（必要なら）
    if player and player.has_method("update_measurements"):
        player.pose = "stand"
        player.update_measurements()

func _setup_ui():
    var ui_layer = CanvasLayer.new()
    
    var sidebar = PanelContainer.new()
    sidebar.set_anchors_preset(Control.PRESET_LEFT_WIDE)
    sidebar.custom_minimum_size = Vector2(400, 0)
    
    var style = StyleBoxFlat.new()
    style.bg_color = Color("#f8f9fa")
    style.border_width_right = 2
    style.border_color = Color("#dee2e6")
    sidebar.add_theme_stylebox_override("panel", style)
    
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 30)
    margin.add_theme_constant_override("margin_top", 40)
    margin.add_theme_constant_override("margin_right", 30)
    margin.add_theme_constant_override("margin_bottom", 40)
    sidebar.add_child(margin)
    
    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 30)
    margin.add_child(vbox)
    
    var title = Label.new()
    title.text = "キャラクター作成プレビュー"
    title.add_theme_color_override("font_color", Color("#212529"))
    title.add_theme_font_size_override("font_size", 24)
    vbox.add_child(title)
    
    var sep = HSeparator.new()
    vbox.add_child(sep)
    
    _build_sliders(vbox)
    
    var sep2 = HSeparator.new()
    vbox.add_child(sep2)
    
    var next_btn = Button.new()
    next_btn.text = "次へ (ステージ選択)"
    next_btn.custom_minimum_size = Vector2(0, 60)
    next_btn.add_theme_font_size_override("font_size", 20)
    next_btn.focus_mode = Control.FOCUS_NONE
    next_btn.pressed.connect(_on_next_pressed)
    vbox.add_child(next_btn)
    
    var back_btn = Button.new()
    back_btn.text = "タイトルに戻る"
    back_btn.custom_minimum_size = Vector2(0, 50)
    back_btn.add_theme_font_size_override("font_size", 18)
    back_btn.focus_mode = Control.FOCUS_NONE
    back_btn.pressed.connect(_on_back_pressed)
    vbox.add_child(back_btn)

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

func _on_next_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/StageSelectScene.tscn")

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")
