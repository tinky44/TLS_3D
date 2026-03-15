extends Control

func _ready() -> void:
    if _maybe_start_codex_smoke():
        return

    var bg = ColorRect.new()
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.color = Color("#2b2b2b")
    add_child(bg)

    var center = CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 40)
    center.add_child(vbox)
    
    var title_label = Label.new()
    title_label.text = "Tall Life Simulator"
    title_label.add_theme_font_size_override("font_size", 64)
    title_label.add_theme_color_override("font_color", Color("#ffffff"))
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title_label)
    
    var start_btn = Button.new()
    start_btn.text = "Start"
    start_btn.custom_minimum_size = Vector2(200, 60)
    start_btn.add_theme_font_size_override("font_size", 32)
    start_btn.focus_mode = Control.FOCUS_NONE
    start_btn.pressed.connect(_on_start_pressed)
    vbox.add_child(start_btn)
    
    var continue_btn = Button.new()
    continue_btn.text = "続きから"
    continue_btn.custom_minimum_size = Vector2(200, 60)
    continue_btn.add_theme_font_size_override("font_size", 32)
    continue_btn.focus_mode = Control.FOCUS_NONE
    continue_btn.pressed.connect(_on_continue_pressed)
    vbox.add_child(continue_btn)

    var exit_btn = Button.new()
    exit_btn.text = "Exit"
    exit_btn.custom_minimum_size = Vector2(200, 60)
    exit_btn.add_theme_font_size_override("font_size", 32)
    exit_btn.focus_mode = Control.FOCUS_NONE
    exit_btn.pressed.connect(_on_exit_pressed)
    vbox.add_child(exit_btn)

func _on_start_pressed() -> void:
    var global = get_node_or_null("/root/Global")
    if global:
        global.slot_select_mode = "save"
    get_tree().change_scene_to_file("res://scenes/CharacterCreatorScene.tscn")

func _on_continue_pressed() -> void:
    var global = get_node_or_null("/root/Global")
    if global:
        global.slot_select_mode = "load"
    get_tree().change_scene_to_file("res://scenes/SaveSlotSelectScene.tscn")

func _on_exit_pressed() -> void:
    if OS.has_feature("web"):
        JavaScriptBridge.eval("window.location.replace(new URL('./', window.location.href).toString());")
    else:
        get_tree().quit()

func _maybe_start_codex_smoke() -> bool:
    for arg in OS.get_cmdline_user_args():
        if arg == "--codex-smoke":
            call_deferred("_start_codex_smoke")
            return true
    return false

func _start_codex_smoke() -> void:
    get_tree().change_scene_to_file("res://scenes/CodexSmokeRunner.tscn")
