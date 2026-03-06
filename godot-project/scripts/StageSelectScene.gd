extends Control

func _ready() -> void:
    var bg = ColorRect.new()
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.color = Color("#2b2b2b")
    add_child(bg)

    var center = CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 30)
    center.add_child(vbox)
    
    var title_label = Label.new()
    title_label.text = "ステージセレクト"
    title_label.add_theme_font_size_override("font_size", 48)
    title_label.add_theme_color_override("font_color", Color("#ffffff"))
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title_label)
    
    var home_btn = Button.new()
    home_btn.text = "家 (Room)"
    home_btn.custom_minimum_size = Vector2(300, 80)
    home_btn.add_theme_font_size_override("font_size", 32)
    home_btn.focus_mode = Control.FOCUS_NONE
    home_btn.pressed.connect(_on_stage_selected.bind("room"))
    vbox.add_child(home_btn)
    
    # 将来用のダミーボタン（今は無効化するか、表示だけしておく）
    var school_btn = Button.new()
    school_btn.text = "学校 (Comming Soon...)"
    school_btn.custom_minimum_size = Vector2(300, 80)
    school_btn.add_theme_font_size_override("font_size", 24)
    school_btn.disabled = true
    school_btn.focus_mode = Control.FOCUS_NONE
    vbox.add_child(school_btn)

    var back_btn = Button.new()
    back_btn.text = "戻る"
    back_btn.custom_minimum_size = Vector2(300, 60)
    back_btn.add_theme_font_size_override("font_size", 24)
    back_btn.focus_mode = Control.FOCUS_NONE
    back_btn.pressed.connect(_on_back_pressed)
    vbox.add_child(back_btn)

func _on_stage_selected(stage_id: String) -> void:
    var global = get_node_or_null("/root/Global")
    if global:
        global.current_stage_id = stage_id
    get_tree().change_scene_to_file("res://Main.tscn")

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/CharacterCreatorScene.tscn")
