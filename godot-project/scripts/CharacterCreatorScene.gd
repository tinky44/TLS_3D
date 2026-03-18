extends Node2D

@onready var player = $Player
var preview_camera: Camera2D
var CM_TO_PX: float = 2.0

var h_lbl: Label
var r_lbl: Label
var l_lbl: Label
var growth_type_btns: Array = [] # [{btn, type, factor}]

func _ready() -> void:
    var global = get_node_or_null("/root/Global")
    if global:
        CM_TO_PX = global.CM_TO_PX

    _setup_camera()
    _setup_ui()
    # プレビューが見えやすいように初期ポーズを調整
    if player and player.has_method("update_measurements"):
        player.pose = "stand"
        player.facing = "front" # 初期状態を正面向きにする
        player.update_measurements()
    _update_camera()

func _setup_camera() -> void:
    # PlayerのCamera2Dを無効化 or 上書きするため、Playerの子としてカメラを追加
    # すでにPlayerに古いカメラがあれば削除
    var old_cam = player.get_node_or_null("Camera2D")
    if old_cam:
        old_cam.queue_free()

    preview_camera = Camera2D.new()
    preview_camera.name = "PreviewCamera"
    preview_camera.enabled = true
    preview_camera.position_smoothing_enabled = false
    # UIサイドバー(400px分)を考慮。画面幅の右側半分にキャラが映るようオフセット
    preview_camera.offset = Vector2(-200, 0)
    # キャラ全体が映るようzoomを調整（必要に応じてこの値を変える）
    preview_camera.zoom = Vector2(0.8, 0.8)
    player.add_child(preview_camera)

func _update_camera() -> void:
    if not preview_camera or not player: return
    var global = get_node_or_null("/root/Global")
    var height_cm = 180.0
    if global:
        height_cm = global.current_params.get("height", 180.0)
    var char_height_px = height_cm * CM_TO_PX
    # カメラのYはキャラ中心（足元から身長の半分だけ上 = キャラの胴体中間）
    # Playerの足元がY=0(PlayerローカルY)、頭がY=-char_height_pxのため
    preview_camera.position = Vector2(0, -char_height_px * 0.5)


func _process(_delta: float) -> void:
    _update_camera()

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

    # サイドバー全体を縦に分割：スクロール領域 + 固定ボタン領域
    var outer_vbox = VBoxContainer.new()
    outer_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
    sidebar.add_child(outer_vbox)

    # ─── スクロール領域（スライダー群） ───
    var scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    outer_vbox.add_child(scroll)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 30)
    margin.add_theme_constant_override("margin_top", 30)
    margin.add_theme_constant_override("margin_right", 30)
    margin.add_theme_constant_override("margin_bottom", 16)
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(margin)

    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 22)
    margin.add_child(vbox)

    var title = Label.new()
    title.text = "キャラクター作成"
    title.add_theme_color_override("font_color", Color("#212529"))
    title.add_theme_font_size_override("font_size", 22)
    vbox.add_child(title)

    vbox.add_child(HSeparator.new())

    _build_sliders(vbox)

    # ─── 固定ボタン領域（常に下部に表示） ───
    var btn_margin = MarginContainer.new()
    btn_margin.add_theme_constant_override("margin_left", 30)
    btn_margin.add_theme_constant_override("margin_right", 30)
    btn_margin.add_theme_constant_override("margin_top", 12)
    btn_margin.add_theme_constant_override("margin_bottom", 24)
    outer_vbox.add_child(btn_margin)

    var btn_vbox = VBoxContainer.new()
    btn_vbox.add_theme_constant_override("separation", 10)
    btn_margin.add_child(btn_vbox)

    btn_vbox.add_child(HSeparator.new())

    var next_btn = Button.new()
    next_btn.text = "このキャラで始める"
    next_btn.custom_minimum_size = Vector2(0, 56)
    next_btn.add_theme_font_size_override("font_size", 20)
    next_btn.focus_mode = Control.FOCUS_NONE
    next_btn.pressed.connect(_on_next_pressed)
    btn_vbox.add_child(next_btn)

    var back_btn = Button.new()
    back_btn.text = "タイトルに戻る"
    back_btn.custom_minimum_size = Vector2(0, 44)
    back_btn.add_theme_font_size_override("font_size", 16)
    back_btn.focus_mode = Control.FOCUS_NONE
    back_btn.pressed.connect(_on_back_pressed)
    btn_vbox.add_child(back_btn)

    ui_layer.add_child(sidebar)
    add_child(ui_layer)

func _build_sliders(parent_vbox: VBoxContainer):
    var global = get_node_or_null("/root/Global")
    if not global: return
    var params = global.current_params
    
    # 身長
    h_lbl = Label.new()
    h_lbl.text = "身長: %.1f cm" % params["height"]
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
    r_lbl = Label.new()
    r_lbl.text = "頭身: %.2f" % params["ratio"]
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
    l_lbl = Label.new()
    l_lbl.text = "股下比率: %.1f %%" % params["legRatio"]
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

    parent_vbox.add_child(HSeparator.new())

    # ─── 開始学年 ───
    var age_title = Label.new()
    age_title.text = "開始学年:"
    age_title.add_theme_color_override("font_color", Color("#495057"))
    parent_vbox.add_child(age_title)

    var age_box = HBoxContainer.new()
    age_box.add_theme_constant_override("separation", 6)
    parent_vbox.add_child(age_box)

    var age_group = ButtonGroup.new()
    var age_defs = [
        ["小学校入学\n(6歳)", 6],
        ["中学校入学\n(12歳)", 12],
        ["高校入学\n(15歳)", 15],
    ]
    for ad in age_defs:
        var btn = Button.new()
        btn.text = ad[0]
        btn.toggle_mode = true
        btn.button_group = age_group
        btn.button_pressed = (global.age == ad[1])
        btn.focus_mode = Control.FOCUS_NONE
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn.custom_minimum_size = Vector2(0, 60)
        var age_val: int = ad[1]
        btn.pressed.connect(func(): _on_start_age_pressed(age_val))
        age_box.add_child(btn)

    # ─── 成長タイプ ───
    var gt_title = Label.new()
    gt_title.text = "成長タイプ:"
    gt_title.add_theme_color_override("font_color", Color("#495057"))
    parent_vbox.add_child(gt_title)

    var gt_box = HBoxContainer.new()
    gt_box.add_theme_constant_override("separation", 6)
    parent_vbox.add_child(gt_box)

    var btn_group = ButtonGroup.new()
    var gt_defs = [
        ["ゆっくり", "slow", 0.5],
        ["普通", "normal", 1.0],
        ["速い", "fast", 1.5],
        ["急成長", "explosive", 2.5],
    ]
    for gt in gt_defs:
        var btn = Button.new()
        btn.text = gt[0]
        btn.toggle_mode = true
        btn.button_group = btn_group
        btn.button_pressed = (global.growth_type == gt[1])
        btn.focus_mode = Control.FOCUS_NONE
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        growth_type_btns.append({"btn": btn, "type": gt[1], "factor": gt[2]})
        gt_box.add_child(btn)
    btn_group.pressed.connect(_on_growth_type_pressed)

    parent_vbox.add_child(HSeparator.new())

    # ─── トップス（上着） ───
    var tops_title = Label.new()
    tops_title.text = "トップス:"
    tops_title.add_theme_color_override("font_color", Color("#495057"))
    parent_vbox.add_child(tops_title)

    var tops_row1 = HBoxContainer.new()
    tops_row1.add_theme_constant_override("separation", 6)
    parent_vbox.add_child(tops_row1)
    var tops_row2 = HBoxContainer.new()
    tops_row2.add_theme_constant_override("separation", 6)
    parent_vbox.add_child(tops_row2)

    var tops_group = ButtonGroup.new()
    var tops_defs = [
        ["セーラー服", "sailor", "#1a2a5e"],
        ["ジャンパースカート", "blazer", "#212840"],
        ["リボンブラウス", "blouse_bow", "#f0e8e0"],
        ["スウェッター", "sweater", "#7a9a7a"],
        ["Tシャツ", "t_shirt", "#ab82a8"],
    ]
    for i in range(tops_defs.size()):
        var td = tops_defs[i]
        var row = tops_row1 if i < 3 else tops_row2
        var tb = Button.new()
        tb.text = td[0]
        tb.toggle_mode = true
        tb.button_group = tops_group
        tb.button_pressed = (global.current_appearance.get("tops_type", "t_shirt") == td[1])
        tb.focus_mode = Control.FOCUS_NONE
        tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tb.custom_minimum_size = Vector2(0, 42)
        var t_type: String = td[1]
        var t_color: String = td[2]
        tb.pressed.connect(func(): _on_tops_type_pressed(t_type, t_color))
        row.add_child(tb)

    # ─── ボトムス（下着） ───
    var btm_title = Label.new()
    btm_title.text = "ボトムス:"
    btm_title.add_theme_color_override("font_color", Color("#495057"))
    parent_vbox.add_child(btm_title)

    var btm_box = HBoxContainer.new()
    btm_box.add_theme_constant_override("separation", 6)
    parent_vbox.add_child(btm_box)

    var btm_group = ButtonGroup.new()
    var btm_defs = [
        ["スカート", "skirt", "#3a5f8a"],
        ["ロングスカート", "skirt_long", "#3a5f8a"],
        ["セーラースカート", "skirt_sailor", "#1a2a5e"],
        ["パンツ", "pants", "#3a5f8a"],
    ]
    for bd in btm_defs:
        var bb = Button.new()
        bb.text = bd[0]
        bb.toggle_mode = true
        bb.button_group = btm_group
        bb.button_pressed = (global.current_appearance.get("bottoms_type", "pants") == bd[1])
        bb.focus_mode = Control.FOCUS_NONE
        bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bb.custom_minimum_size = Vector2(0, 42)
        var b_type: String = bd[1]
        var b_color: String = bd[2]
        bb.pressed.connect(func(): _on_bottoms_type_pressed(b_type, b_color))
        btm_box.add_child(bb)

func _on_height_changed(val: float):
    if h_lbl: h_lbl.text = "身長: %.1f cm" % val
    var global = get_node_or_null("/root/Global")
    if global:
        global.current_params["height"] = val
        global.save_settings()
        if player and player.has_method("update_measurements"):
            player.update_measurements()

func _on_ratio_changed(val: float):
    if r_lbl: r_lbl.text = "頭身: %.2f" % val
    var global = get_node_or_null("/root/Global")
    if global:
        global.current_params["ratio"] = val
        global.save_settings()
        if player and player.has_method("update_measurements"):
            player.update_measurements()

func _on_leg_ratio_changed(val: float):
    if l_lbl: l_lbl.text = "股下比率: %.1f %%" % val
    var global = get_node_or_null("/root/Global")
    if global:
        global.current_params["legRatio"] = val
        global.save_settings()
        if player and player.has_method("update_measurements"):
            player.update_measurements()

func _on_start_age_pressed(age_val: int) -> void:
    var global = get_node_or_null("/root/Global")
    if not global: return
    global.age = age_val
    global.term = preload("res://scripts/Global.gd").age_to_term(age_val)

    # 通学帽: 中学以上は外す
    global.current_appearance["hat_type"] = "school_hat" if age_val < 12 else "none"

    # 制服を学校段階に合わせて自動設定
    var uniform: Dictionary = global.get_school_uniform(age_val)
    for key in uniform.keys():
        global.current_appearance[key] = uniform[key]

    global.save_settings()
    # 画面のボタン表示やキャラクターの見た目を更新するため、シーン全体を再度リロードする
    get_tree().reload_current_scene()

func _on_growth_type_pressed(btn: BaseButton) -> void:
    var global = get_node_or_null("/root/Global")
    if not global: return
    for item in growth_type_btns:
        if item["btn"] == btn:
            global.growth_type = item["type"]
            global.growth_factor = item["factor"]
            global.save_settings()
            return

func _on_tops_type_pressed(tops_type: String, default_color: String) -> void:
    var global = get_node_or_null("/root/Global")
    if not global: return
    global.current_appearance["tops_type"] = tops_type
    # デフォルト色を設定（即時プレビューに反映）
    global.current_appearance["tops_color"] = default_color
    global.save_settings()
    if player and player.has_method("update_measurements"):
        player.update_measurements()

func _on_bottoms_type_pressed(bottoms_type: String, default_color: String) -> void:
    var global = get_node_or_null("/root/Global")
    if not global: return
    global.current_appearance["bottoms_type"] = bottoms_type
    global.current_appearance["bottoms_color"] = default_color
    global.save_settings()
    if player and player.has_method("update_measurements"):
        player.update_measurements()

func _on_next_pressed() -> void:
    var global = get_node_or_null("/root/Global")
    if global:
        # 新規ゲーム開始時に成長履歴をリセット
        global.growth_history = []
        global.prev_height = 0.0
        global.self_confidence = 0
        global.self_complex = 0
        global.stress = 0
        global.pending_term_choice = false
        global.term_hotspot_flags = {}
        global.term_memory_note = ""
        # 成長記録の開始点は、キャラ作成時点の身長をそのまま使う
        global.record_growth_history("start")
        global.visited_stages = {}
        global.experienced_events = []
        global.lock_initial_state()
        global.recorded_height = global.current_params["height"]
        global.height_measured_this_term = false
        global.bonus_growth_cm = 0.0
        global.current_stage_id = "myroom"
        global.slot_select_mode = "save"
        global.queue_event("entrance_ceremony") # 最初の入学式モノローグ
    get_tree().change_scene_to_file("res://scenes/SaveSlotSelectScene.tscn")

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")
