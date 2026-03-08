extends CharacterBody2D

var SPEED: float = 0.0
const GRAVITY = 1200.0
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
var _has_reacted: bool = false
const REACTION_DIST = 150.0

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
	collision_layer = 0 # 当たり判定なし（プレイヤーがすり抜けられるようにする）
	collision_mask |= 4
	update_measurements()

	_reaction_label = Label.new()
	_reaction_label.text = ""
	_reaction_label.add_theme_font_size_override("font_size", 16)
	_reaction_label.add_theme_color_override("font_color", Color.BLACK)
	_reaction_label.add_theme_color_override("font_outline_color", Color.WHITE)
	_reaction_label.add_theme_constant_override("outline_size", 4)
	_reaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reaction_label.position = Vector2(-100, -100)
	_reaction_label.size = Vector2(200, 30)
	_reaction_label.z_index = 100
	add_child(_reaction_label)

func _process(delta: float) -> void:
	var p_node = get_parent().get_node_or_null("Player")
	if not p_node:
		var global = get_node_or_null("/root/Global")
		if global and global.get("player"):
			p_node = global.player
			
	if p_node and m and p_node.get("m"):
		var dist = global_position.x - p_node.global_position.x
		var abs_dist = abs(dist)
		if abs_dist < REACTION_DIST:
			var self_eye_y = global_position.y - m["landmarks"]["eye"] * CM_TO_PX
			var p_eye_y = p_node.global_position.y - p_node.m["landmarks"]["eye"] * CM_TO_PX
			var diff_y = p_eye_y - self_eye_y
			
			# abs_distとdiff_yで角度を計算。diff_yは下がプラスなので、見上げるときdiff_yはマイナス
			var angle = clamp(atan2(diff_y, abs_dist), -PI / 3, PI / 3) # 首の可動限界
			look_head_angle = angle
			
			var max_pitch = m["head"] * CM_TO_PX * 0.2
			look_pitch = sin(angle) * max_pitch
			
			if dist < 0: # 相手が右にいる
				dir = 1
				facing = "side"
			else:
				dir = -1
				facing = "side"
				
			if not _has_reacted:
				_has_reacted = true
				if diff_y < -15.0: # 相手のほうが15cm以上高い(画面上ではYが小さい)
					_reaction_label.text = "大きい…！"
				elif diff_y > 15.0:
					_reaction_label.text = "小柄だ"
				else:
					_reaction_label.text = "こんにちは"
					
			_reaction_label.position.y = - (visual_height_cm * CM_TO_PX) - 40.0
		else:
			look_pitch = lerp(look_pitch, 0.0, 5.0 * delta)
			look_head_angle = lerp(look_head_angle, 0.0, 5.0 * delta)
			_reaction_label.text = ""
			_has_reacted = false
			# そのままの向きを維持


func setup(params: Dictionary, app: Dictionary):
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

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		
	# Simple idle logic (can be expanded later)
	velocity.x = 0
	
	is_walking = (velocity.x != 0)
	if is_walking:
		walk_phase += walk_speed * delta
	else:
		walk_phase = lerp_angle(walk_phase, 0.0, 10.0 * delta)

	_update_visual_height(delta)
	_update_collision()
	move_and_slide()
	character_drawer.queue_redraw()

func _update_visual_height(delta: float):
	visual_height_cm = lerp(visual_height_cm, float(m["height"]), 15.0 * delta)

func _update_collision():
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
		"height": h, "head": ht, "headWidth": ht * 0.702, "neck": n,
		"shoulder": ht * 1.872, "arm": arm, "armLength": arm, "leg": leg,
		"landmarks": {"top": h, "eye": h - ht * 0.5, "shoulder": h - ht - 2 * n}
	}
