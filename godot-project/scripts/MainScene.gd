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
var _nearby_npc: Node = null # Eキーで話しかけられる近くのNPC

# アクションヒントパネル（Q キーで切り替え）
var action_hint_panel: PanelContainer
var action_hint_label: Label

# 測定結果パネル
var measurement_panel: Control
var measurement_content_label: Label
var history_panel: Control
var history_header_label: Label
var growth_graph: Control
var bump_alert_label: Label
var _bump_alert_time_left: float = 0.0

# ─── ダイアログシステム ──────────────────────────────────────────
var dialogue_panel: Control
var dialogue_name_label: Label
var dialogue_text_label: Label
var dialogue_hint_label: Label
var choice_container: VBoxContainer
var _in_dialogue: bool = false
var _choice_pending: bool = false
var _dialogue_lines: Array = []
var _dialogue_index: int = 0
var _current_dialogue_npc: String = ""
var _current_dialogue_key: String = ""
const DialogueDatabase = preload("res://scripts/DialogueDatabase.gd")
var _dialogues: Dictionary = DialogueDatabase.DATA

# ─── 学期選択 ──────────────────────────────────────────────────
var term_choice_panel: Control
var term_choice_header_label: Label
var _term_choice_showing: bool = false

const TERM_CHOICE_ORDER = ["home", "school", "station"]
const TERM_CHOICES: Dictionary = {
	"home": {
		"title": "1. 家で過ごす",
		"summary": "家族の近くで落ち着いて過ごす。ストレスは下がるが、外の刺激は少ない。",
		"stage_id": "room",
		"stress_delta": -12,
		"event_id": "term_home"
	},
	"school": {
		"title": "2. 学校を優先する",
		"summary": "授業や人間関係に向き合う。少し気疲れするが、学校イベントが進みやすい。",
		"stage_id": "school",
		"stress_delta": 8,
		"event_id": ""
	},
	"station": {
		"title": "3. 駅前に出る",
		"summary": "人の多い場所で、自分の大きさを強く意識する。ストレスは大きく上がる。",
		"stage_id": "station",
		"stress_delta": 16,
		"event_id": "term_station"
	},
}

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
	_setup_dialogue_panel() # ダイアログパネル（bubble_panelの上）
	_setup_pause_menu() # pause_menu を後に追加（最前面に描画）
	_setup_measurement_panel()
	_setup_term_choice_panel()
	_load_stage()

func _setup_appearance_debug(vbox: VBoxContainer) -> void:
	var section_label = Label.new()
	section_label.text = "【服装】"
	section_label.add_theme_font_size_override("font_size", 14)
	section_label.add_theme_color_override("font_color", Color("#6c757d"))
	vbox.add_child(section_label)

	# トップス選択（全6種類）
	var tops_row = HBoxContainer.new()
	vbox.add_child(tops_row)
	var tops_label = Label.new()
	tops_label.text = "トップス:"
	tops_label.custom_minimum_size = Vector2(76, 0)
	tops_row.add_child(tops_label)
	var tops_opt = OptionButton.new()
	tops_opt.focus_mode = Control.FOCUS_NONE
	tops_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tops_values = ["sailor", "blazer", "blouse_bow", "jumper_skirt", "sweater", "t_shirt"]
	tops_opt.add_item("セーラー服", 0)
	tops_opt.add_item("ジャンパースカート", 1)
	tops_opt.add_item("リボンブラウス", 2)
	tops_opt.add_item("サスペンダースカート", 3)
	tops_opt.add_item("スウェッター", 4)
	tops_opt.add_item("Tシャツ", 5)
	var cur_tops = tops_values.find(Global.current_appearance.get("tops_type", "t_shirt"))
	tops_opt.selected = max(0, cur_tops)
	tops_opt.item_selected.connect(func(idx: int) -> void:
		_apply_tops_type(tops_values[idx])
	)
	tops_row.add_child(tops_opt)

	# ボトムス選択
	var bottoms_row = HBoxContainer.new()
	vbox.add_child(bottoms_row)
	var bottoms_label = Label.new()
	bottoms_label.text = "ボトムス:"
	bottoms_label.custom_minimum_size = Vector2(76, 0)
	bottoms_row.add_child(bottoms_label)
	var bottoms_opt = OptionButton.new()
	bottoms_opt.focus_mode = Control.FOCUS_NONE
	bottoms_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bottoms_values = ["skirt", "skirt_long", "skirt_sailor", "pants"]
	bottoms_opt.add_item("スカート", 0)
	bottoms_opt.add_item("ロングスカート", 1)
	bottoms_opt.add_item("セーラースカート", 2)
	bottoms_opt.add_item("パンツ", 3)
	var cur_btm = bottoms_values.find(Global.current_appearance.get("bottoms_type", "pants"))
	bottoms_opt.selected = max(0, cur_btm)
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
	hair_label.custom_minimum_size = Vector2(76, 0)
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

	# 帽子選択
	var hat_row = HBoxContainer.new()
	vbox.add_child(hat_row)
	var hat_label = Label.new()
	hat_label.text = "帽子:"
	hat_label.custom_minimum_size = Vector2(76, 0)
	hat_row.add_child(hat_label)
	var hat_opt = OptionButton.new()
	hat_opt.focus_mode = Control.FOCUS_NONE
	hat_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hat_values = ["none", "school_hat"]
	hat_opt.add_item("なし", 0)
	hat_opt.add_item("学校帽", 1)
	var cur_hat = hat_values.find(Global.current_appearance.get("hat_type", "none"))
	hat_opt.selected = max(0, cur_hat)
	hat_opt.item_selected.connect(func(idx: int) -> void:
		Global.current_appearance["hat_type"] = hat_values[idx]
		var drawer = player.get_node_or_null("CharacterDrawer")
		if drawer: drawer.queue_redraw()
	)
	hat_row.add_child(hat_opt)

	# バッグ選択
	var bag_row = HBoxContainer.new()
	vbox.add_child(bag_row)
	var bag_label = Label.new()
	bag_label.text = "バッグ:"
	bag_label.custom_minimum_size = Vector2(76, 0)
	bag_row.add_child(bag_label)
	var bag_opt = OptionButton.new()
	bag_opt.focus_mode = Control.FOCUS_NONE
	bag_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bag_values = ["none", "randoseru"]
	bag_opt.add_item("なし", 0)
	bag_opt.add_item("ランドセル", 1)
	var cur_bag = bag_values.find(Global.current_appearance.get("bag_type", "none"))
	bag_opt.selected = max(0, cur_bag)
	bag_opt.item_selected.connect(func(idx: int) -> void:
		Global.current_appearance["bag_type"] = bag_values[idx]
		var drawer = player.get_node_or_null("CharacterDrawer")
		if drawer: drawer.queue_redraw()
	)
	bag_row.add_child(bag_opt)

	# ヒント
	var hint_lbl = Label.new()
	hint_lbl.text = "[Q] 服装パネルを開閉"
	hint_lbl.add_theme_font_size_override("font_size", 12)
	hint_lbl.add_theme_color_override("font_color", Color("#888"))
	vbox.add_child(hint_lbl)

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

func _setup_dialogue_panel() -> void:
	dialogue_panel = Control.new()
	dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.custom_minimum_size = Vector2(0, 160)
	dialogue_panel.offset_top = -160
	dialogue_panel.offset_bottom = 0
	dialogue_panel.hide()
	dialogue_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color("#1a1a2e")
	bg.border_color = Color("#e8c872")
	bg.border_width_top = 2
	bg.content_margin_left = 24
	bg.content_margin_right = 24
	bg.content_margin_top = 16
	bg.content_margin_bottom = 16

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", bg)
	dialogue_panel.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	dialogue_name_label = Label.new()
	dialogue_name_label.add_theme_font_size_override("font_size", 16)
	dialogue_name_label.add_theme_color_override("font_color", Color("#e8c872"))
	vbox.add_child(dialogue_name_label)

	dialogue_text_label = Label.new()
	dialogue_text_label.add_theme_font_size_override("font_size", 20)
	dialogue_text_label.add_theme_color_override("font_color", Color.WHITE)
	dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(dialogue_text_label)

	# 選択肢コンテナ
	choice_container = VBoxContainer.new()
	choice_container.add_theme_constant_override("separation", 6)
	choice_container.hide()
	vbox.add_child(choice_container)

	dialogue_hint_label = Label.new()
	dialogue_hint_label.text = "Eキーで次へ"
	dialogue_hint_label.add_theme_font_size_override("font_size", 13)
	dialogue_hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	dialogue_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(dialogue_hint_label)

	ui_layer.add_child(dialogue_panel)

func _setup_term_choice_panel() -> void:
	term_choice_panel = ColorRect.new()
	term_choice_panel.color = Color(0, 0, 0, 0.72)
	term_choice_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	term_choice_panel.hide()
	term_choice_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	term_choice_panel.add_child(center)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#16202c")
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "今学期どこで過ごす？"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	term_choice_header_label = Label.new()
	term_choice_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	term_choice_header_label.add_theme_font_size_override("font_size", 15)
	term_choice_header_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.94))
	vbox.add_child(term_choice_header_label)

	for choice_id: String in TERM_CHOICE_ORDER:
		var choice: Dictionary = TERM_CHOICES[choice_id]
		var btn = Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(580, 74)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "%s\n%s  (stress %s%d)" % [
			String(choice.get("title", choice_id)),
			String(choice.get("summary", "")),
			"+" if int(choice.get("stress_delta", 0)) >= 0 else "",
			int(choice.get("stress_delta", 0))
		]
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_term_choice_selected.bind(choice_id))
		vbox.add_child(btn)

	var hint = Label.new()
	hint.text = "[1][2][3] でも選択できます"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.72, 0.79, 0.86))
	vbox.add_child(hint)

	ui_layer.add_child(term_choice_panel)

func _show_term_choice_panel() -> void:
	if _term_choice_showing:
		return
	var global = get_node_or_null("/root/Global")
	if not global or not global.pending_term_choice:
		return
	_term_choice_showing = true
	term_choice_header_label.text = "%d歳 / 第%d学期 / stress %d (%s)" % [
		int(global.age),
		int(global.term) + 1,
		int(global.stress),
		_get_stress_state_text(int(global.stress))
	]
	term_choice_panel.show()
	get_tree().paused = true

func _hide_term_choice_panel() -> void:
	_term_choice_showing = false
	term_choice_panel.hide()
	get_tree().paused = false

func _on_term_choice_selected(choice_id: String) -> void:
	var global = get_node_or_null("/root/Global")
	if not global:
		return
	if not TERM_CHOICES.has(choice_id):
		return

	var choice: Dictionary = TERM_CHOICES[choice_id]
	global.pending_term_choice = false
	global.current_term_plan = choice_id
	global.add_stress(int(choice.get("stress_delta", 0)))

	var summer_front: bool = (
		global.pending_events.size() > 0
		and String(global.pending_events[0]) == "summer_growth"
	)
	if summer_front and choice_id != "home":
		global.pending_events.pop_front()
		global.queue_event("summer_growth")

	var event_id: String = String(choice.get("event_id", ""))
	if event_id != "" and not (choice_id == "home" and summer_front):
		global.pending_events.push_front(event_id)

	global.current_stage_id = String(choice.get("stage_id", global.current_stage_id))
	global.save_settings()
	_hide_term_choice_panel()
	_load_stage()

func _is_term_intro_dialogue() -> bool:
	if _current_dialogue_npc != "player":
		return false
	return _current_dialogue_key in [
		"new_semester",
		"entrance_elementary",
		"entrance_middle",
		"entrance_high",
		"summer_growth",
		"summer_growth_vball"
	]

func _get_stress_state_text(stress_value: int) -> String:
	if stress_value >= 75:
		return "かなり張りつめている"
	if stress_value >= 45:
		return "少ししんどい"
	if stress_value >= 20:
		return "やや緊張している"
	return "落ち着いている"

func _start_dialogue(npc_id: String, key: String = "default") -> void:
	if _in_dialogue or _measurement_showing or _term_choice_showing: return
	if not _dialogues.has(npc_id): return
	var npc_data: Dictionary = _dialogues[npc_id]
	if not npc_data.has(key): return

	_current_dialogue_npc = npc_id
	_current_dialogue_key = key
	_dialogue_lines = npc_data[key]
	_dialogue_index = 0
	_in_dialogue = true
	get_tree().paused = true
	dialogue_panel.show()
	_show_dialogue_line()

func _show_dialogue_line() -> void:
	if _dialogue_index >= _dialogue_lines.size():
		_end_dialogue()
		return
	var line: Dictionary = _dialogue_lines[_dialogue_index]
	dialogue_name_label.text = line.get("speaker", "")
	dialogue_text_label.text = line.get("text", "")
	if line.has("choices"):
		_show_choices(line["choices"])
	else:
		choice_container.hide()
		_choice_pending = false
		dialogue_hint_label.show()

func _show_choices(choices: Array) -> void:
	_choice_pending = true
	dialogue_hint_label.hide()
	for child in choice_container.get_children():
		child.queue_free()
	var choice_style = StyleBoxFlat.new()
	choice_style.bg_color = Color("#2a2a44")
	choice_style.border_color = Color("#e8c872")
	choice_style.border_width_bottom = 1
	choice_style.content_margin_left = 12
	choice_style.content_margin_right = 12
	choice_style.content_margin_top = 6
	choice_style.content_margin_bottom = 6
	var hover_style = choice_style.duplicate()
	hover_style.bg_color = Color("#3a3a60")
	for c in choices:
		var btn = Button.new()
		btn.text = c.get("label", "")
		btn.add_theme_font_size_override("font_size", 17)
		btn.add_theme_stylebox_override("normal", choice_style.duplicate())
		btn.add_theme_stylebox_override("hover", hover_style.duplicate())
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.connect("pressed", _on_choice_selected.bind(c))
		choice_container.add_child(btn)
	choice_container.show()

func _on_choice_selected(choice: Dictionary) -> void:
	_choice_pending = false
	choice_container.hide()
	dialogue_hint_label.show()
	# 感情パラメータ更新
	var emotion: String = choice.get("emotion", "")
	var global = get_node_or_null("/root/Global")
	if global and emotion != "":
		if emotion == "confidence":
			global.self_confidence += 1
		elif emotion == "complex":
			global.self_complex += 1
	# アクション処理（バレー部ストーリーなど）
	var action: String = choice.get("action", "")
	if global and action != "":
		_process_choice_action(action, global)
	# 分岐先へ
	var next_key: String = choice.get("next", "")
	if next_key != "":
		var npc_data: Dictionary = _dialogues.get(_current_dialogue_npc, {})
		if npc_data.has(next_key):
			_dialogue_lines = npc_data[next_key]
			_dialogue_index = 0
			_show_dialogue_line()
			return
	_advance_dialogue()

func _process_choice_action(action: String, global: Node) -> void:
	match action:
		"vball_join":
			global.vball_joined = true
			global.vball_story_phase = 2
		"vball_pain_report":
			global.vball_story_phase = 4
			global.queue_event("vball_tell_senior")
		"vball_rejoin":
			global.vball_joined = true
			global.is_leg_pain = false
			global.vball_story_phase = 7
		"vball_manager_role":
			global.vball_joined = false
			global.is_leg_pain = false
			global.vball_story_phase = 7

func _advance_dialogue() -> void:
	if _choice_pending: return
	_dialogue_index += 1
	_show_dialogue_line()

func _end_dialogue() -> void:
	var should_show_term_choice: bool = false
	var global = get_node_or_null("/root/Global")
	if global and global.pending_term_choice and _is_term_intro_dialogue():
		should_show_term_choice = true

	_in_dialogue = false
	_choice_pending = false
	choice_container.hide()
	dialogue_hint_label.show()
	get_tree().paused = false
	dialogue_panel.hide()
	# measure_invite 終了 → はるかがプレイヤーに追随し始める
	if _current_dialogue_npc == "haruka" and _current_dialogue_key == "measure_invite":
		if global:
			global.haruka_following = true
		for child in get_children():
			if child.has_meta("is_npc") and child.get("npc_id") == "haruka":
				child.follow_target = player
				break
	# ─── バレー部ストーリー後処理 ────────────────────────────────
	elif _current_dialogue_npc == "senior" and _current_dialogue_key == "first_meet":
		if global and global.vball_story_phase == 0:
			global.vball_story_phase = 1
	elif _current_dialogue_npc == "senior" and _current_dialogue_key == "practice_first":
		if global and global.vball_joined:
			global.is_leg_pain = true
			global.vball_story_phase = 3
	elif _current_dialogue_npc == "senior" and _current_dialogue_key == "pain_concern":
		if global:
			global.is_leg_pain = false
			global.vball_joined = false
			global.vball_story_phase = 5
	elif _current_dialogue_npc == "teacher" and _current_dialogue_key == "semester_start":
		if global and global.current_term_plan == "school":
			call_deferred("_start_dialogue", "player", "term_school")
	elif _current_dialogue_npc == "honoka" and _current_dialogue_key == "vball_join_cheer":
		pass # 特に後処理なし
	elif _current_dialogue_npc == "honoka" and _current_dialogue_key == "haruka_after_summer":
		pass # 特に後処理なし

	if should_show_term_choice:
		call_deferred("_show_term_choice_panel")

func _get_bubble_screen_pos() -> Vector2:
	var cam = player.get_node_or_null("Camera2D")
	var screen_pos: Vector2
	if cam:
		screen_pos = player.global_position - cam.get_screen_center_position() + get_viewport().get_visible_rect().size / 2.0
	else:
		screen_pos = player.global_position
	var offset_y = player.visual_height_cm * p + 80
	return screen_pos + Vector2(-bubble_panel.size.x / 2.0, -offset_y)

func _get_nearby_named_npc(dist_px: float) -> Node:
	if not player: return null
	for child in get_children():
		if child.has_meta("is_npc"):
			var d = abs(child.global_position.x - player.global_position.x)
			if d <= dist_px:
				return child
	return null

func _interact_with_npc(npc: Node) -> void:
	if not npc or not player: return
	# フレーム間でNPCが離れた場合の保護
	if abs(npc.global_position.x - player.global_position.x) > 200.0: return
	
	var npc_id: String = npc.get("npc_id") if npc.get("npc_id") != null else ""
	var is_generic = false
	if npc_id == "":
		npc_id = "generic"
		is_generic = true

	# 身長差に応じてセリフキーを選択
	var player_m = player.get("m")
	var npc_m = npc.get("m")
	var key = "default"
	if player_m and npc_m:
		var npc_data: Dictionary = _dialogues.get(npc_id, _dialogues.get("generic", {}))
		var diff = float(player_m["height"]) - float(npc_m["height"])
		var global = get_node_or_null("/root/Global")
		var vball_phase = global.vball_story_phase if global else 0
		
		# 初対面判定 (Globalのメタデータを使って記憶を維持)
		var unique_npc_key = npc_id
		var has_met = false
		if is_generic:
			has_met = false # 名無しNPCは常に初対面扱い
		elif global:
			has_met = global.met_npcs.has(unique_npc_key)
		else:
			has_met = npc.get_meta("met_player", false)

		if is_generic:
			if diff >= 35.0:
				key = "huge"
			elif diff >= 15.0:
				key = "tall"
			else:
				key = "default"
		elif npc_data.has("first_meet") and not has_met:
			key = "first_meet"
			if global:
				global.met_npcs.append(unique_npc_key)
			else:
				npc.set_meta("met_player", true)
		elif npc_id == "senior":
			# バレー部ストーリーフェーズによる分岐
			if vball_phase == 1:
				key = "join_invite"
			elif vball_phase == 2 and global and global.vball_joined:
				key = "practice_first"
			elif vball_phase == 3 and global and global.is_leg_pain:
				key = "pain_concern"
			elif vball_phase == 6:
				key = "senior_after_summer"
			elif diff >= 35.0 and npc_data.has("huge"):
				key = "huge"
		elif npc_id == "honoka":
			if global and global.is_leg_pain and vball_phase == 3:
				key = "vball_pain_consult"
			elif global and not global.haruka_invited_this_term:
				key = "measure_invite"
				global.haruka_invited_this_term = true
			elif diff >= 35.0 and npc_data.has("huge"):
				key = "huge"
			elif diff >= 15.0 and npc_data.has("tall"):
				key = "tall"
		elif (npc_id == "haruka") and global and not global.haruka_invited_this_term:
			key = "measure_invite"
			global.haruka_invited_this_term = true
		elif diff >= 35.0 and npc_data.has("huge"):
			key = "huge"
		elif diff >= 15.0 and npc_data.has("tall"):
			key = "tall"
		elif (npc_id == "mother" or npc_id == "father") and npc_data.has("check"):
			key = "check"
	_start_dialogue(npc_id, key)

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
	if action_hint_label and action_hint_panel and action_hint_panel.visible:
		action_hint_label.text = _get_action_hint_text()

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

	# NPC検知を先に行う（ステージオブジェクトより優先）
	_nearby_npc = _get_nearby_named_npc(150.0)
	if _nearby_npc:
		_nearby_transition_door = ""
		_nearby_height_scale = false
		bubble_label.text = "[Eキー] 話しかける"
		bubble_panel.show()
		bubble_panel.position = _get_bubble_screen_pos()
		return

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
		bubble_panel.position = _get_bubble_screen_pos()
	else:
		_nearby_transition_door = ""
		_nearby_height_scale = false
		bubble_panel.hide()

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
	
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sidebar.add_child(scroll)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	
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
	if player and player.has_method("refresh_movement_tuning"):
		player.call("refresh_movement_tuning")

	speed_slider.value_changed.connect(func(v: float):
		Global.system_settings["move_speed"] = v
		if player and player.has_method("refresh_movement_tuning"):
			player.call("refresh_movement_tuning")
	)
	speed_slider.drag_ended.connect(func(_val: bool):
		Global.save_settings()
	)
	vbox.add_child(speed_slider)

	vbox.add_child(HSeparator.new())
	_setup_appearance_debug(vbox)

	sidebar.hide() # 初期状態は非表示。Qキーでトグル
	ui_layer.add_child(sidebar)

	# ─── アクションヒントパネル（画面右下・常時表示）─────────────
	action_hint_panel = PanelContainer.new()
	var ah_style = StyleBoxFlat.new()
	ah_style.bg_color = Color(0, 0, 0, 0.55)
	ah_style.corner_radius_top_left = 8
	ah_style.corner_radius_top_right = 8
	ah_style.corner_radius_bottom_right = 8
	ah_style.corner_radius_bottom_left = 8
	ah_style.content_margin_left = 14
	ah_style.content_margin_right = 14
	ah_style.content_margin_top = 8
	ah_style.content_margin_bottom = 8
	action_hint_panel.add_theme_stylebox_override("panel", ah_style)
	action_hint_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	action_hint_panel.offset_left = -360
	action_hint_panel.offset_top = -64
	action_hint_panel.offset_right = -16
	action_hint_panel.offset_bottom = -16
	action_hint_label = Label.new()
	action_hint_label.add_theme_font_size_override("font_size", 14)
	action_hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	action_hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	action_hint_label.add_theme_constant_override("outline_size", 3)
	action_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_hint_label.custom_minimum_size = Vector2(300, 0)
	action_hint_panel.add_child(action_hint_label)
	ui_layer.add_child(action_hint_panel)

	# 常時表示する「Q: ステータス設定」ヒントラベル
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
	if _term_choice_showing and event.is_action_pressed("ui_cancel"):
		return
	if _term_choice_showing and event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_on_term_choice_selected("home")
			KEY_2:
				_on_term_choice_selected("school")
			KEY_3:
				_on_term_choice_selected("station")
		return

	if event.is_action_pressed("ui_cancel"): # デフォルトでESCキー
		_toggle_pause()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			if sidebar: sidebar.visible = not sidebar.visible
			_toggle_action_hint()
		elif event.keycode == KEY_G:
			_toggle_history_panel()
		elif event.keycode == KEY_E:
			if _in_dialogue:
				_advance_dialogue()
			elif _measurement_showing:
				_on_next_term_pressed()
			elif _nearby_transition_door != "":
				_enter_transition_door()
			elif _nearby_height_scale:
				_show_measurement_result()
			elif _nearby_npc:
				_interact_with_npc(_nearby_npc)

# 服装タイプを適用するヘルパー（サイドバーのドロップダウンから使用）
func _apply_tops_type(tops_type: String) -> void:
	const COLOR_MAP = {
		"sailor": "#1a2a5e",
		"blazer": "#212840",
		"blouse_bow": "#f0e8e0",
		"jumper_skirt": "#212840",
		"sweater": "#7a9a7a",
		"t_shirt": "#ab82a8",
	}
	Global.current_appearance["tops_type"] = tops_type
	if COLOR_MAP.has(tops_type):
		Global.current_appearance["tops_color"] = COLOR_MAP[tops_type]
	var drawer = player.get_node_or_null("CharacterDrawer") if player else null
	if drawer: drawer.queue_redraw()


func _toggle_action_hint() -> void:
	if action_hint_panel:
		action_hint_panel.visible = not action_hint_panel.visible

func _get_action_hint_text() -> String:
	if _term_choice_showing:
		return "[1][2][3] 学期の過ごし方を選ぶ"
	if _in_dialogue:
		return "[E] 次へ"
	if _measurement_showing:
		return "[E] 次の学期へ進む"
	if _nearby_transition_door != "":
		var dest = _nearby_transition_door.substr("door_to_".length())
		var dest_name = StageBuilder.get_stage_name(dest, Global.age) if StageBuilder.STAGES.has(dest) else dest
		return "[E] %s へ移動" % dest_name
	if _nearby_height_scale:
		return "[E] 身長を測る"
	if _nearby_npc:
		var npc_id: String = _nearby_npc.get("npc_id") if _nearby_npc.get("npc_id") != null else ""
		if npc_id != "":
			return "[E] 話しかける"
	if Global.stress >= 70:
		return "肩がこわばる……今学期は少し休みたい"
	if Global.stress >= 40:
		return "少し気が張っている  [Q] 設定  [G] 成長記録"
	# バレー部ストーリーヒント
	var vball_phase = Global.vball_story_phase
	if vball_phase == 0 and Global.senior_gym_invited:
		return "廊下の先輩に話しかけてみよう"
	if vball_phase == 1:
		return "体育館に行って先輩に話しかけよう"
	if vball_phase == 2:
		return "先輩と練習してみよう"
	if vball_phase == 3 and Global.is_leg_pain:
		return "ほのかに脚のことを相談してみよう"
	return "[Q] 設定  [G] 成長記録  [E] インタラクト"

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
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = 'index.html';")
	else:
		get_tree().quit()


func _update_ui():
	if not player or not status_label: return
	
	var global = get_node_or_null("/root/Global")
	var stage_id: String = global.current_stage_id if global else "room"
	var stage_name: String = StageBuilder.get_stage_name(stage_id, global.age if global else 0)
	var m = player.get("m")
	if not m: return
	
	var params = global.current_params if global else m
	
	var age_val: int = global.age if global else 0
	var term_val: int = global.term if global else 0
	var stress_val: int = global.stress if global else 0
	var term_plan: String = global.current_term_plan if global else ""
	var school_type: String = StageBuilder.get_stage_name("school", age_val)
	var text = "【基本情報】\n"
	text += "Stage: %s\n" % stage_name
	text += "%d歳 / %d学期 (%s)\n" % [age_val, term_val + 1, school_type]
	if term_plan != "":
		var plan_data: Dictionary = TERM_CHOICES.get(term_plan, {})
		text += "今学期の方針: %s\n" % String(plan_data.get("title", term_plan))
	text += "stress: %d / 100 (%s)\n" % [int(stress_val), _get_stress_state_text(int(stress_val))]
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
	StageBuilder.build_stage(stage_id, self , p, global.age if global else 0)
	
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
		var bump_handler := Callable(self , "_on_player_head_bump")
		if player.has_signal("head_bump") and not player.is_connected("head_bump", bump_handler):
			player.connect("head_bump", bump_handler)

	# ペンディングイベントを処理（始業式は教室に入ったときのみ発火）
	if global:
		var ev = global.pop_next_event()
		if ev == "semester_start":
			if stage_id == "school":
				await get_tree().create_timer(0.5).timeout
				_start_dialogue("teacher", "semester_start")
				# 1学期（初回）のみ先輩招待をキュー
				if not global.senior_gym_invited:
					global.senior_gym_invited = true
					global.queue_event("gym_senior_invite")
			else:
				global.pending_events.push_front(ev) # 教室に入るまで保留
		elif ev == "gym_senior_invite":
			if stage_id == "gymnasium":
				await get_tree().create_timer(0.8).timeout
				_start_dialogue("senior", "first_meet")
			else:
				global.pending_events.push_front(ev) # 体育館に入るまで保留
		elif ev == "term_home":
			if stage_id == "room":
				await get_tree().create_timer(0.5).timeout
				_start_dialogue("player", "term_home")
			else:
				global.pending_events.push_front(ev)
		elif ev == "term_station":
			if stage_id == "station":
				await get_tree().create_timer(0.5).timeout
				_start_dialogue("player", "term_station")
			else:
				global.pending_events.push_front(ev)
		elif ev == "summer_growth":
			if stage_id == "room":
				await get_tree().create_timer(0.8).timeout
				# バレー部加入済みの場合は専用ダイアログを使う（未加入ルートも保護）
				var summer_key = "summer_growth"
				if global.vball_joined and global.vball_story_phase >= 2:
					summer_key = "summer_growth_vball"
				_start_dialogue("player", summer_key)
				# バレー部ストーリーが進行中なら夏後フェーズへ
				if global.vball_story_phase >= 2 and global.vball_story_phase < 6:
					global.vball_story_phase = 6
			else:
				global.pending_events.push_front(ev) # room に入るまで保留
		elif ev == "vball_tell_senior":
			if stage_id == "gymnasium":
				await get_tree().create_timer(0.8).timeout
				_start_dialogue("senior", "pain_concern")
			else:
				global.pending_events.push_front(ev) # 体育館に入るまで保留
		elif ev == "entrance_ceremony":
			if stage_id == "myroom":
				await get_tree().create_timer(1.2).timeout
				_start_dialogue("player", _get_entrance_dialogue_key(global.age))
			else:
				global.pending_events.push_front(ev) # myroom に入るまで保留

func _get_entrance_dialogue_key(age: int) -> String:
	if age <= 6: return "entrance_elementary"
	if age <= 12: return "entrance_middle"
	return "entrance_high"

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

	elif stage_id == "room":
		# 母親
		var mother = npc_scene.instantiate()
		mother.set_meta("is_npc", true)
		mother.npc_id = "mother"
		mother.position = Vector2(400 * p, 0)
		add_child(mother)
		# 父親（男性パラメータを事前設定）
		var father = npc_scene.instantiate()
		father.set_meta("is_npc", true)
		father.npc_id = "father"
		father.custom_params = {"height": 170.0, "ratio": 7.3, "legRatio": 46.0, "sex": "male"}
		father.position = Vector2(700 * p, 0)
		add_child(father)

	elif stage_id == "school_hallway":
		# 先輩（バレー部）
		var senior = npc_scene.instantiate()
		senior.set_meta("is_npc", true)
		senior.npc_id = "senior"
		senior.custom_params = {"height": 168.0, "ratio": 7.1, "legRatio": 45.0, "sex": "female"}
		senior.position = Vector2(1200 * p, 0)
		add_child(senior)
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
		# 友人「ほのか」
		var honoka = npc_scene.instantiate()
		honoka.set_meta("is_npc", true)
		honoka.npc_id = "honoka"
		honoka.position = Vector2(300 * p, 0)
		add_child(honoka)
		# コアNPC「桐島はるか」
		var npc1 = npc_scene.instantiate()
		npc1.set_meta("is_npc", true)
		npc1.npc_id = "haruka"
		npc1.custom_params = {
			"height": 152.0,
			"ratio": 6.8,
			"legRatio": 44.0,
			"sex": "female"
		}
		npc1.custom_appearance = {
			"hair_style": "long",
			"hair_color": "#885533",
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

	elif stage_id == "gymnasium":
		# バレー部先輩
		var gym_senior = npc_scene.instantiate()
		gym_senior.set_meta("is_npc", true)
		gym_senior.npc_id = "senior"
		gym_senior.custom_params = {"height": 168.0, "ratio": 7.1, "legRatio": 45.0, "sex": "female"}
		gym_senior.position = Vector2(1200 * p, 0)
		add_child(gym_senior)

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
		nurse.npc_id = "nurse"
		nurse.position = Vector2(680 * p, 0) # 机のそば
		add_child(nurse)
		# はるかが追随中なら身長計の横にスポーン
		var global_inf = get_node_or_null("/root/Global")
		if global_inf and global_inf.haruka_following:
			var haruka_inf = npc_scene.instantiate()
			haruka_inf.set_meta("is_npc", true)
			haruka_inf.npc_id = "haruka"
			haruka_inf.custom_params = {
				"height": 152.0,
				"ratio": 6.8,
				"legRatio": 44.0,
				"sex": "female"
			}
			haruka_inf.custom_appearance = {
				"hair_style": "long",
				"hair_color": "#885533",
				"tops_type": "sweater",
				"tops_color": "#ffffff",
				"bottoms_type": "skirt_long",
				"bottoms_color": "#333333",
				"shoes_type": "sneakers",
				"shoes_color": "#aa3333"
			}
			haruka_inf.position = Vector2(350 * p, 0) # 身長計付近
			add_child(haruka_inf)

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
		var cur_age = global.age if global else 0
		for obs in StageBuilder.get_obstacles(new_stage_id, cur_age):
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

# 測定パネル内の動的ラベル（アニメ用）
var _meas_height_label: Label = null
var _meas_diff_label: Label = null
var _meas_btn_row: HBoxContainer = null
var _measurement_showing: bool = false
var _mini_proxy: Node2D = null
var _mini_drawer: Node2D = null
var _meas_graph: Control = null

func _setup_measurement_panel() -> void:
	measurement_panel = ColorRect.new()
	measurement_panel.color = Color(0, 0, 0, 0.0)
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

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	panel.add_child(hbox)

	# --- 左: ミニアバタービュー ---
	var svc = SubViewportContainer.new()
	svc.custom_minimum_size = Vector2(160, 0)
	svc.stretch = true
	svc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(svc)

	var sv = SubViewport.new()
	sv.size = Vector2i(160, 380)
	sv.transparent_bg = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.process_mode = Node.PROCESS_MODE_ALWAYS
	svc.add_child(sv)

	_mini_proxy = Node2D.new()
	_mini_proxy.set_script(load("res://scripts/MiniPlayerProxy.gd"))
	_mini_proxy.position = Vector2(80, 365)
	_mini_proxy.process_mode = Node.PROCESS_MODE_ALWAYS
	sv.add_child(_mini_proxy)

	_mini_drawer = Node2D.new()
	_mini_drawer.set_script(load("res://scripts/CharacterDrawer.gd"))
	_mini_drawer.process_mode = Node.PROCESS_MODE_ALWAYS
	_mini_proxy.add_child(_mini_drawer)

	# --- 右: テキストUI ---
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	hbox.add_child(vbox)

	var title = Label.new()
	title.text = "身体測定結果"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# 身長数値（カウントアップアニメ対象）
	_meas_height_label = Label.new()
	_meas_height_label.add_theme_font_size_override("font_size", 48)
	_meas_height_label.add_theme_color_override("font_color", Color.WHITE)
	_meas_height_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meas_height_label.text = "--- cm"
	vbox.add_child(_meas_height_label)

	# 前回比（ポップアップアニメ対象）
	_meas_diff_label = Label.new()
	_meas_diff_label.add_theme_font_size_override("font_size", 28)
	_meas_diff_label.add_theme_color_override("font_color", Color("#7fffb0"))
	_meas_diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meas_diff_label.modulate.a = 0.0
	vbox.add_child(_meas_diff_label)

	# 成長グラフ（測定パネル内インライン表示）
	var GrowthGraphScript = load("res://scripts/GrowthGraph.gd")
	_meas_graph = GrowthGraphScript.new()
	_meas_graph.custom_minimum_size = Vector2(380, 110)
	vbox.add_child(_meas_graph)

	vbox.add_child(HSeparator.new())

	# 詳細テキスト（平均比較・コメント）
	measurement_content_label = Label.new()
	measurement_content_label.add_theme_font_size_override("font_size", 16)
	measurement_content_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	measurement_content_label.custom_minimum_size = Vector2(380, 0)
	measurement_content_label.modulate.a = 0.0
	vbox.add_child(measurement_content_label)

	vbox.add_child(HSeparator.new())

	_meas_btn_row = HBoxContainer.new()
	_meas_btn_row.add_theme_constant_override("separation", 24)
	_meas_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_meas_btn_row.modulate.a = 0.0
	vbox.add_child(_meas_btn_row)

	var close_btn = Button.new()
	close_btn.text = "閉じる"
	close_btn.custom_minimum_size = Vector2(140, 48)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(_on_measurement_panel_closed)
	_meas_btn_row.add_child(close_btn)

	var next_btn = Button.new()
	next_btn.text = "次の学期へ"
	next_btn.custom_minimum_size = Vector2(160, 48)
	next_btn.add_theme_font_size_override("font_size", 16)
	next_btn.focus_mode = Control.FOCUS_NONE
	next_btn.pressed.connect(_on_next_term_pressed)
	_meas_btn_row.add_child(next_btn)

	ui_layer.add_child(measurement_panel)

func _update_mini_avatar(h_cm: float) -> void:
	if not is_instance_valid(_mini_proxy) or not is_instance_valid(_mini_drawer):
		return
	var global = get_node_or_null("/root/Global")
	if not global:
		return
	var temp_params = global.current_params.duplicate()
	temp_params["height"] = h_cm
	_mini_proxy.m = global.get_custom_body_measurements(temp_params)
	_mini_proxy.visual_height_cm = h_cm
	_mini_drawer.queue_redraw()

func _show_measurement_result() -> void:
	var global = get_node_or_null("/root/Global")
	if not global: return

	var h: float = global.current_params["height"]
	var prev_h: float = global.prev_height
	var a: int = global.age
	var avg_h: float = global.get_avg_height(a)
	var diff_avg: float = h - avg_h
	var diff_prev: float = h - prev_h if prev_h > 0.0 else 0.0

	# 詳細テキスト（後でフェードイン）
	var detail = "年齢：%d歳  第%d学期\n" % [a, global.term + 1]
	detail += "同学年平均：%.1f cm  （差：%+.1f cm）\n\n" % [avg_h, diff_avg]
	detail += global.get_measurement_comment(diff_avg)
	measurement_content_label.text = detail

	# 前回比ラベル
	if prev_h > 0.0:
		_meas_diff_label.text = "前回比  %+.1f cm" % diff_prev
	else:
		_meas_diff_label.text = "はじめての測定"

	# 初期状態リセット
	_meas_height_label.text = "%.1f cm" % (prev_h if prev_h > 0.0 else h)
	_meas_diff_label.modulate.a = 0.0
	measurement_content_label.modulate.a = 0.0
	_meas_btn_row.modulate.a = 0.0
	_meas_diff_label.scale = Vector2(0.7, 0.7)
	_update_mini_avatar(prev_h if prev_h > 0.0 else h)

	# グラフに「現在測定中」のプレビューデータをセット（最新点を末尾に追加）
	if _meas_graph:
		var preview = global.growth_history.duplicate()
		preview.append({
			"height": h, "avg_height": avg_h,
			"age": a, "term": global.term,
			"diff_prev": diff_prev, "diff_avg": diff_avg,
		})
		_meas_graph.set_data(preview)
		_meas_graph.animate_new_point(1.4) # カウントアップ(1.4秒)と同期

	_measurement_showing = true
	measurement_panel.show()
	get_tree().paused = true

	# 背景フェードイン（MainScene は PROCESS_MODE_ALWAYS なので pause 中でも動作する）
	var tween = create_tween()
	tween.tween_property(measurement_panel, "color", Color(0, 0, 0, 0.75), 0.4)

	# 身長カウントアップ（前回値 → 現在値）＋アバターがリアルタイムで成長
	if prev_h > 0.0:
		tween.tween_method(func(v: float):
			_meas_height_label.text = "%.1f cm" % v
			_update_mini_avatar(v)
		, prev_h, h, 1.4)
	else:
		tween.tween_interval(0.5)

	# 前回比ポップアップ
	tween.tween_property(_meas_diff_label, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(_meas_diff_label, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(_meas_diff_label, "scale", Vector2(1.0, 1.0), 0.1)

	# 詳細とボタンをフェードイン
	tween.tween_interval(0.2)
	tween.tween_property(measurement_content_label, "modulate:a", 1.0, 0.4)
	tween.tween_property(_meas_btn_row, "modulate:a", 1.0, 0.3)

func _on_measurement_panel_closed() -> void:
	_measurement_showing = false
	measurement_panel.hide()
	get_tree().paused = false
	# はるかが追随中なら測定後セリフを再生
	var global = get_node_or_null("/root/Global")
	if global and global.haruka_following:
		global.haruka_following = false
		_start_dialogue("haruka", "measure_after")

func _on_next_term_pressed() -> void:
	_measurement_showing = false
	measurement_panel.hide()
	get_tree().paused = false
	_nearby_height_scale = false

	# フェードオーバーレイを生成
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.z_index = 100
	ui_layer.add_child(fade)

	# フェードアウト（0.5秒）
	var tw = create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.5)
	await tw.finished

	# 学期を進めて自室へ
	var global = get_node_or_null("/root/Global")
	if global:
		global.advance_term()
		global.current_stage_id = "myroom"

	if player:
		player.update_measurements()

	_load_stage()

	# 黒画面中に学期テキストを表示
	if global:
		var lbl = Label.new()
		lbl.text = "第 %d 学期" % (global.term + 1)
		lbl.add_theme_font_size_override("font_size", 36)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
		lbl.modulate.a = 0.0
		lbl.set_anchors_preset(Control.PRESET_CENTER)
		lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
		lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
		fade.add_child(lbl)
		var tw_lbl = create_tween()
		tw_lbl.tween_property(lbl, "modulate:a", 1.0, 0.3)
		tw_lbl.tween_interval(0.5)
		tw_lbl.tween_property(lbl, "modulate:a", 0.0, 0.3)

	# フェードイン（0.8秒）
	var tw2 = create_tween()
	tw2.tween_property(fade, "color:a", 0.0, 0.8)
	await tw2.finished
	fade.queue_free()

	# 少し歩き込んでから主人公モノローグ（入学年は入学式セリフ）
	await get_tree().create_timer(1.8).timeout
	var mono_key = "new_semester"
	if global and global.age in [12, 15]:
		mono_key = _get_entrance_dialogue_key(global.age)
	_start_dialogue("player", mono_key)

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
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "成長記録"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	history_header_label = Label.new()
	history_header_label.add_theme_font_size_override("font_size", 15)
	history_header_label.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	history_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(history_header_label)

	# 折れ線グラフ
	var GrowthGraphScript = load("res://scripts/GrowthGraph.gd")
	growth_graph = GrowthGraphScript.new()
	growth_graph.custom_minimum_size = Vector2(560, 300)
	vbox.add_child(growth_graph)

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

	history_header_label.text = "現在 %.1fcm  /  %d歳  /  第%d学期" % [
		float(global.current_params["height"]),
		int(global.age),
		int(global.term) + 1
	]
	growth_graph.set_data(global.growth_history)

	history_panel.show()
	get_tree().paused = true
