extends Node3D
## MainScene3D.gd — 3D版メインシーン
##
## ステージ構築、NPC配置、ステージ遷移、身長変更演出を管理。

const NPC3D_SCENE = preload("res://scenes/NPC3D.tscn")
const CM_TO_UNIT: float = 0.01

@onready var player: CharacterBody3D = $Player3D
@onready var stage_root: Node3D = $Stage3D

var ui_layer: CanvasLayer
var status_label: Label
var sidebar: PanelContainer
var action_hint_label: Label
var bump_alert_label: Label
var height_display_label: Label
var _bump_alert_time_left: float = 0.0

# ─── ステージ遷移 ────────────────────────────────────────────────
var _nearby_transition_door: String = ""
var _transition_running: bool = false
var _fade_rect: ColorRect

# ─── NPC管理 ─────────────────────────────────────────────────────
var _spawned_npcs: Array = []

# ─── NPC視点カメラ ─────────────────────────────────────────────────
var _npc_view_cam: Camera3D = null
var _npc_view_active: bool = false
var _e_hold_time: float = 0.0
var _e_hold_npc: Node = null

# ─── 頭ぶつけ・成長演出 ──────────────────────────────────────────
var _bumped_obstacles: Array = []
var _last_notified_height: float = 0.0
const GROWTH_NOTIFY_THRESHOLD: float = 5.0

# ─── ステージ別NPC配置テーブル ────────────────────────────────────
const STAGE_NPC_SPAWNS: Dictionary = {
	"myroom": [],
	"room": [
		{"npc_id": "mother", "x_cm": 850, "z_cm": 0},
		{"npc_id": "father", "x_cm": 920, "z_cm": -50},
	],
	"school": [
		{"npc_id": "haruka", "x_cm": 1200, "z_cm": 0},
		{"npc_id": "generic_f", "x_cm": 400, "z_cm": -50, "height_cm": 160.0, "sex": "female"},
		{"npc_id": "generic_m", "x_cm": 600, "z_cm": 30, "height_cm": 175.0, "sex": "male"},
	],
	"school_hallway": [
		{"npc_id": "haruka", "x_cm": 800, "z_cm": 0},
		{"npc_id": "generic_f2", "x_cm": 1500, "z_cm": -40, "height_cm": 158.0, "sex": "female"},
		{"npc_id": "generic_m2", "x_cm": 2200, "z_cm": 20, "height_cm": 170.0, "sex": "male"},
	],
	"outdoor": [
		{"npc_id": "haruka", "x_cm": 400, "z_cm": 0},
		{"npc_id": "generic_f3", "x_cm": 650, "z_cm": -40, "height_cm": 162.0, "sex": "female"},
		{"npc_id": "generic_m3", "x_cm": 900, "z_cm": 30, "height_cm": 173.0, "sex": "male"},
		{"npc_id": "generic_f4", "x_cm": 1100, "z_cm": -20, "height_cm": 155.0, "sex": "female"},
		{"npc_id": "generic_m4", "x_cm": 1300, "z_cm": 10, "height_cm": 178.0, "sex": "male"},
	],
	"park": [
		{"npc_id": "generic_f5", "x_cm": 600, "z_cm": -60, "height_cm": 165.0, "sex": "female"},
		{"npc_id": "generic_m5", "x_cm": 900, "z_cm": 40, "height_cm": 172.0, "sex": "male"},
		{"npc_id": "generic_f6", "x_cm": 1400, "z_cm": -30, "height_cm": 158.0, "sex": "female"},
		{"npc_id": "generic_m6", "x_cm": 1800, "z_cm": 50, "height_cm": 180.0, "sex": "male"},
		{"npc_id": "generic_f7", "x_cm": 2200, "z_cm": -50, "height_cm": 163.0, "sex": "female"},
		{"npc_id": "haruka", "x_cm": 2600, "z_cm": 20},
	],
	"gymnasium": [
		{"npc_id": "senior", "x_cm": 1600, "z_cm": 0},
		{"npc_id": "generic_f8", "x_cm": 800, "z_cm": -50, "height_cm": 170.0, "sex": "female"},
	],
	"infirmary": [
		{"npc_id": "nurse", "x_cm": 800, "z_cm": -30},
	],
	"station": [],
	"train": [],
}

func _ready() -> void:
	_setup_ui()
	_load_stage()
	_setup_npc_view_camera()

	if player and player.has_signal("head_bump"):
		player.connect("head_bump", _on_head_bump)

# ─── UI構築 ──────────────────────────────────────────────────────
func _setup_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)

	# サイドバー（Qキートグル）
	sidebar = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.14, 0.88)
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	sidebar.add_theme_stylebox_override("panel", style)
	sidebar.position = Vector2(0, 60)
	sidebar.custom_minimum_size = Vector2(300, 0)

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
	action_hint_label.add_theme_font_size_override("font_size", 18)
	action_hint_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.65))
	action_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	action_hint_label.offset_top = -60
	action_hint_label.offset_bottom = -15
	ui_layer.add_child(action_hint_label)

	# 身長表示（画面上部中央、常時表示）
	height_display_label = Label.new()
	height_display_label.add_theme_font_size_override("font_size", 22)
	height_display_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	height_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	height_display_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	height_display_label.offset_top = 10
	height_display_label.offset_left = -200
	height_display_label.offset_right = 200
	ui_layer.add_child(height_display_label)

	# バンプ通知
	bump_alert_label = Label.new()
	bump_alert_label.add_theme_font_size_override("font_size", 22)
	bump_alert_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
	bump_alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bump_alert_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bump_alert_label.offset_top = 50
	bump_alert_label.offset_left = -300
	bump_alert_label.offset_right = 300
	bump_alert_label.hide()
	ui_layer.add_child(bump_alert_label)

	# ステージ名（右上）
	var stage_title := Label.new()
	stage_title.name = "StageTitleLabel"
	stage_title.add_theme_font_size_override("font_size", 18)
	stage_title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	stage_title.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	stage_title.offset_left = -250
	stage_title.offset_top = 10
	stage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_layer.add_child(stage_title)

	# 操作ヒント（左下）
	var controls_hint := Label.new()
	controls_hint.add_theme_font_size_override("font_size", 13)
	controls_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	controls_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls_hint.offset_top = -120
	controls_hint.offset_bottom = -10
	controls_hint.offset_right = 250
	controls_hint.text = "WASD: 移動  マウス: 見回し\nPgUp/PgDn: 身長変更\nE: 移動/[長押]NPC視点  Q: ステータス\nEsc: カーソル切替"
	ui_layer.add_child(controls_hint)

	# フェード用（ステージ遷移等）
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.z_index = 100
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_fade_rect)

	# 頭ぶつけ赤フラッシュ用
	var bump_flash_rect := ColorRect.new()
	bump_flash_rect.name = "BumpFlashRect"
	bump_flash_rect.color = Color(1.0, 0.1, 0.0, 0.0)
	bump_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bump_flash_rect.z_index = 50
	bump_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(bump_flash_rect)

# ─── NPC視点カメラ構築 ────────────────────────────────────────────
func _setup_npc_view_camera() -> void:
	_npc_view_cam = Camera3D.new()
	_npc_view_cam.name = "NpcViewCamera"
	_npc_view_cam.fov = 70.0
	_npc_view_cam.current = false
	add_child(_npc_view_cam)

# ─── ステージ読み込み ────────────────────────────────────────────
func _load_stage(spawn_x_cm: float = -1.0) -> void:
	var global = get_node_or_null("/root/Global")
	var stage_id: String = "myroom"
	var age: int = 6
	if global:
		stage_id = String(global.current_stage_id)
		age = int(global.age)

	var resolved_id := StageBuilder.resolve_stage_id(stage_id, age)

	# NPCを削除
	_clear_npcs()

	# ステージ構築
	StageBuilder3D.build_stage(stage_id, stage_root, age)

	# プレイヤー初期位置
	if player:
		var stage_data = StageBuilder.STAGES.get(resolved_id, {})
		var width_cm: float = float(stage_data.get("width", 700))
		var start_x: float = width_cm * 0.5
		if spawn_x_cm >= 0:
			start_x = spawn_x_cm
		player.position = Vector3(start_x * CM_TO_UNIT, 0.0, 0.0)
		player.update_measurements()

	# NPC配置
	_spawn_npcs(resolved_id, age)

	# UI更新
	_update_stage_title(resolved_id)
	_setup_lighting(resolved_id)

# ─── NPC配置 ─────────────────────────────────────────────────────
func _spawn_npcs(stage_id: String, age: int) -> void:
	var global = get_node_or_null("/root/Global")
	if not global:
		return

	# ステージ別のスポーン情報を取得（基本ステージ名でも検索）
	var spawns: Array = []
	if STAGE_NPC_SPAWNS.has(stage_id):
		spawns = STAGE_NPC_SPAWNS[stage_id]
	else:
		# サフィックス付きステージ（school_elementary等）→ 基本名で検索
		for key in STAGE_NPC_SPAWNS:
			if stage_id.begins_with(key):
				spawns = STAGE_NPC_SPAWNS[key]
				break

	for spawn_info in spawns:
		var npc_id: String = String(spawn_info["npc_id"])
		if global.core_npcs.has(npc_id):
			_create_npc(npc_id, global.core_npcs[npc_id], spawn_info, age)
		else:
			# 汎用NPC（generic_* / nurse等）— spawn_infoに身長/性別を指定可
			var generic_data := {
				"name": _get_generic_npc_name(npc_id),
				"height_base": float(spawn_info.get("height_cm", 163.0)),
				"height_mode": "fixed",
				"sex": String(spawn_info.get("sex", "female")),
			}
			_create_npc(npc_id, generic_data, spawn_info, age)

func _create_npc(npc_id: String, npc_data: Dictionary, spawn_info: Dictionary, age: int) -> void:
	var npc_node: CharacterBody3D = NPC3D_SCENE.instantiate()
	stage_root.add_child(npc_node)
	npc_node.setup(npc_id, npc_data, age)
	npc_node.position = Vector3(
		float(spawn_info.get("x_cm", 500)) * CM_TO_UNIT,
		0.0,
		float(spawn_info.get("z_cm", 0)) * CM_TO_UNIT
	)
	_spawned_npcs.append(npc_node)
	# 巡回原点を設定（配置位置をセット）
	if npc_node.has_method("set_patrol_origin"):
		npc_node.set_patrol_origin()

func _clear_npcs() -> void:
	for npc in _spawned_npcs:
		if is_instance_valid(npc):
			npc.queue_free()
	_spawned_npcs.clear()

func _get_generic_npc_name(npc_id: String) -> String:
	if npc_id == "nurse":
		return "養護教諭"
	return "通行人"

# ─── ステージ遷移 ────────────────────────────────────────────────
func _check_nearby_doors() -> void:
	if not player:
		_nearby_transition_door = ""
		return

	_nearby_transition_door = ""
	var player_x: float = player.global_position.x

	var global = get_node_or_null("/root/Global")
	var stage_id: String = String(global.current_stage_id) if global else "myroom"
	var resolved_id := StageBuilder.resolve_stage_id(stage_id, int(global.age) if global else 0)
	var stage_data: Dictionary = StageBuilder.STAGES.get(resolved_id, {})

	for obs in stage_data.get("obstacles", []):
		var obs_id: String = String(obs.get("id", ""))
		if not obs_id.begins_with("door_to_"):
			continue

		var door_x_start: float = float(obs["x"]) * CM_TO_UNIT
		var door_x_end: float = float(obs["x2"]) * CM_TO_UNIT
		var door_center_x: float = (door_x_start + door_x_end) * 0.5

		if abs(player_x - door_center_x) < 0.8:  # 80cm以内
			_nearby_transition_door = obs_id
			break

func _do_stage_transition(door_id: String) -> void:
	if _transition_running:
		return
	if not door_id.begins_with("door_to_"):
		return

	var destination: String = door_id.substr("door_to_".length())
	var global = get_node_or_null("/root/Global")
	if not global:
		return

	_transition_running = true

	# フェードアウト
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, 0.4)
	await tw.finished

	# ステージ切替
	global.current_stage_id = destination
	var age: int = int(global.age)
	var resolved := StageBuilder.resolve_stage_id(destination, age)

	# 到着先のスポーン位置を決定（逆方向のドアの位置）
	var spawn_x_cm: float = -1.0
	var dest_data: Dictionary = StageBuilder.STAGES.get(resolved, {})
	var current_stage: String = String(global.current_stage_id)
	for obs in dest_data.get("obstacles", []):
		# 元のステージへ戻るドアの近くにスポーン
		var obs_id: String = String(obs.get("id", ""))
		if obs_id.begins_with("door_to_"):
			# 今来たステージへの帰還ドアを探す
			spawn_x_cm = float(obs.get("x", 0)) + 50.0
			break
	if spawn_x_cm < 0:
		spawn_x_cm = float(dest_data.get("width", 700)) * 0.5

	_load_stage(spawn_x_cm)

	# フェードイン
	var tw2 := create_tween()
	tw2.tween_property(_fade_rect, "color:a", 0.0, 0.4)
	await tw2.finished

	_transition_running = false

# ─── ライティング ────────────────────────────────────────────────
func _setup_lighting(stage_id: String) -> void:
	for child in get_children():
		if (child is DirectionalLight3D or child is WorldEnvironment) and child.has_meta("is_stage_obj"):
			child.queue_free()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var is_outdoor := (
		stage_id == "outdoor" or stage_id == "adjacent_town"
		or stage_id == "gakuenmachi" or stage_id.begins_with("schoolyard")
		or stage_id == "platform" or stage_id == "gakuenmae"
		or stage_id == "park"
	)

	if is_outdoor:
		env.background_color = Color(0.55, 0.78, 0.98)
		env.ambient_light_color = Color(0.8, 0.85, 0.95)
		env.ambient_light_energy = 0.6
	else:
		env.background_color = Color(0.12, 0.12, 0.16)
		env.ambient_light_color = Color(0.9, 0.85, 0.78)
		env.ambient_light_energy = 0.5

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	world_env.set_meta("is_stage_obj", true)
	add_child(world_env)

	var light := DirectionalLight3D.new()
	light.set_meta("is_stage_obj", true)
	if is_outdoor:
		light.light_color = Color(1.0, 0.97, 0.90)
		light.light_energy = 1.2
		light.rotation_degrees = Vector3(-45, -30, 0)
		light.shadow_enabled = true
	else:
		light.light_color = Color(1.0, 0.95, 0.88)
		light.light_energy = 0.9
		light.rotation_degrees = Vector3(-70, 0, 0)
		light.shadow_enabled = false
	add_child(light)

func _update_stage_title(stage_id: String) -> void:
	var stage_data = StageBuilder.STAGES.get(stage_id, {})
	var stage_name: String = String(stage_data.get("name", stage_id))
	var title_label = ui_layer.get_node_or_null("StageTitleLabel")
	if title_label:
		title_label.text = stage_name

# ─── フレーム処理 ────────────────────────────────────────────────
func _process(delta: float) -> void:
	_check_nearby_doors()
	_update_status_ui()
	_update_action_hints()
	_update_bump_alert(delta)
	_update_height_display()
	_handle_input(delta)
	_update_npc_view(delta)

func _handle_input(delta: float) -> void:
	# Qキー: サイドバートグル
	if Input.is_action_just_pressed("toggle_status"):
		sidebar.visible = not sidebar.visible

	# Eキー: NPC視点（近くにNPCがいる場合）/ ステージ遷移
	var near_npc := _get_nearest_npc(2.5)
	if Input.is_action_pressed("interact") and near_npc != null and _nearby_transition_door == "":
		_e_hold_time += delta
		_e_hold_npc = near_npc
	elif _npc_view_active:
		_deactivate_npc_view()
		_e_hold_time = 0.0
		_e_hold_npc = null
	else:
		if Input.is_action_just_pressed("interact") and _nearby_transition_door != "":
			_do_stage_transition(_nearby_transition_door)
		_e_hold_time = 0.0
		_e_hold_npc = null

	# PgUp / PgDown: 身長変更（テスト＆演出用）
	if Input.is_key_pressed(KEY_PAGEUP):
		_change_height(1.0)
	if Input.is_key_pressed(KEY_PAGEDOWN):
		_change_height(-1.0)

	# Home: 身長リセット
	if Input.is_key_pressed(KEY_HOME):
		var global = get_node_or_null("/root/Global")
		if global:
			global.current_params["height"] = 180.0
			if player:
				player.update_measurements()

func _get_nearest_npc(max_dist: float) -> Node:
	if not player:
		return null
	var nearest: Node = null
	var nearest_dist: float = max_dist
	for npc in _spawned_npcs:
		if is_instance_valid(npc):
			var d := player.global_position.distance_to(npc.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = npc
	return nearest

func _update_npc_view(_delta: float) -> void:
	if _e_hold_time >= 0.5 and _e_hold_npc != null and is_instance_valid(_e_hold_npc):
		if not _npc_view_active:
			_activate_npc_view(_e_hold_npc)
	elif _npc_view_active and (_e_hold_npc == null or not is_instance_valid(_e_hold_npc)):
		_deactivate_npc_view()

	if _npc_view_active and _npc_view_cam and _e_hold_npc != null and is_instance_valid(_e_hold_npc):
		# NPC目線位置にカメラを配置
		var npc3d := _e_hold_npc as CharacterBody3D
		if npc3d:
			var eye_h: float = npc3d.get("eye_height_m")
			_npc_view_cam.global_position = npc3d.global_position + Vector3(0, eye_h, 0)
			# プレイヤーを見上げる
			if player:
				var player_eye: Vector3 = player.global_position + Vector3(0, player.eye_height_m * 0.5, 0)
				_npc_view_cam.look_at(player_eye, Vector3.UP)

func _activate_npc_view(npc: Node) -> void:
	if _npc_view_active:
		return
	_npc_view_active = true
	_npc_view_cam.current = true
	if player:
		var fp_cam := player.get_node_or_null("CameraPivot/FirstPersonCamera") as Camera3D
		if fp_cam:
			fp_cam.current = false
	# ヒント表示
	action_hint_label.text = "👁 NPC視点 — E を離すと戻る"

func _deactivate_npc_view() -> void:
	if not _npc_view_active:
		return
	_npc_view_active = false
	_npc_view_cam.current = false
	if player:
		var fp_cam := player.get_node_or_null("CameraPivot/FirstPersonCamera") as Camera3D
		if fp_cam:
			fp_cam.current = true

func _change_height(delta_cm: float) -> void:
	var global = get_node_or_null("/root/Global")
	if not global or not player:
		return

	var new_height: float = clamp(
		float(global.current_params["height"]) + delta_cm,
		100.0, 300.0
	)
	global.current_params["height"] = new_height

	# 頭身を自動更新（Global.advance_term のロジックと同じ）
	global.current_params["ratio"] = clamp(5.5 + (new_height - 100.0) / 30.0, 5.0, 9.0)

	player.update_measurements()

	# 成長演出
	var current_h: float = float(global.current_params.get("height", 170))
	if _last_notified_height == 0.0:
		_last_notified_height = current_h
	if abs(current_h - _last_notified_height) >= GROWTH_NOTIFY_THRESHOLD:
		_trigger_growth_effect(current_h)
		_last_notified_height = current_h

func _update_height_display() -> void:
	if not player or not height_display_label:
		return
	var global = get_node_or_null("/root/Global")
	if not global:
		return

	var h: float = float(global.current_params["height"])
	var avg: float = global.get_avg_height(int(global.age))
	var diff: float = h - avg
	var diff_str: String = ""
	if diff > 0:
		diff_str = "  (平均+%.1fcm)" % diff
	elif diff < 0:
		diff_str = "  (平均%.1fcm)" % diff

	height_display_label.text = "📏 %.1f cm%s" % [h, diff_str]

func _update_status_ui() -> void:
	if not sidebar.visible:
		return
	var global = get_node_or_null("/root/Global")
	if not global or not player:
		return

	var h: float = float(global.current_params["height"])
	var avg: float = global.get_avg_height(int(global.age))
	var diff: float = h - avg

	var text := ""
	text += "【身長】%.1f cm" % h
	if diff > 0:
		text += "（平均 +%.1f）" % diff
	text += "\n"
	text += "【年齢】%d歳 / %s\n" % [int(global.age), Global.get_school_grade_name(int(global.age))]
	text += "【学期】%s\n" % Global.get_school_term_label(int(global.age), int(global.term))
	text += "【目線の高さ】%.0f cm\n" % (player.eye_height_m / CM_TO_UNIT)

	if player.target_crouch_cm > 0:
		text += "\n⚡ 屈み中（%.0f cm まで）\n" % player.target_crouch_cm
	if player.is_crouch_impossible:
		text += "\n⚠ 天井が低すぎて入れない\n"

	# 近くのNPC情報
	for npc in _spawned_npcs:
		if is_instance_valid(npc):
			var dist: float = player.global_position.distance_to(npc.global_position)
			if dist < 3.0:
				var npc_h: float = npc.height_cm
				var h_diff: float = h - npc_h
				text += "\n👤 %s（%.0fcm）" % [npc.npc_name, npc_h]
				if h_diff > 0:
					text += " — あなたより %.0fcm 低い" % h_diff
				elif h_diff < 0:
					text += " — あなたより %.0fcm 高い" % abs(h_diff)

	text += "\n\n[Q] 閉じる  [PgUp/PgDn] 身長変更"
	status_label.text = text

func _update_action_hints() -> void:
	var hints: PackedStringArray = []

	if _nearby_transition_door != "":
		hints.append("[E] %s に移動" % _get_door_destination_name(_nearby_transition_door))

	if player and player.is_crouch_impossible:
		hints.append("⚠ ここでは先に進めない")

	# 近くのNPCがいる場合（E長押しでNPC視点）
	if not _npc_view_active:
		for npc in _spawned_npcs:
			if is_instance_valid(npc) and player:
				var dist: float = player.global_position.distance_to(npc.global_position)
				if dist < 2.5 and _nearby_transition_door == "":
					hints.append("👤 %s（%.0fcm） — [E] 長押しでNPC視点" % [npc.npc_name, npc.height_cm])
					break

	action_hint_label.text = "\n".join(hints)

func _get_door_destination_name(door_id: String) -> String:
	if not door_id.begins_with("door_to_"):
		return door_id
	var dest := door_id.substr("door_to_".length())
	# age付きのステージ名解決
	var global = get_node_or_null("/root/Global")
	var age: int = int(global.age) if global else 0
	var resolved := StageBuilder.resolve_stage_id(dest, age)
	var stage_data = StageBuilder.STAGES.get(resolved, {})
	return String(stage_data.get("name", dest))

# ─── 頭部バンプ ─────────────────────────────────────────────────
func _on_head_bump(obs_id: String, obs_height_cm: float) -> void:
	var player_h: float = player.visual_height_cm if player else 180.0
	var diff: float = player_h - obs_height_cm

	# 初回ぶつかり判定
	var is_first_bump := not _bumped_obstacles.has(obs_id)
	if is_first_bump:
		_bumped_obstacles.append(obs_id)
		bump_alert_label.text = "初めて頭をぶつけた！（%.0fcm）" % obs_height_cm
	else:
		bump_alert_label.text = "ゴンッ！ %s に頭をぶつけた（障害物 %.0fcm / あなた %.0fcm）" % [obs_id, obs_height_cm, player_h]

	bump_alert_label.show()
	_bump_alert_time_left = 2.5

	# 赤フラッシュ（身長が高いほど強い）
	var flash := ui_layer.get_node_or_null("BumpFlashRect")
	if flash:
		var flash_alpha := clampf(0.3 + (player_h - 170.0) / 200.0, 0.3, 0.65)
		flash.color.a = flash_alpha
		var tw := create_tween()
		tw.tween_property(flash, "color:a", 0.0, 0.5)\
		  .set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func _update_bump_alert(delta: float) -> void:
	if _bump_alert_time_left > 0:
		_bump_alert_time_left -= delta
		# フェードアウト演出
		if _bump_alert_time_left < 0.5:
			bump_alert_label.modulate.a = _bump_alert_time_left / 0.5
		if _bump_alert_time_left <= 0:
			bump_alert_label.hide()
			bump_alert_label.modulate.a = 1.0

# ─── 成長演出 ─────────────────────────────────────────────────────
func _trigger_growth_effect(new_height: float) -> void:
	var notify := Label.new()
	notify.text = "%.0f cm !" % new_height
	notify.add_theme_font_size_override("font_size", 48)
	notify.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	notify.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notify.set_anchors_preset(Control.PRESET_CENTER)
	notify.offset_left = -150
	notify.offset_right = 150
	notify.offset_top = -40
	ui_layer.add_child(notify)

	var tw := create_tween()
	tw.tween_property(notify, "position:y", notify.position.y - 60, 1.2)\
	  .set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(notify, "modulate:a", 0.0, 1.2)\
	  .set_ease(Tween.EASE_IN)
	tw.tween_callback(notify.queue_free)

	# カメラFOVパルス（成長を体感）
	if player:
		var cam := player.get_node_or_null("CameraPivot/FirstPersonCamera") as Camera3D
		if cam:
			var orig_fov := cam.fov
			cam.fov = orig_fov + 8.0
			var tw2 := create_tween()
			tw2.tween_property(cam, "fov", orig_fov, 0.5)\
			  .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
