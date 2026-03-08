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
		"shoulder": ht * 1.872, "arm": arm, "armLength": ht * 3.2, "leg": leg,
		"landmarks": {"top": h, "eye": h - ht * 0.5, "shoulder": h - ht - 2 * n}
	}
