extends Control

const COLS = 4
const SLOT_W = 220
const SLOT_H = 100
const GAP = 12

var global: Node

func _ready() -> void:
    global = get_node_or_null("/root/Global")
    _build_ui()

func _build_ui() -> void:
    var is_load = global and global.slot_select_mode == "load"

    var bg = ColorRect.new()
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.color = Color("#1e1e2e")
    add_child(bg)

    var vbox = VBoxContainer.new()
    vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
    vbox.add_theme_constant_override("separation", 16)
    vbox.offset_left = 40
    vbox.offset_right = -40
    vbox.offset_top = 30
    vbox.offset_bottom = -30
    add_child(vbox)

    var title = Label.new()
    title.text = "データをロード" if is_load else "セーブスロットを選択"
    title.add_theme_font_size_override("font_size", 36)
    title.add_theme_color_override("font_color", Color("#ffffff"))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title)

    var scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(scroll)

    var grid = GridContainer.new()
    grid.columns = COLS
    grid.add_theme_constant_override("h_separation", GAP)
    grid.add_theme_constant_override("v_separation", GAP)
    scroll.add_child(grid)

    for i in range(1, Global.SLOT_COUNT + 1):
        var info = global.get_slot_info(i) if global else {}
        var is_empty = info.is_empty()

        var panel = PanelContainer.new()
        panel.custom_minimum_size = Vector2(SLOT_W, SLOT_H)

        var style = StyleBoxFlat.new()
        if is_empty:
            style.bg_color = Color("#2a2a3e") if not is_load else Color("#1a1a2a")
        else:
            style.bg_color = Color("#2d4a6e")
        style.border_width_left = 2
        style.border_width_top = 2
        style.border_width_right = 2
        style.border_width_bottom = 2
        style.border_color = Color("#555577") if is_empty else Color("#6699cc")
        style.corner_radius_top_left = 8
        style.corner_radius_top_right = 8
        style.corner_radius_bottom_right = 8
        style.corner_radius_bottom_left = 8
        panel.add_theme_stylebox_override("panel", style)

        var margin = MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 10)
        margin.add_theme_constant_override("margin_top", 8)
        margin.add_theme_constant_override("margin_right", 10)
        margin.add_theme_constant_override("margin_bottom", 8)
        panel.add_child(margin)

        var inner = VBoxContainer.new()
        inner.add_theme_constant_override("separation", 4)
        margin.add_child(inner)

        var slot_lbl = Label.new()
        slot_lbl.text = "SLOT %02d" % i
        slot_lbl.add_theme_font_size_override("font_size", 12)
        slot_lbl.add_theme_color_override("font_color", Color("#aaaacc"))
        inner.add_child(slot_lbl)

        if is_empty:
            var empty_lbl = Label.new()
            empty_lbl.text = "（空）"
            empty_lbl.add_theme_font_size_override("font_size", 16)
            empty_lbl.add_theme_color_override("font_color", Color("#555566"))
            inner.add_child(empty_lbl)
        else:
            var stage_name = StageBuilder.STAGES.get(info["stage_id"], {}).get("name", info["stage_id"])
            var data_lbl = Label.new()
            data_lbl.text = "%.0fcm  %s" % [info["height"], stage_name]
            data_lbl.add_theme_font_size_override("font_size", 16)
            data_lbl.add_theme_color_override("font_color", Color("#ffffff"))
            inner.add_child(data_lbl)

            var ts = info.get("timestamp", "")
            if ts != "":
                ts = ts.replace("T", " ").substr(0, 16)
            var ts_lbl = Label.new()
            ts_lbl.text = ts
            ts_lbl.add_theme_font_size_override("font_size", 11)
            ts_lbl.add_theme_color_override("font_color", Color("#8899aa"))
            inner.add_child(ts_lbl)

        # クリック可否
        var clickable = (not is_load) or (not is_empty)
        if clickable:
            var btn = Button.new()
            btn.flat = true
            btn.set_anchors_preset(Control.PRESET_FULL_RECT)
            btn.focus_mode = Control.FOCUS_NONE
            btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
            # 透明スタイル
            var btn_style = StyleBoxEmpty.new()
            btn.add_theme_stylebox_override("normal", btn_style)
            btn.add_theme_stylebox_override("hover", btn_style)
            btn.add_theme_stylebox_override("pressed", btn_style)
            btn.pressed.connect(_on_slot_pressed.bind(i))
            panel.add_child(btn)

            # ホバー強調
            var hover_style = style.duplicate()
            hover_style.border_color = Color("#ffffff") if not is_load else Color("#88ddff")
            btn.mouse_entered.connect(func():
                panel.add_theme_stylebox_override("panel", hover_style))
            btn.mouse_exited.connect(func():
                panel.add_theme_stylebox_override("panel", style))
        else:
            panel.modulate = Color(1, 1, 1, 0.35)

        grid.add_child(panel)

    # 戻るボタン
    var back_btn = Button.new()
    back_btn.text = "タイトルに戻る"
    back_btn.custom_minimum_size = Vector2(200, 50)
    back_btn.add_theme_font_size_override("font_size", 18)
    back_btn.focus_mode = Control.FOCUS_NONE
    back_btn.pressed.connect(_on_back_pressed)
    vbox.add_child(back_btn)

func _on_slot_pressed(slot: int) -> void:
    if not global: return
    if global.slot_select_mode == "save":
        global.save_slot(slot)
        # 新規ゲーム開始時は導入シーンへ
        get_tree().change_scene_to_file("res://scenes/IntroScene.tscn")
    else:
        if global.load_slot(slot):
            get_tree().change_scene_to_file("res://Main.tscn")

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")
