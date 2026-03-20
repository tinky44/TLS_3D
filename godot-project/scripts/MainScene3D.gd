extends Node3D
## MainScene3D.gd — 3D版メインシーン
##
## 2D版 MainScene.gd の機能を段階的に3Dへ移植。
## Phase 1: ステージ構築 + プレイヤー移動 + カメラ制御

@onready var player: CharacterBody3D = $Player3D
@onready var stage_root: Node3D = $Stage3D

var ui_layer: CanvasLayer
var status_label: Label
var sidebar: PanelContainer
var action_hint_label: Label
var bump_alert_label: Label
var _bump_alert_time_left: float = 0.0

# ─── ダイアログシステム（将来の統合用） ─────────────────────────
var dialogue_panel: Control
var dialogue_name_label: Label
var dialogue_text_label: Label
var _in_dialogue: bool = false

# ─── ステージ遷移 ────────────────────────────────────────────────
var _nearby_transition_door: String = ""

func _ready() -> void:
	_setup_ui()
	_load_stage()

	# プレイヤーの頭部バンプシグナル接続
	if player and player.has_signal("head_bump"):
		player.connect("head_bump", _on_head_bump)

# ─── UI構築 ──────────────────────────────────────────────────────
func _setup_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	# ステータスサイドバー（Qキートグル）
	sidebar = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.14, 0.85)
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	sidebar.add_theme_stylebox_override("panel", style)
	sidebar.position = Vector2(0, 60)
	sidebar.custom_minimum_size = Vector2(280, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(status_label)

	sidebar.add_child(vbox)
	ui_layer.add_child(sidebar)
	sidebar.hide()

	# アクションヒント（画面下部中央）
	action_hint_label = Label.new()
	action_hint_label.add_theme_font_size_override("font_size", 16)
	action_hint_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	action_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	action_hint_label.offset_top = -50
	action_hint_label.offset_bottom = -20
	ui_layer.add_child(action_hint_label)

	# バンプ通知
	bump_alert_label = Label.new()
	bump_alert_label.add_theme_font_size_override("font_size", 20)
	bump_alert_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	bump_alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bump_alert_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bump_alert_label.offset_top = 40
	bump_alert_label.hide()
	ui_layer.add_child(bump_alert_label)

	# ステージ名表示
	var stage_title := Label.new()
	stage_title.name = "StageTitleLabel"
	stage_title.add_theme_font_size_override("font_size", 18)
	stage_title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	stage_title.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	stage_title.offset_left = -200
	stage_title.offset_top = 10
	stage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_layer.add_child(stage_title)

# ─── ステージ読み込み ────────────────────────────────────────────
func _load_stage() -> void:
	var global = get_node_or_null("/root/Global")
	var stage_id: String = "myroom"
	if global:
		stage_id = String(global.current_stage_id)

	# ステージ構築
	StageBuilder3D.build_stage(stage_id, stage_root, int(global.age) if global else 6)

	# プレイヤー初期位置
	if player:
		var stage_data = StageBuilder.STAGES.get(
			StageBuilder.resolve_stage_id(stage_id, int(global.age) if global else 0),
			{}
		)
		var width_cm: float = float(stage_data.get("width", 700))
		player.position = Vector3(
			width_cm * 0.5 * StageBuilder3D.CM_TO_UNIT,  # ステージ中央
			0.0,  # 床の上
			0.0   # 奥行き中央
		)
		player.update_measurements()

	# ステージ名表示
	_update_stage_title(stage_id)

	# ライティング設定
	_setup_lighting(stage_id)

func _update_stage_title(stage_id: String) -> void:
	var global = get_node_or_null("/root/Global")
	var resolved_id := StageBuilder.resolve_stage_id(stage_id, int(global.age) if global else 0)
	var stage_data = StageBuilder.STAGES.get(resolved_id, {})
	var stage_name: String = String(stage_data.get("name", stage_id))

	var title_label = ui_layer.get_node_or_null("StageTitleLabel")
	if title_label:
		title_label.text = stage_name

# ─── ライティング ────────────────────────────────────────────────
func _setup_lighting(stage_id: String) -> void:
	# 既存のライトを削除
	for child in get_children():
		if child is DirectionalLight3D or child is WorldEnvironment:
			if child.has_meta("is_stage_obj"):
				child.queue_free()

	# 環境光
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR

	if stage_id == "outdoor" or stage_id == "adjacent_town" or stage_id == "gakuenmachi":
		env.background_color = Color(0.55, 0.78, 0.98)  # 空
		env.ambient_light_color = Color(0.8, 0.85, 0.95)
		env.ambient_light_energy = 0.6
	elif stage_id.begins_with("schoolyard"):
		env.background_color = Color(0.50, 0.72, 0.95)
		env.ambient_light_color = Color(0.8, 0.85, 0.95)
		env.ambient_light_energy = 0.5
	else:
		env.background_color = Color(0.15, 0.15, 0.20)  # 室内
		env.ambient_light_color = Color(0.9, 0.85, 0.78)
		env.ambient_light_energy = 0.4

	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	world_env.set_meta("is_stage_obj", true)
	add_child(world_env)

	# ディレクショナルライト
	var light := DirectionalLight3D.new()
	light.set_meta("is_stage_obj", true)

	if stage_id == "outdoor" or stage_id.begins_with("schoolyard") or stage_id == "adjacent_town":
		light.light_color = Color(1.0, 0.97, 0.90)
		light.light_energy = 1.2
		light.rotation_degrees = Vector3(-45, -30, 0)
		light.shadow_enabled = true
	else:
		light.light_color = Color(1.0, 0.95, 0.88)
		light.light_energy = 0.8
		light.rotation_degrees = Vector3(-70, 0, 0)
		light.shadow_enabled = false

	add_child(light)

# ─── フレーム処理 ────────────────────────────────────────────────
func _process(delta: float) -> void:
	_update_status_ui()
	_update_action_hints()
	_update_bump_alert(delta)
	_handle_input()

func _handle_input() -> void:
	# Qキー: サイドバートグル
	if Input.is_action_just_pressed("toggle_status"):
		sidebar.visible = not sidebar.visible

	# Vキー: 視点切替（将来実装）
	if Input.is_action_just_pressed("toggle_view"):
		pass  # Phase 4 で実装

func _update_status_ui() -> void:
	if not sidebar.visible:
		return

	var global = get_node_or_null("/root/Global")
	if not global or not player:
		return

	var height_cm: float = player.visual_height_cm
	var full_height_cm: float = float(global.current_params["height"])
	var avg_h: float = global.get_avg_height(int(global.age))
	var diff := full_height_cm - avg_h

	var text := ""
	text += "【身長】%.1f cm" % full_height_cm
	if diff > 0:
		text += "（平均 +%.1f）" % diff
	text += "\n"
	text += "【年齢】%d歳 / %s\n" % [int(global.age), Global.get_school_grade_name(int(global.age))]
	text += "【学期】%s\n" % Global.get_school_term_label(int(global.age), int(global.term))

	if player.target_crouch_cm > 0:
		text += "【屈み中】%.0f cm まで\n" % player.target_crouch_cm
	if player.is_crouch_impossible:
		text += "⚠ 天井が低すぎて入れない\n"

	text += "\n[Q] 閉じる  [V] 視点切替"
	status_label.text = text

func _update_action_hints() -> void:
	var hints: PackedStringArray = []

	if _nearby_transition_door != "":
		hints.append("[E] %sに移動" % _get_door_destination_name(_nearby_transition_door))

	if player and player.is_crouch_impossible:
		hints.append("⚠ ここでは先に進めない")

	action_hint_label.text = "\n".join(hints)

func _get_door_destination_name(door_id: String) -> String:
	if not door_id.begins_with("door_to_"):
		return door_id
	var dest := door_id.substr("door_to_".length())
	var stage_data = StageBuilder.STAGES.get(dest, {})
	return String(stage_data.get("name", dest))

# ─── 頭部バンプ ─────────────────────────────────────────────────
func _on_head_bump(obs_id: String, obs_height_cm: float) -> void:
	var player_h: float = player.visual_height_cm if player else 180.0
	bump_alert_label.text = "ゴンッ！（%s に頭をぶつけた）" % obs_id
	bump_alert_label.show()
	_bump_alert_time_left = 2.0

func _update_bump_alert(delta: float) -> void:
	if _bump_alert_time_left > 0:
		_bump_alert_time_left -= delta
		if _bump_alert_time_left <= 0:
			bump_alert_label.hide()
