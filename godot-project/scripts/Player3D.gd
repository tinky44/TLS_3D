extends CharacterBody3D
## Player3D.gd — 3Dプレイヤー制御
##
## 一人称視点での身長差、プロポーションの体感。
## 身体パーツ（胴体、脚）の動的スケーリングを実装。

signal head_bump(obs_id: String, obs_height_cm: float)

# ─── 定数 ────────────────────────────────────────────────────────
const CM_TO_UNIT: float = 0.01
const BASE_MOVE_SPEED: float = 2.5
const GRAVITY: float = 9.8
const HEAD_BUMP_COOLDOWN := 0.35
const HEAD_BUMP_SHAKE_TIME := 0.18
const HEAD_BUMP_SHAKE_STRENGTH := 0.06

# ─── マウスルック設定 ─────────────────────────────────────────────
const MOUSE_SENSITIVITY: float = 0.002
const PITCH_LIMIT: float = 88.0        # 真下（脚）を見られるように広げる

# ─── 身体パラメータ ──────────────────────────────────────────────
var visual_height_cm: float = 180.0
var visual_height_m: float = 1.80
var eye_height_m: float = 1.62
var speed: float = BASE_MOVE_SPEED
var dir: int = 1

# ─── 屈み ────────────────────────────────────────────────────────
var auto_crouch: bool = true
var target_crouch_cm: float = -1.0
var is_crouch_impossible: bool = false

# ─── 状態 ────────────────────────────────────────────────────────
var pose: String = "normal"
var is_walking: bool = false
var m: Dictionary = {}

# ─── マウスルック ─────────────────────────────────────────────────
var _mouse_captured: bool = false
var _yaw: float = 0.0
var _pitch: float = 0.0

# ─── 歩行アニメーション ──────────────────────────────────────────
var _walk_time: float = 0.0
const WALK_BOB_SPEED: float = 10.0
const WALK_BOB_AMOUNT: float = 0.02

# ─── 内部 ────────────────────────────────────────────────────────
var _head_bump_cooldown_left: float = 0.0
var _head_bump_shake_left: float = 0.0

# ─── カメラモード ─────────────────────────────────────────────────
var _is_third_person: bool = false
@onready var third_person_camera: Camera3D = null  # 動的に取得

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var first_person_camera: Camera3D = $CameraPivot/FirstPersonCamera
@onready var camera_pivot: Node3D = $CameraPivot
@onready var ceiling_ray: RayCast3D = $CeilingRay

# 身体モデルのパーツ
@onready var torso_mesh: MeshInstance3D = $BodyModel/Torso
@onready var leg_l_mesh: MeshInstance3D = $BodyModel/LegL
@onready var leg_r_mesh: MeshInstance3D = $BodyModel/LegR
@onready var body_model_node: Node3D = $BodyModel

# ─── 初期化 ──────────────────────────────────────────────────────
func _ready() -> void:
	update_measurements()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true
	third_person_camera = get_node_or_null("ThirdPersonCamera") as Camera3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _mouse_captured:
		var motion := event as InputEventMouseMotion
		_yaw -= motion.relative.x * MOUSE_SENSITIVITY
		_pitch -= motion.relative.y * MOUSE_SENSITIVITY
		_pitch = clamp(_pitch, deg_to_rad(-PITCH_LIMIT), deg_to_rad(PITCH_LIMIT))

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_ESCAPE:
			if _mouse_captured:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				_mouse_captured = false
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				_mouse_captured = true
		if key_event.keycode == KEY_R:
			_toggle_camera_mode()

	if event is InputEventMouseButton and event.pressed and not _mouse_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_mouse_captured = true

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
	var head_ht_m: float = float(m.get("head", visual_height_cm / 7.5)) * CM_TO_UNIT
	eye_height_m = (visual_height_cm - float(m.get("head", 0)) * 0.45) * CM_TO_UNIT # 頭の半分より少し上が目線

	_update_collision()
	_update_camera_height()
	_update_speed()
	_update_body_model()

func _update_collision() -> void:
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var capsule := collision_shape.shape as CapsuleShape3D
		capsule.height = max(0.4, visual_height_m)
		capsule.radius = min(0.25, visual_height_m * 0.12)
		collision_shape.position.y = visual_height_m * 0.5

func _update_camera_height() -> void:
	if camera_pivot:
		camera_pivot.position.y = eye_height_m

func _update_speed() -> void:
	var base_speed := BASE_MOVE_SPEED
	if has_node("/root/Global"):
		var global = get_node("/root/Global")
		base_speed = float(global.system_settings.get("move_speed", 250.0)) / 100.0
	var leg_cm: float = float(m.get("leg", visual_height_cm * 0.48))
	var base_leg_cm: float = 180.0 * 0.48
	var leg_scale: float = clampf(leg_cm / base_leg_cm, 0.65, 1.8)
	speed = base_speed * leg_scale

# ─── 身体モデルの動的更新 ───────────────────────────────────────
func _update_body_model() -> void:
	if not body_model_node: return

	var leg_h_m: float = float(m.get("leg", visual_height_cm * 0.48)) * CM_TO_UNIT
	var head_h_m: float = float(m.get("head", visual_height_cm / 7.5)) * CM_TO_UNIT
	var neck_h_m: float = float(m.get("neck", head_h_m * 0.22)) * CM_TO_UNIT
	var torso_h_m: float = visual_height_m - leg_h_m - head_h_m - neck_h_m

	# 脚 (Cylinders)
	if leg_l_mesh and leg_r_mesh:
		var leg_mesh := CylinderMesh.new()
		leg_mesh.top_radius = 0.05 * (visual_height_cm / 180.0)
		leg_mesh.bottom_radius = 0.04 * (visual_height_cm / 180.0)
		leg_mesh.height = leg_h_m
		leg_l_mesh.mesh = leg_mesh
		leg_r_mesh.mesh = leg_mesh
		
		# 脚の位置（腰から下に伸びる）
		var leg_spacing: float = 0.08 * (visual_height_cm / 180.0)
		leg_l_mesh.position = Vector3(-leg_spacing, leg_h_m * 0.5, 0)
		leg_r_mesh.position = Vector3(leg_spacing, leg_h_m * 0.5, 0)

	# 胴体 (Capsule)
	if torso_mesh:
		var cm := CapsuleMesh.new()
		cm.radius = 0.12 * (visual_height_cm / 180.0)
		cm.height = torso_h_m + neck_h_m # 首まで含める
		torso_mesh.mesh = cm
		torso_mesh.position.y = leg_h_m + (torso_h_m + neck_h_m) * 0.5

	# マテリアル設定（制服カラー: 濃紺）
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.2)
	torso_mesh.material_override = mat
	leg_l_mesh.material_override = mat
	leg_r_mesh.material_override = mat

# ─── 物理処理 ────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# 視線の回転
	rotation.y = _yaw
	if camera_pivot:
		camera_pivot.rotation.x = _pitch

	# 移動計算
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	if input_dir.x == 0: input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("move_forward", "move_backward")
	if input_dir.y == 0: input_dir.y = Input.get_axis("ui_up", "ui_down")

	if pose != "normal" or is_crouch_impossible:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 10.0)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 10.0)
	elif input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		var forward := -transform.basis.z
		var right := transform.basis.x
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		var move_dir := (right * input_dir.x + forward * (-input_dir.y)).normalized()
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 10.0)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 10.0)

	is_walking = Vector2(velocity.x, velocity.z).length() > 0.01

	# 歩行揺れ
	if is_walking and is_on_floor() and first_person_camera:
		_walk_time += delta * WALK_BOB_SPEED
		var bob_y := sin(_walk_time) * WALK_BOB_AMOUNT
		var bob_x := cos(_walk_time * 0.5) * WALK_BOB_AMOUNT * 0.5
		first_person_camera.position = Vector3(bob_x, bob_y, 0)
	elif first_person_camera:
		first_person_camera.position = first_person_camera.position.lerp(Vector3.ZERO, 10.0 * delta)
		_walk_time = 0.0

	# 身体モデルを移動方向に少しだけ傾ける（慣性演出）
	if body_model_node:
		var target_tilt_z = -input_dir.x * 0.05
		var target_tilt_x = input_dir.y * 0.05
		body_model_node.rotation.x = lerp_angle(body_model_node.rotation.x, target_tilt_x, 5.0 * delta)
		body_model_node.rotation.z = lerp_angle(body_model_node.rotation.z, target_tilt_z, 5.0 * delta)

	_handle_auto_crouch_3d()
	_update_visual_height(delta)
	_update_collision()
	_update_camera_height()
	_update_body_model() # 屈み中もモデル更新
	move_and_slide()
	_process_head_bump(delta)

# ─── オートクラウチ ─────────────────────────────────────────────
func _handle_auto_crouch_3d() -> void:
	if not auto_crouch or pose != "normal":
		target_crouch_cm = -1.0
		is_crouch_impossible = false
		return
	if ceiling_ray:
		ceiling_ray.force_raycast_update()
		if ceiling_ray.is_colliding():
			var hit_point: Vector3 = ceiling_ray.get_collision_point()
			var ceil_h_cm: float = (hit_point.y - global_position.y) / CM_TO_UNIT
			if ceil_h_cm < visual_height_cm + 10.0:
				target_crouch_cm = ceil_h_cm - 8.0
				is_crouch_impossible = target_crouch_cm < visual_height_cm * 0.45
				return
	target_crouch_cm = -1.0
	is_crouch_impossible = false

func _update_visual_height(delta: float) -> void:
	var target_h_cm := visual_height_cm
	var full_h_cm: float = float(m.get("height", 180.0))
	match pose:
		"taiiku_suwari": target_h_cm = full_h_cm * 0.5
		"chair_sit": target_h_cm = full_h_cm * 0.55
		"sleep": target_h_cm = full_h_cm * 0.35
		"normal":
			target_h_cm = full_h_cm
			if target_crouch_cm > 0: target_h_cm = min(target_h_cm, target_crouch_cm)
	visual_height_cm = lerp(visual_height_cm, target_h_cm, 15.0 * delta)
	visual_height_m = visual_height_cm * CM_TO_UNIT
	# モデル全体の高さを屈みに合わせて縮小（簡易的なボーン圧縮に相当）
	if body_model_node:
		body_model_node.scale.y = visual_height_cm / full_h_cm

func _process_head_bump(delta: float) -> void:
	_head_bump_cooldown_left = max(0.0, _head_bump_cooldown_left - delta)
	_head_bump_shake_left = max(0.0, _head_bump_shake_left - delta)
	if _head_bump_cooldown_left > 0.0: return
	if ceiling_ray and ceiling_ray.is_colliding():
		var hit_point: Vector3 = ceiling_ray.get_collision_point()
		if abs(hit_point.y - (global_position.y + visual_height_m)) < 0.1:
			var collider = ceiling_ray.get_collider()
			if collider and collider.has_meta("obs_id"):
				_trigger_head_bump(String(collider.get_meta("obs_id")), float(collider.get_meta("obs_height_cm")))
	if _head_bump_shake_left > 0.0 and first_person_camera:
		var strength := HEAD_BUMP_SHAKE_STRENGTH * (_head_bump_shake_left / HEAD_BUMP_SHAKE_TIME)
		first_person_camera.position.y += randf_range(-strength, strength)

func _trigger_head_bump(obs_id: String, obs_height_cm: float) -> void:
	_head_bump_cooldown_left = HEAD_BUMP_COOLDOWN
	_head_bump_shake_left = HEAD_BUMP_SHAKE_TIME
	velocity.y = max(velocity.y, -0.5)
	emit_signal("head_bump", obs_id, obs_height_cm)
	# FOVパルス（頭ぶつけ演出）
	if first_person_camera and not _is_third_person:
		first_person_camera.fov = 95.0
		var tw := create_tween()
		tw.tween_property(first_person_camera, "fov", 75.0, 0.35)\
		  .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _toggle_camera_mode() -> void:
	_is_third_person = not _is_third_person
	if first_person_camera:
		first_person_camera.current = not _is_third_person
	if third_person_camera:
		third_person_camera.current = _is_third_person

func _mock_measurements(h: float = 180.0) -> Dictionary:
	var ht = h / 7.5
	var n = ht * 0.22
	var leg = h * 0.48
	var arm = h - leg - ht - 2 * n
	return {"height": h, "head": ht, "neck": n, "leg": leg, "arm": arm}
