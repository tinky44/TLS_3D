extends CharacterBody3D
## Player3D.gd — 3Dプレイヤー制御
##
## 2D版 SkeletalPlayer.gd のロジックを3Dに移植。
## 身長パラメータと連動したカメラ高さ、自動屈み、頭部バンプ検出を担当。

signal head_bump(obs_id: String, obs_height_cm: float)

# ─── 定数 ────────────────────────────────────────────────────────
const CM_TO_UNIT: float = 0.01  # 1cm → 0.01 Godot ユニット（1m = 1.0）
const BASE_MOVE_SPEED: float = 2.5     # m/s（2D版の250px/sに相当）
const GRAVITY: float = 9.8
const HEAD_BUMP_COOLDOWN := 0.35
const HEAD_BUMP_SHAKE_TIME := 0.18
const HEAD_BUMP_SHAKE_STRENGTH := 0.06  # メートル単位

# ─── 身体パラメータ ──────────────────────────────────────────────
var visual_height_cm: float = 180.0
var visual_height_m: float = 1.80
var eye_height_m: float = 1.62     # 身長 × 0.9
var speed: float = BASE_MOVE_SPEED
var dir: int = 1  # 1=右向き, -1=左向き

# ─── 屈み ────────────────────────────────────────────────────────
var auto_crouch: bool = true
var target_crouch_cm: float = -1.0
var is_crouch_impossible: bool = false

# ─── 状態 ────────────────────────────────────────────────────────
var pose: String = "normal"
var is_walking: bool = false
var m: Dictionary = {}  # Global.get_body_measurements() の結果

# ─── 内部 ────────────────────────────────────────────────────────
var _head_bump_cooldown_left: float = 0.0
var _head_bump_shake_left: float = 0.0
var _camera_base_y: float = 0.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var first_person_camera: Camera3D = $FirstPersonCamera
@onready var ceiling_ray: RayCast3D = $CeilingRay

# ─── 初期化 ──────────────────────────────────────────────────────
func _ready() -> void:
	update_measurements()

func update_measurements() -> void:
	if has_node("/root/Global"):
		var global = get_node("/root/Global")
		if global.has_method("get_body_measurements"):
			m = global.get_body_measurements()
		else:
			m = _mock_measurements(global.current_params["height"])
		visual_height_cm = float(global.current_params["height"])
	else:
		visual_height_cm = 180.0
		m = _mock_measurements(visual_height_cm)

	visual_height_m = visual_height_cm * CM_TO_UNIT
	eye_height_m = visual_height_m * 0.9

	_update_collision()
	_update_camera_height()
	_update_speed()

func _update_collision() -> void:
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var capsule := collision_shape.shape as CapsuleShape3D
		capsule.height = max(0.4, visual_height_m)
		capsule.radius = min(0.2, visual_height_m * 0.15)
		collision_shape.position.y = visual_height_m * 0.5

func _update_camera_height() -> void:
	if first_person_camera:
		first_person_camera.position.y = eye_height_m

func _update_speed() -> void:
	var base_speed := BASE_MOVE_SPEED
	if has_node("/root/Global"):
		var global = get_node("/root/Global")
		base_speed = float(global.system_settings.get("move_speed", 250.0)) / 100.0
	# 脚の長さに応じた速度スケーリング
	var leg_cm: float = float(m.get("leg", visual_height_cm * 0.48))
	var base_leg_cm: float = 180.0 * 0.48
	var leg_scale: float = clampf(leg_cm / base_leg_cm, 0.65, 1.8)
	speed = base_speed * leg_scale

# ─── 物理処理 ────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# 重力
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# 横移動（2.5D: X軸のみ）
	var direction := Input.get_axis("move_left", "move_right")
	# ui_left/ui_right もフォールバックとして対応
	if direction == 0:
		direction = Input.get_axis("ui_left", "ui_right")

	if pose != "normal" or is_crouch_impossible:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 10.0)
	elif direction != 0:
		velocity.x = direction * speed
		dir = int(sign(direction))
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 10.0)

	# Z軸は固定（2.5Dモード）
	velocity.z = 0

	is_walking = abs(velocity.x) > 0.01

	_handle_auto_crouch_3d()
	_update_visual_height(delta)
	_update_collision()
	_update_camera_height()
	move_and_slide()
	_process_head_bump(delta)

# ─── オートクラウチ（3D版） ──────────────────────────────────────
func _handle_auto_crouch_3d() -> void:
	if not auto_crouch or pose != "normal":
		target_crouch_cm = -1.0
		is_crouch_impossible = false
		return

	# 天井レイキャストをフレーム同期
	if ceiling_ray:
		ceiling_ray.force_raycast_update()
		if ceiling_ray.is_colliding():
			var hit_point: Vector3 = ceiling_ray.get_collision_point()
			var ceil_h_m: float = hit_point.y - global_position.y
			var ceil_h_cm: float = ceil_h_m / CM_TO_UNIT

			if ceil_h_cm < visual_height_cm + 10.0:
				target_crouch_cm = ceil_h_cm - 8.0

				# 屈み不能判定（身長の45%以下まで屈む必要がある場合）
				if target_crouch_cm < visual_height_cm * 0.45:
					is_crouch_impossible = true
				else:
					is_crouch_impossible = false
				return

	target_crouch_cm = -1.0
	is_crouch_impossible = false

func _update_visual_height(delta: float) -> void:
	var target_h_cm := visual_height_cm
	var full_height_cm: float = float(m.get("height", 180.0))

	match pose:
		"taiiku_suwari":
			target_h_cm = full_height_cm * 0.5
		"chair_sit":
			target_h_cm = full_height_cm * 0.55
		"sleep":
			target_h_cm = full_height_cm * 0.35
		"normal":
			target_h_cm = full_height_cm
			if target_crouch_cm > 0:
				target_h_cm = min(target_h_cm, target_crouch_cm)

	visual_height_cm = lerp(visual_height_cm, target_h_cm, 15.0 * delta)
	visual_height_m = visual_height_cm * CM_TO_UNIT
	eye_height_m = visual_height_m * 0.9

# ─── 頭部バンプ ─────────────────────────────────────────────────
func _process_head_bump(delta: float) -> void:
	_head_bump_cooldown_left = max(0.0, _head_bump_cooldown_left - delta)
	_head_bump_shake_left = max(0.0, _head_bump_shake_left - delta)

	if _head_bump_cooldown_left > 0.0:
		return

	# 天井衝突チェック
	if ceiling_ray and ceiling_ray.is_colliding():
		var hit_point: Vector3 = ceiling_ray.get_collision_point()
		var head_y: float = global_position.y + visual_height_m
		if abs(hit_point.y - head_y) < 0.1:
			var collider = ceiling_ray.get_collider()
			if collider and collider.has_meta("obs_id"):
				_trigger_head_bump(
					String(collider.get_meta("obs_id")),
					float(collider.get_meta("obs_height_cm"))
				)

	# カメラシェイク
	if _head_bump_shake_left > 0.0 and first_person_camera:
		var strength := HEAD_BUMP_SHAKE_STRENGTH * (_head_bump_shake_left / HEAD_BUMP_SHAKE_TIME)
		first_person_camera.position.y = eye_height_m + randf_range(-strength, strength)
	elif first_person_camera:
		first_person_camera.position.y = eye_height_m

func _trigger_head_bump(obs_id: String, obs_height_cm: float) -> void:
	_head_bump_cooldown_left = HEAD_BUMP_COOLDOWN
	_head_bump_shake_left = HEAD_BUMP_SHAKE_TIME
	velocity.y = max(velocity.y, -0.5)
	emit_signal("head_bump", obs_id, obs_height_cm)

# ─── ユーティリティ ──────────────────────────────────────────────
func _mock_measurements(h: float = 180.0) -> Dictionary:
	var ht = h / 7.5
	var n = ht * 0.22
	var leg = h * 0.48
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
			"shoulder": h - ht - 2 * n,
		}
	}
