extends Node2D

# const STAGES = ["room", "train", "outdoor", "school"]
var p: float = 2.0

@onready var player: Node = $Player

# UI用
var ui_layer: CanvasLayer
var status_label: Label
var bubble_panel: PanelContainer
var bubble_label: Label

# ポーズメニュー用
var pause_menu: Control
var pause_save_label: Label

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
	_setup_pause_menu()
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
	# CanvasLayer (ui_layer) に追加することで、2DのZ順に影響されず常に最前面に描画
	ui_layer.add_child(bubble_panel)
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
	
	# 線のセパレータ（不要であればこちらも削除して構いませんが、見た目のために残します...あ、ボタン下にあったものなので削除します）

	ui_layer.add_child(sidebar)
	add_child(ui_layer)
	# ui_layerはsidebar追加後に子として登録するため、_setup_bubble()より先に呼ぶ必要がある

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
	
	status_label.text = text

func _load_stage():
	var global = get_node_or_null("/root/Global")
	var stage_id = global.current_stage_id if global else "room"
	
	# 床や障害物を生成
	StageBuilder.build_stage(stage_id, self , p)

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
				# X軸に -160 を指定し、キャラクターを画面右側に寄せる（左側のUI領域を確保）
				cam.offset = Vector2(-160, -m["height"] * p * 0.4)
			# 地面は y=50 のため、足元＋少しの余白だけ映るように余裕を持たせる
			cam.limit_bottom = 250

func _on_save_pressed() -> void:
	var global = get_node_or_null("/root/Global")
	if not global: return
	if global.current_slot >= 1:
		global.save_slot(global.current_slot)
