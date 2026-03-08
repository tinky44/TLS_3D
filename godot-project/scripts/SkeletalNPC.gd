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

var auto_crouch: bool = false
var target_crouch_cm: float = -1.0
var visual_height_cm: float = 158.0

var m: Dictionary
var appearance: Dictionary

var look_pitch: float = 0.0
var look_head_angle: float = 0.0
var _reaction_label: Label = null
var _current_reaction_key: String = ""
var _reaction_time_left: float = 0.0
var _avoid_dir: float = 0.0

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

	var dist_x: float = global_position.x - p_node.global_position.x
	var abs_dist: float = abs(dist_x)
	if abs_dist > REACTION_DIST:
		_reset_reaction(delta)
		return

	var player_m: Dictionary = p_node.get("m")
	var self_eye_y: float = global_position.y - float(m["landmarks"]["eye"]) * CM_TO_PX
	var player_eye_y: float = p_node.global_position.y - float(player_m["landmarks"]["eye"]) * CM_TO_PX
	var diff_y_px: float = player_eye_y - self_eye_y
	var diff_y_cm: float = -diff_y_px / CM_TO_PX

	var angle: float = clamp(atan2(diff_y_px, max(abs_dist, 1.0)), -PI / 3.0, PI / 3.0)
	look_head_angle = angle
	var max_pitch: float = float(m["head"]) * CM_TO_PX * 0.2
	look_pitch = sin(angle) * max_pitch

	if dist_x < 0:
		dir = 1
	else:
		dir = -1
	facing = "side"

	var reaction_key: String = _get_reaction_key(diff_y_cm)
	if reaction_key != _current_reaction_key:
		_current_reaction_key = reaction_key
		_reaction_label.text = _get_reaction_text(reaction_key)
		_reaction_time_left = 1.2

	_reaction_label.position.y = -(visual_height_cm * CM_TO_PX) - 40.0
	_reaction_label.visible = _reaction_time_left > 0.0 and _reaction_label.text != ""

	if reaction_key == "very_huge":
		_avoid_dir = sign(dist_x)
	elif reaction_key == "huge":
		_avoid_dir = sign(dist_x) * 0.45
	else:
		_avoid_dir = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	velocity.x = _avoid_dir * SPEED * CM_TO_PX
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

	appearance = custom_appearance
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
		collision_shape.position.y = -h_px / 2.0

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
