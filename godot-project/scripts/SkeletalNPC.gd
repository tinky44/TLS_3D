extends CharacterBody2D

var SPEED: float = 55.0
const GRAVITY = 1200.0
const REACTION_DIST := 170.0
const HUGE_DIFF_CM := 35.0
const VERY_HUGE_DIFF_CM := 60.0
var CM_TO_PX: float = 2.0

var facing: String = "side"
var dir: int = 1
var is_walking: bool = false
var walk_phase: float = 0.0
var walk_speed: float = 8.0
var pose: String = "normal"
var receives_global_stress: bool = false
var patrol_range: float = 80.0
var patrol_speed: float = 28.0
var patrol_dir: int = 1

var auto_crouch: bool = false
var target_crouch_cm: float = -1.0
var visual_height_cm: float = 158.0

var m: Dictionary
var appearance: Dictionary
var npc_data: Dictionary = {}

var npc_id: String = "" # コアNPCの識別子。空文字は匿名NPC
var follow_target: Node2D = null # セットされると追随モードになる
var look_pitch: float = 0.0
var look_head_angle: float = 0.0
var _reaction_label: Label = null
var _current_reaction_key: String = ""
var _reaction_time_left: float = 0.0
var _avoid_dir: float = 0.0
var _spawn_x: float = 0.0
var _proximity_time: float = 0.0
var _greet_cooldown_left: float = 0.0
var _greet_triggered_for_approach: bool = false
var _last_greet_index: int = -1
var _player_is_close: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var character_drawer: Node2D = $CharacterDrawer

@export var custom_params: Dictionary = {
	"height": 158.0,
	"ratio": 7.0,
	"legRatio": 45.0,
	"sex": "female"
}

@export var custom_appearance: Dictionary = {
	"hair_style": "long",
	"hair_color": "#111111",
	"tops_type": "sweater",
	"tops_color": "#ffffff",
	"bottoms_type": "skirt_long",
	"bottoms_color": "#333333",
	"shoes_type": "sneakers",
	"shoes_color": "#aa3333"
}

func _ready() -> void:
	collision_layer = 0
	collision_mask |= 4
	_spawn_x = global_position.x
	
	var global = get_node_or_null("/root/Global")
	if global and npc_id != "" and global.get("core_npcs") and global.core_npcs.has(npc_id):
		var data: Dictionary = global.core_npcs[npc_id]
		npc_data = data.duplicate(true)
		var params = custom_params.duplicate()
		# 身長モードの判定
		if data.get("height_mode") == "avg":
			params["height"] = global.get_avg_height(global.age) + data.get("height_base", 155.0) - 158.5
		else:
			params["height"] = data.get("height_base", 158.0)

		var resolved_appearance: Dictionary = data.get("appearance", {}).duplicate(true)
		if data.get("is_student", false):
			var uniform_age: int = _get_uniform_age_for_stage(String(global.current_stage_id), global.age)
			var uniform: Dictionary = Global.get_school_uniform(uniform_age)
			for key in uniform.keys():
				resolved_appearance[key] = uniform[key]
		var shoes_type: String = Global.get_shoes_for_stage(String(global.current_stage_id))
		resolved_appearance["shoes_type"] = shoes_type
		resolved_appearance["shoes_color"] = _get_default_shoe_color(shoes_type)

		# その他のパラメータ上書き（もしあれば）
		setup(params, resolved_appearance)
	else:
		npc_data = {}
		update_measurements()

	_reaction_label = Label.new()
	_reaction_label.text = ""
	_reaction_label.add_theme_font_size_override("font_size", 16)
	_reaction_label.add_theme_color_override("font_color", Color.BLACK)
	_reaction_label.add_theme_color_override("font_outline_color", Color.WHITE)
	_reaction_label.add_theme_constant_override("outline_size", 4)
	_reaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reaction_label.position = Vector2(-110, -100)
	_reaction_label.size = Vector2(220, 40)
	_reaction_label.z_index = 100
	add_child(_reaction_label)

func _process(delta: float) -> void:
	var p_node: Node2D = get_parent().get_node_or_null("Player") as Node2D
	if not p_node:
		return
	if not m or not p_node.get("m"):
		return

	_reaction_time_left = max(0.0, _reaction_time_left - delta)
	_greet_cooldown_left = max(0.0, _greet_cooldown_left - delta)

	var dist_x: float = global_position.x - p_node.global_position.x
	var abs_dist: float = abs(dist_x)
	_player_is_close = abs_dist <= REACTION_DIST
	if abs_dist > REACTION_DIST:
		_reset_proximity_state()
		_reset_reaction(delta)
		return

	var player_m: Dictionary = p_node.get("m")
	var self_eye_y: float = global_position.y - float(m["landmarks"]["eye"]) * CM_TO_PX
	var player_eye_y: float = p_node.global_position.y - float(player_m["landmarks"]["eye"]) * CM_TO_PX
	var diff_y_px: float = player_eye_y - self_eye_y

	var angle: float = clamp(atan2(diff_y_px, max(abs_dist, 1.0)), -PI / 3.0, PI / 3.0)
	look_head_angle = angle
	var max_pitch: float = float(m["head"]) * CM_TO_PX * 0.2
	look_pitch = sin(angle) * max_pitch

	if dist_x < 0:
		dir = 1
	else:
		dir = -1
	facing = "side"

	_reaction_label.position.y = - (visual_height_cm * CM_TO_PX) - 40.0
	if npc_id == "":
		# プレイヤーがNPCより小さければ反応しない。大きい場合のみ年齢平均との差で判定。
		var actual_height_diff: float = float(player_m["height"]) - float(m["height"])
		var reaction_key: String
		if actual_height_diff <= 0.0:
			reaction_key = "same"
		else:
			var global_node = get_node_or_null("/root/Global")
			var avg_height: float = 158.5
			if global_node:
				avg_height = global_node.get_avg_height(global_node.age)
			reaction_key = _get_reaction_key(float(player_m["height"]) - avg_height)
		if reaction_key != _current_reaction_key:
			_current_reaction_key = reaction_key
			_show_reaction_text(_get_reaction_text(reaction_key), 1.2)

		if reaction_key == "very_huge":
			_avoid_dir = sign(dist_x)
		elif reaction_key == "huge":
			_avoid_dir = sign(dist_x) * 0.45
		else:
			_avoid_dir = 0.0
	else:
		_avoid_dir = 0.0
		_process_passive_greet(delta)

	_reaction_label.visible = _reaction_time_left > 0.0 and _reaction_label.text != ""

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if follow_target:
		var dx = follow_target.global_position.x - global_position.x
		if abs(dx) > 100.0 * CM_TO_PX:
			velocity.x = sign(dx) * SPEED * CM_TO_PX
			dir = int(sign(dx))
			facing = "side"
		else:
			velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
	elif abs(_avoid_dir) > 0.01:
		velocity.x = _avoid_dir * SPEED * CM_TO_PX
	elif patrol_range > 0.0 and not _player_is_close:
		var patrol_limit: float = patrol_range * CM_TO_PX
		if global_position.x >= _spawn_x + patrol_limit:
			patrol_dir = -1
		elif global_position.x <= _spawn_x - patrol_limit:
			patrol_dir = 1
		velocity.x = patrol_dir * patrol_speed * CM_TO_PX
		dir = patrol_dir
		facing = "side"
	else:
		velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
	is_walking = abs(velocity.x) > 1.0
	if is_walking:
		walk_phase += walk_speed * delta
	else:
		walk_phase = lerp_angle(walk_phase, 0.0, 10.0 * delta)

	_update_visual_height(delta)
	_update_collision()
	move_and_slide()
	character_drawer.queue_redraw()

func _get_reaction_key(height_diff_cm: float) -> String:
	if height_diff_cm >= VERY_HUGE_DIFF_CM:
		return "very_huge"
	if height_diff_cm >= HUGE_DIFF_CM:
		return "huge"
	if height_diff_cm >= 15.0:
		return "tall"
	if height_diff_cm <= -15.0:
		return "shorter"
	return "same"

func _get_reaction_text(reaction_key: String) -> String:
	match reaction_key:
		"very_huge":
			return "でかっ…！"
		"huge":
			return "見上げちゃう"
		"tall":
			return "背、高いな"
		"shorter":
			return "今日は私の方が高い"
		_:
			return ""

func _reset_reaction(delta: float) -> void:
	look_pitch = lerp(look_pitch, 0.0, 5.0 * delta)
	look_head_angle = lerp(look_head_angle, 0.0, 5.0 * delta)
	_avoid_dir = lerp(_avoid_dir, 0.0, 6.0 * delta)
	_current_reaction_key = ""
	_reaction_time_left = 0.0
	_reaction_label.text = ""
	_reaction_label.visible = false

func setup(params: Dictionary, app: Dictionary) -> void:
	for k in params.keys():
		custom_params[k] = params[k]
	for k in app.keys():
		custom_appearance[k] = app[k]
	update_measurements()

func update_measurements() -> void:
	if has_node("/root/Global"):
		var global = get_node("/root/Global")
		CM_TO_PX = global.CM_TO_PX
		m = global.get_custom_body_measurements(custom_params)
	else:
		m = _mock_measurements()

	appearance = custom_appearance.duplicate(true)
	visual_height_cm = m["height"]

	_update_collision()
	if character_drawer:
		character_drawer.queue_redraw()

func _update_visual_height(delta: float) -> void:
	visual_height_cm = lerp(visual_height_cm, float(m["height"]), 15.0 * delta)

func _update_collision() -> void:
	var h_px = visual_height_cm * CM_TO_PX
	var shape = collision_shape.shape as CapsuleShape2D
	if shape:
		shape.height = max(40.0, h_px)
		collision_shape.position.y = - h_px / 2.0

func _mock_measurements() -> Dictionary:
	var h = 158.0
	var ht = h / 7.0
	var n = ht * 0.22
	var leg = h * 0.45
	var arm = h - leg - ht - 2 * n
	return {
		"height": h,
		"head": ht,
		"headWidth": ht * 0.702,
		"neck": n,
		"shoulder": ht * 1.872,
		"arm": arm,
		"armLength": arm,
		"leg": leg,
		"landmarks": {
			"top": h,
			"eye": h - ht * 0.5,
			"shoulder": h - ht - 2 * n
		}
	}

func _process_passive_greet(delta: float) -> void:
	if npc_data.is_empty():
		return
	if _greet_cooldown_left > 0.0:
		return
	_proximity_time += delta
	if _proximity_time < 2.0 or _greet_triggered_for_approach:
		return
	var greet_events: Variant = npc_data.get("greet_events", [])
	if not (greet_events is Array) or greet_events.is_empty():
		return
	var next_index: int = 0
	if greet_events.size() > 1:
		next_index = randi_range(0, greet_events.size() - 1)
		if next_index == _last_greet_index:
			next_index = (next_index + 1) % greet_events.size()
	_last_greet_index = next_index
	_greet_triggered_for_approach = true
	_greet_cooldown_left = 5.0
	_show_reaction_text(String(greet_events[next_index]), 2.6)

func _reset_proximity_state() -> void:
	_player_is_close = false
	_proximity_time = 0.0
	_greet_triggered_for_approach = false

func _show_reaction_text(text: String, duration: float) -> void:
	_reaction_label.text = text
	_reaction_time_left = duration

func _get_default_shoe_color(shoes_type: String) -> String:
	match shoes_type:
		"uwabaki":
			return "#f7f7f2"
		"loafer":
			return "#4b4b52"
		"socks":
			return "#f5f4fb"
		_:
			return "#f0f0f0"

func _get_uniform_age_for_stage(stage_id: String, fallback_age: int) -> int:
	if stage_id.ends_with("_elementary"):
		return 10
	if stage_id.ends_with("_middle"):
		return 13
	if stage_id.ends_with("_high"):
		return 16
	return fallback_age
