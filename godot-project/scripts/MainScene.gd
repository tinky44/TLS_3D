extends Node2D

# const STAGES = ["room", "train", "outdoor", "school"]
var p: float = 2.0

@onready var player: Node = $Player

# UI用
var ui_layer: CanvasLayer
var sidebar: PanelContainer # Qキーでトグル表示するステータスサイドバー
var status_label: Label
var bubble_panel: PanelContainer
var bubble_label: Label

var minimap_bg: ColorRect
var minimap_player: ColorRect

# ポーズメニュー用
var pause_menu: Control
var pause_save_label: Label

# ステージ遷移用
var _nearby_transition_door: String = ""
var _nearby_height_scale: bool = false

# 測定結果パネル
var measurement_panel: Control
var measurement_content_label: Label
var history_panel: Control
var history_content_label: Label
var bump_alert_label: Label
var _bump_alert_time_left: float = 0.0

func _ready() -> void:
	# 既存のテスト用古いノード群があれば削除
	if has_node("Floor"): get_node("Floor").queue_free()
	if has_node("ObstacleHigh"): get_node("ObstacleHigh").queue_free()
	if has_node("ObstacleLow"): get_node("ObstacleLow").queue_free()
	
	# Globalスケール取得
	var global = get_node_or_null("/root/Global")
	if global:
		p = global.CM_TO_PX
		
	process_mode = Node.PROCESS_MODE_ALWAYS
	if player:
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		
	_setup_ui()
	_setup_bubble() # bubble_panel を先に追加（下層に描画）
	_setup_pause_menu() # pause_menu を後に追加（最前面に描画）
	_setup_measurement_panel()
	_load_stage()

func _setup_appearance_debug(vbox: VBoxContainer) -> void:
	var section_label = Label.new()
	section_label.text = "【服装デバッグ】"
	section_label.add_theme_font_size_override("font_size", 14)
	section_label.add_theme_color_override("font_color", Color("#6c757d"))
	vbox.add_child(section_label)

	# トップス選択
	var tops_row = HBoxContainer.new()
	vbox.add_child(tops_row)
	var tops_label = Label.new()
	tops_label.text = "トップス:"
	tops_label.custom_minimum_size = Vector2(90, 0)
	tops_row.add_child(tops_label)
	var tops_opt = OptionButton.new()
	tops_opt.focus_mode = Control.FOCUS_NONE
	tops_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tops_values = ["t_shirt", "sweater", "blouse"]
	tops_opt.add_item("Tシャツ", 0)
	tops_opt.add_item("セーター(長袖)", 1)
	tops_opt.add_item("ブラウス(長袖)", 2)
	tops_opt.selected = tops_values.find(Global.current_appearance.get("tops_type", "t_shirt"))
	tops_opt.item_selected.connect(func(idx: int) -> void:
		Global.current_appearance["tops_type"] = tops_values[idx]
		var drawer = player.get_node_or_null("CharacterDrawer")
		if drawer: drawer.queue_redraw()
	)
	tops_row.add_child(tops_opt)

	# ボトムス選択
	var bottoms_row = HBoxContainer.new()
	vbox.add_child(bottoms_row)
	var bottoms_label = Label.new()
	bottoms_label.text = "ボトムス:"
	bottoms_label.custom_minimum_size = Vector2(90, 0)
	bottoms_row.add_child(bottoms_label)
	var bottoms_opt = OptionButton.new()
	bottoms_opt.focus_mode = Control.FOCUS_NONE
	bottoms_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bottoms_values = ["pants", "skirt_short", "skirt_long"]
	bottoms_opt.add_item("パンツ", 0)
	bottoms_opt.add_item("ミニスカート", 1)
	bottoms_opt.add_item("ロングスカート", 2)
	bottoms_opt.selected = bottoms_values.find(Global.current_appearance.get("bottoms_type", "pants"))
	bottoms_opt.item_selected.connect(func(idx: int) -> void:
		Global.current_appearance["bottoms_type"] = bottoms_values[idx]
		var drawer = player.get_node_or_null("CharacterDrawer")
		if drawer: drawer.queue_redraw()
	)
	bottoms_row.add_child(bottoms_opt)

	# 髪型選択
	var hair_row = HBoxContainer.new()
	vbox.add_child(hair_row)
	var hair_label = Label.new()
	hair_label.text = "髪型:"
	hair_label.custom_minimum_size = Vector2(90, 0)
	hair_row.add_child(hair_label)
	var hair_opt = OptionButton.new()
	hair_opt.focus_mode = Control.FOCUS_NONE
	hair_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hair_values = ["short", "long"]
	hair_opt.add_item("ショート", 0)
	hair_opt.add_item("ロング", 1)
	hair_opt.selected = hair_values.find(Global.current_appearance.get("hair_style", "short"))
	hair_opt.item_selected.connect(func(idx: int) -> void:
		Global.current_appearance["hair_style"] = hair_values[idx]
		var drawer = player.get_node_or_null("CharacterDrawer")
		if drawer: drawer.queue_redraw()
	)
	hair_row.add_child(hair_opt)

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
	# CanvasLayer (ui_layer) に追加することで、2DのZ順に影響されず常に最前面に描画
	ui_layer.add_child(bubble_panel)
	bubble_panel.hide()

func _setup_bump_alert() -> void:
	bump_alert_label = Label.new()
	bump_alert_label.hide()
	bump_alert_label.add_theme_font_size_override("font_size", 18)
	bump_alert_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.75))
	bump_alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	bump_alert_label.add_theme_constant_override("outline_size", 5)
	bump_alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bump_alert_label.size = Vector2(360, 30)
	ui_layer.add_child(bump_alert_label)

func _update_bump_alert(delta: float) -> void:
	if not bump_alert_label:
		return
	if _bump_alert_time_left <= 0.0:
		bump_alert_label.hide()
		return

	_bump_alert_time_left = max(0.0, _bump_alert_time_left - delta)
	if _bump_alert_time_left <= 0.0:
		bump_alert_label.hide()
		return

	if not player:
		return

	var cam = player.get_node_or_null("Camera2D")
	var screen_pos: Vector2
	if cam:
		screen_pos = player.global_position - cam.get_screen_center_position() + get_viewport().get_visible_rect().size / 2.0
	else:
		screen_pos = player.global_position
	bump_alert_label.position = screen_pos + Vector2(-bump_alert_label.size.x / 2.0, -player.visual_height_cm * p - 120.0)
	bump_alert_label.show()

func _show_bump_alert(text: String) -> void:
	if not bump_alert_label:
		_setup_bump_alert()
	bump_alert_label.text = text
	_bump_alert_time_left = 0.9
	bump_alert_label.show()


func _process(delta: float) -> void:
	_update_ui()
	_update_bubble()
	_update_minimap()
	_update_bump_alert(delta)

func _update_minimap():
	if not player or not minimap_bg or not minimap_player: return
	var global = get_node_or_null("/root/Global")
	var stage_id = global.current_stage_id if global else "room"
	var stage_w_cm = 2000.0
	if StageBuilder.STAGES.has(stage_id):
		stage_w_cm = float(StageBuilder.STAGES[stage_id]["width"])
		
	var px_cm = clamp(player.global_position.x / p, 0.0, stage_w_cm)
	var ratio = px_cm / max(1.0, stage_w_cm)
	
	# clamp to keep within the bar visually
	var target_x = ratio * minimap_bg.size.x - minimap_player.size.x * 0.5
	minimap_player.position.x = target_x
	
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

		# 近くのオブジェクトに応じたインタラクションヒントを追加
		if obs_id.begins_with("door_to_"):
			_nearby_transition_door = obs_id
			_nearby_height_scale = false
			bubble_label.text += "\n[Eキーで移動]"
		elif obs_id == "height_scale":
			_nearby_transition_door = ""
			_nearby_height_scale = true
			bubble_label.text += "\n[Eキー] 身長を測る"
		else:
			_nearby_transition_door = ""
			_nearby_height_scale = false

		bubble_panel.show()

		# プレイヤーの2D座標をCanvasLayer上のスクリーン座標に変換して配置
		var cam = player.get_node_or_null("Camera2D")
		var screen_pos: Vector2
		if cam:
			screen_pos = player.global_position - cam.get_screen_center_position() + get_viewport().get_visible_rect().size / 2.0
		else:
			screen_pos = player.global_position
		var offset_y = player.visual_height_cm * p + 80
		bubble_panel.position = screen_pos + Vector2(-bubble_panel.size.x / 2.0, -offset_y)
	else:
		_nearby_transition_door = ""
		_nearby_height_scale = false
		bubble_panel.hide()

	pass

func _setup_ui():
	ui_layer = CanvasLayer.new()
	
	# サイドバー全体を覆うパネル（クラス変数を使用）
	sidebar = PanelContainer.new()
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

	var speed_label = Label.new()
	speed_label.text = "歩き速度"
	speed_label.add_theme_color_override("font_color", Color("#495057"))
	speed_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(speed_label)
	
	var speed_slider = HSlider.new()
	speed_slider.min_value = 50.0
	speed_slider.max_value = 600.0
	speed_slider.step = 10.0
	speed_slider.value = Global.system_settings.get("move_speed", 250.0)
	
	# 初期値をプレイヤーに適用
	if player:
		var initial_v = speed_slider.value
		var ratio = initial_v / 250.0
		player.set("SPEED", initial_v)
		player.set("walk_speed", 12.0 * ratio)

	speed_slider.value_changed.connect(func(v: float):
		Global.system_settings["move_speed"] = v
		if player:
			var ratio = v / 250.0
			player.set("SPEED", v)
			player.set("walk_speed", 12.0 * ratio)
	)
	speed_slider.drag_ended.connect(func(_val: bool):
		Global.save_settings()
	)
	vbox.add_child(speed_slider)

	vbox.add_child(HSeparator.new())
	_setup_appearance_debug(vbox)

	sidebar.hide() # 初期状態は非表示。Qキーでトグル
	ui_layer.add_child(sidebar)

	# 常時表示する「Q: ステータス」ヒントラベル
	var hint = Label.new()
	hint.text = "Q: ステータス設定"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 4)
	hint.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hint.position = Vector2(20, 10)
	ui_layer.add_child(hint)

	# ステージ上の自分の位置を示す線（ミニマップ）
	minimap_bg = ColorRect.new()
	minimap_bg.color = Color(0, 0, 0, 0.5)
	minimap_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	minimap_bg.position = Vector2(20, 32)
	minimap_bg.size = Vector2(200, 4)
	ui_layer.add_child(minimap_bg)
	
	minimap_player = ColorRect.new()
	minimap_player.color = Color(0.2, 0.8, 1.0, 1.0) # 水色
	minimap_player.position = Vector2(0, -2)
	minimap_player.size = Vector2(6, 8)
	minimap_bg.add_child(minimap_player)

	add_child(ui_layer)
	# ui_layer は _setup_ui() で add_child 済み。_setup_bubble() / _setup_pause_menu() はその後に呼ぶ

func _setup_pause_menu() -> void:
	pause_menu = ColorRect.new()
	pause_menu.color = Color(0, 0, 0, 0.6) # 半透明黒背景
	pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.hide()
	# ポーズメニュー自体は常に動作するようにする（親がALWAYSなので継承でも可だが念のため）
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(center)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#212529")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 40
	style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "PAUSE MENU"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)
	
	# セパレータ
	vbox.add_child(HSeparator.new())
	
	var resume_btn = Button.new()
	resume_btn.text = "ゲームに戻る (ESC)"
	resume_btn.custom_minimum_size = Vector2(250, 50)
	resume_btn.add_theme_font_size_override("font_size", 18)
	resume_btn.focus_mode = Control.FOCUS_NONE
	resume_btn.pressed.connect(_toggle_pause)
	vbox.add_child(resume_btn)
	
	var save_btn = Button.new()
	save_btn.text = "セーブする"
	save_btn.custom_minimum_size = Vector2(250, 50)
	save_btn.add_theme_font_size_override("font_size", 18)
	save_btn.focus_mode = Control.FOCUS_NONE
	save_btn.pressed.connect(_on_pause_save_pressed)
	vbox.add_child(save_btn)
	
	pause_save_label = Label.new()
	pause_save_label.add_theme_color_override("font_color", Color("#28a745"))
	pause_save_label.add_theme_font_size_override("font_size", 14)
	pause_save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(pause_save_label)
	
	var title_btn = Button.new()
	title_btn.text = "タイトルに戻る"
	title_btn.custom_minimum_size = Vector2(250, 50)
	title_btn.add_theme_font_size_override("font_size", 18)
	title_btn.focus_mode = Control.FOCUS_NONE
	title_btn.pressed.connect(_on_title_pressed)
	vbox.add_child(title_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "ゲームを終了する"
	quit_btn.custom_minimum_size = Vector2(250, 50)
	quit_btn.add_theme_font_size_override("font_size", 18)
	quit_btn.focus_mode = Control.FOCUS_NONE
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)
	
	ui_layer.add_child(pause_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # デフォルトでESCキー
		_toggle_pause()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			if sidebar: sidebar.visible = not sidebar.visible
		elif event.keycode == KEY_G:
			_toggle_history_panel()
		elif event.keycode == KEY_E:
			if _nearby_transition_door != "":
				_enter_transition_door()
			elif _nearby_height_scale:
				_show_measurement_result()

func _toggle_pause() -> void:
	if pause_menu:
		var is_paused = not get_tree().paused
		get_tree().paused = is_paused
		pause_menu.visible = is_paused
		if pause_save_label:
			pause_save_label.text = ""

func _on_pause_save_pressed() -> void:
	_on_save_pressed()
	if pause_save_label:
		var global = get_node_or_null("/root/Global")
		if global and global.current_slot >= 1:
			pause_save_label.text = "セーブしました (SLOT %02d)" % global.current_slot
			await get_tree().create_timer(2.0).timeout
			if pause_save_label: pause_save_label.text = ""
		else:
			pause_save_label.text = "スロットが選択されていません"

func _on_title_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()


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
	
	text += "\n【操作方法】\n"
	text += "矢印キー左右: 移動\n"
	text += "矢印キー下: 正面向き\n"
	text += "矢印キー上: 後ろ向き\n"
	text += "Eキー: ドアを通る\n"
	
	status_label.text = text

func _load_stage():
	var global = get_node_or_null("/root/Global")
	var stage_id = global.current_stage_id if global else "room"
	
	# 床や障害物を生成
	StageBuilder.build_stage(stage_id, self , p)
	
	_spawn_npcs(stage_id)

	# 自動セーブ（スロット選択済みの場合）
	if global and global.current_slot >= 1:
		global.save_slot(global.current_slot)
	
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
				cam.offset = Vector2(0, -m["height"] * p * 0.4)
			# 地面は y=50 のため、足元＋少しの余白だけ映るように余裕を持たせる
			cam.limit_bottom = 250
		var bump_handler := Callable(self, "_on_player_head_bump")
		if player.has_signal("head_bump") and not player.is_connected("head_bump", bump_handler):
			player.connect("head_bump", bump_handler)

func _on_player_head_bump(obs_id: String, obs_height_cm: float) -> void:
	_show_bump_alert(StageBuilder.get_head_bump_comment(obs_id, obs_height_cm))

func _spawn_npcs(stage_id: String) -> void:
	var npc_scene = load("res://NPC.tscn")
	if not npc_scene: return
	
	for child in get_children():
		if child.has_meta("is_npc"):
			child.queue_free()

	if stage_id == "outdoor":
		var npc = npc_scene.instantiate()
		npc.set_meta("is_npc", true)
		npc.custom_params = {
			"height": 158.0,
			"ratio": 7.0,
			"legRatio": 45.0,
			"sex": "female"
		}
		npc.position = Vector2(300 * p, 0)
		add_child(npc)
		
		# 街にいる小さな子供
		var kid = npc_scene.instantiate()
		kid.set_meta("is_npc", true)
		kid.custom_params = {
			"height": 110.0,
			"ratio": 5.5,
			"legRatio": 45.0,
			"sex": "female"
		}
		kid.custom_appearance = {
			"hair_style": "short",
			"hair_color": "#885533",
			"tops_type": "t_shirt",
			"tops_color": "#ffdd00",
			"bottoms_type": "pants",
			"bottoms_color": "#33aa33",
			"shoes_type": "sneakers",
			"shoes_color": "#ffffff"
		}
		kid.position = Vector2(500 * p, 0)
		add_child(kid)

	elif stage_id == "school_hallway":
		# 廊下にいる生徒
		var npc_hall = npc_scene.instantiate()
		npc_hall.set_meta("is_npc", true)
		npc_hall.custom_params = {
			"height": 140.0,
			"ratio": 6.2,
			"legRatio": 43.0,
			"sex": "female"
		}
		npc_hall.custom_appearance = {
			"hair_style": "long",
			"hair_color": "#443322",
			"tops_type": "blouse",
			"tops_color": "#ffffff",
			"bottoms_type": "skirt_short",
			"bottoms_color": "#111166",
			"shoes_type": "sneakers",
			"shoes_color": "#ffffff"
		}
		npc_hall.position = Vector2(700 * p, 0) # 掲示板付近
		add_child(npc_hall)

	elif stage_id == "school":
		# 背の低い先生/生徒用など
		var npc1 = npc_scene.instantiate()
		npc1.set_meta("is_npc", true)
		npc1.custom_params = {
			"height": 152.0,
			"ratio": 6.8,
			"legRatio": 44.0,
			"sex": "female"
		}
		npc1.custom_appearance = {
			"hair_style": "short",
			"hair_color": "#222222",
			"tops_type": "blouse",
			"tops_color": "#ffffff",
			"bottoms_type": "skirt_short",
			"bottoms_color": "#111166",
			"shoes_type": "sneakers",
			"shoes_color": "#ffffff"
		}
		npc1.position = Vector2(500 * p, 0)
		add_child(npc1)

		# 背の高い男性教師のようなダミー（身長175cm）
		var npc2 = npc_scene.instantiate()
		npc2.set_meta("is_npc", true)
		npc2.custom_params = {
			"height": 175.0,
			"ratio": 7.2,
			"legRatio": 46.0,
			"sex": "male"
		}
		npc2.custom_appearance = {
			"hair_style": "short",
			"hair_color": "#111111",
			"tops_type": "sweater",
			"tops_color": "#333333",
			"bottoms_type": "pants",
			"bottoms_color": "#111111",
			"shoes_type": "sneakers",
			"shoes_color": "#000000"
		}
		npc2.position = Vector2(900 * p, 0) # 先生の机付近
		add_child(npc2)

	elif stage_id == "infirmary":
		# 保健室の先生（小柄な女性、机の前に立っている）
		var nurse = npc_scene.instantiate()
		nurse.set_meta("is_npc", true)
		nurse.custom_params = {
			"height": 155.0,
			"ratio": 6.8,
			"legRatio": 44.0,
			"sex": "female"
		}
		nurse.custom_appearance = {
			"hair_style": "short",
			"hair_color": "#334422",
			"tops_type": "blouse",
			"tops_color": "#ffffff",
			"bottoms_type": "skirt_long",
			"bottoms_color": "#ffffff",
			"shoes_type": "sneakers",
			"shoes_color": "#cccccc"
		}
		nurse.position = Vector2(680 * p, 0) # 机のそば
		add_child(nurse)

func _on_save_pressed() -> void:
	var global = get_node_or_null("/root/Global")
	if not global: return
	if global.current_slot >= 1:
		global.save_slot(global.current_slot)

func _enter_transition_door() -> void:
	# "door_to_XXX" → 遷移先ステージID = "XXX"
	var new_stage_id = _nearby_transition_door.substr("door_to_".length())
	if not StageBuilder.STAGES.has(new_stage_id):
		return

	var from_stage_id = ""
	var global = get_node_or_null("/root/Global")
	if global:
		from_stage_id = global.current_stage_id
		global.current_stage_id = new_stage_id

	_nearby_transition_door = ""
	_load_stage()

	# 遷移先の「戻り口ドア」の近くにスポーン
	if player and from_stage_id != "" and StageBuilder.STAGES.has(new_stage_id):
		var return_door_id = "door_to_" + from_stage_id
		var stage_width = float(StageBuilder.STAGES[new_stage_id]["width"])
		for obs in StageBuilder.STAGES[new_stage_id]["obstacles"]:
			if obs["id"] == return_door_id:
				var obs_x = float(obs["x"])
				var obs_x2 = float(obs["x2"])
				var obs_center = (obs_x + obs_x2) / 2.0
				var spawn_x: float
				# ドアが右半分 → 左に出現、左半分 → 右に出現
				if obs_center > stage_width / 2.0:
					spawn_x = obs_x - 50.0
				else:
					spawn_x = obs_x2 + 50.0
				spawn_x = clamp(spawn_x, 50.0, stage_width - 50.0)
				player.position = Vector2(spawn_x * p, 0)
				break

# ─── 成長システム ───────────────────────────────────────────────

func _setup_measurement_panel() -> void:
	measurement_panel = ColorRect.new()
	measurement_panel.color = Color(0, 0, 0, 0.75)
	measurement_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	measurement_panel.hide()
	measurement_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	measurement_panel.add_child(center)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1a2a3a")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 48
	style.content_margin_right = 48
	style.content_margin_top = 40
	style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "身体測定結果"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	measurement_content_label = Label.new()
	measurement_content_label.add_theme_font_size_override("font_size", 18)
	measurement_content_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	measurement_content_label.custom_minimum_size = Vector2(380, 0)
	vbox.add_child(measurement_content_label)

	vbox.add_child(HSeparator.new())

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 24)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var close_btn = Button.new()
	close_btn.text = "閉じる"
	close_btn.custom_minimum_size = Vector2(140, 48)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(func():
		measurement_panel.hide()
		get_tree().paused = false
	)
	btn_row.add_child(close_btn)

	var next_btn = Button.new()
	next_btn.text = "次の学期へ"
	next_btn.custom_minimum_size = Vector2(160, 48)
	next_btn.add_theme_font_size_override("font_size", 16)
	next_btn.focus_mode = Control.FOCUS_NONE
	next_btn.pressed.connect(_on_next_term_pressed)
	btn_row.add_child(next_btn)

	ui_layer.add_child(measurement_panel)

func _show_measurement_result() -> void:
	var global = get_node_or_null("/root/Global")
	if not global: return

	var h: float = global.current_params["height"]
	var prev_h: float = global.prev_height
	var a: int = global.age
	var avg_h: float = global.get_avg_height(a)
	var diff_avg: float = h - avg_h

	var text = "年齢：%d歳  第%d学期\n\n" % [a, global.term + 1]
	text += "身長：  %.1f cm\n" % h
	if prev_h > 0.0:
		text += "前回比：%+.1f cm\n" % (h - prev_h)
	else:
		text += "前回比：（初回測定）\n"
	text += "同学年平均：%.1f cm\n" % avg_h
	text += "差：    %+.1f cm\n\n" % diff_avg
	text += global.get_measurement_comment(diff_avg)

	measurement_content_label.text = text
	measurement_panel.show()
	get_tree().paused = true

func _on_next_term_pressed() -> void:
	measurement_panel.hide()
	get_tree().paused = false
	_nearby_height_scale = false

	var global = get_node_or_null("/root/Global")
	if not global: return

	global.advance_term()

	if player:
		player.update_measurements()

	_load_stage()

func _setup_history_panel() -> void:
	if history_panel:
		return

	history_panel = ColorRect.new()
	history_panel.color = Color(0, 0, 0, 0.72)
	history_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	history_panel.hide()
	history_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	history_panel.add_child(center)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#16202c")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "成長記録"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	history_content_label = Label.new()
	history_content_label.add_theme_font_size_override("font_size", 18)
	history_content_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	history_content_label.custom_minimum_size = Vector2(520, 320)
	vbox.add_child(history_content_label)

	var close_hint = Label.new()
	close_hint.text = "[G] で閉じる"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.add_theme_font_size_override("font_size", 14)
	close_hint.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	vbox.add_child(close_hint)

	ui_layer.add_child(history_panel)

func _toggle_history_panel() -> void:
	if not history_panel:
		_setup_history_panel()

	if history_panel.visible:
		history_panel.hide()
		get_tree().paused = false
		return

	var global = get_node_or_null("/root/Global")
	if not global:
		return

	var lines: PackedStringArray = global.get_growth_history_lines(14)
	var header := "現在 %.1fcm / %d歳 / 第%d学期\n\n" % [
		float(global.current_params["height"]),
		int(global.age),
		int(global.term) + 1
	]
	if lines.is_empty():
		history_content_label.text = header + "まだ記録がありません。"
	else:
		history_content_label.text = header + "\n".join(lines)

	history_panel.show()
	get_tree().paused = true
