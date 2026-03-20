extends CharacterBody3D
## NPC3D.gd — 3D NPC制御
##
## Global.core_npcs のデータに基づいてNPCを3D空間に配置。
## プレイヤーとの身長差に応じて頭を回転（見上げ/見下ろし）。

const CM_TO_UNIT: float = 0.01

var npc_id: String = ""
var npc_name: String = ""
var height_cm: float = 155.0
var height_m: float = 1.55
var eye_height_m: float = 1.40
var m: Dictionary = {}

# 視線追従
var _look_angle: float = 0.0

@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var head_mesh: MeshInstance3D = $HeadMesh
@onready var name_label: Label3D = $NameLabel

func setup(id: String, data: Dictionary, age: int = 6) -> void:
	npc_id = id
	npc_name = String(data.get("name", id))

	# 身長の決定
	var height_mode: String = String(data.get("height_mode", "fixed"))
	var height_base: float = float(data.get("height_base", 155.0))
	match height_mode:
		"avg":
			# 年齢平均に近い身長
			height_cm = Global.get_avg_height(age) + randf_range(-3.0, 3.0)
		"fixed":
			height_cm = height_base
		_:
			height_cm = height_base

	height_m = height_cm * CM_TO_UNIT
	eye_height_m = height_m * 0.9
	m = _build_measurements()

	_build_visual()

func _build_measurements() -> Dictionary:
	var ht = height_cm / 7.5
	return {
		"height": height_cm,
		"head": ht,
		"landmarks": {
			"top": height_cm,
			"eye": height_cm - ht * 0.5,
			"shoulder": height_cm - ht - ht * 0.22 * 2,
		}
	}

func _build_visual() -> void:
	# 体: カプセル
	if body_mesh:
		var capsule := CapsuleMesh.new()
		var body_height: float = height_m * 0.75  # 首から下
		capsule.height = body_height
		capsule.radius = height_m * 0.12
		body_mesh.mesh = capsule
		body_mesh.position.y = body_height * 0.5

		var mat := StandardMaterial3D.new()
		# NPCごとのカラー
		mat.albedo_color = _get_npc_color()
		body_mesh.material_override = mat

	# 頭: 球
	if head_mesh:
		var sphere := SphereMesh.new()
		var head_size: float = height_m * 0.13
		sphere.radius = head_size
		sphere.height = head_size * 2.0
		head_mesh.mesh = sphere
		head_mesh.position.y = height_m * 0.75 + head_size

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.92, 0.82, 0.72)  # 肌色
		head_mesh.material_override = mat

	# 名前ラベル
	if name_label:
		name_label.text = npc_name
		name_label.position.y = height_m + 0.15
		name_label.font_size = 48
		name_label.outline_size = 8
		name_label.modulate = Color(1, 1, 1, 0.9)

	# コリジョン
	var col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col and col.shape is CapsuleShape3D:
		var cap := col.shape as CapsuleShape3D
		cap.height = height_m
		cap.radius = min(0.2, height_m * 0.12)
		col.position.y = height_m * 0.5

func _process(delta: float) -> void:
	_update_look_at_player(delta)

func _update_look_at_player(delta: float) -> void:
	var player := _find_player()
	if player == null:
		_look_angle = lerp(_look_angle, 0.0, 5.0 * delta)
		return

	var player_eye_y: float = player.global_position.y + player.eye_height_m
	var my_eye_y: float = global_position.y + eye_height_m

	var diff_y: float = player_eye_y - my_eye_y
	var dist_xz: float = Vector2(
		global_position.x - player.global_position.x,
		global_position.z - player.global_position.z
	).length()

	if dist_xz > 5.0:
		_look_angle = lerp(_look_angle, 0.0, 3.0 * delta)
		return

	var target_angle: float = atan2(diff_y, max(dist_xz, 0.3))
	_look_angle = lerp(_look_angle, target_angle, 6.0 * delta)

	# 頭を回転（見上げ/見下ろし）
	if head_mesh:
		head_mesh.rotation.x = clamp(_look_angle, -PI / 3.0, PI / 3.0)

	# プレイヤーの方を振り向く（Y軸回転）
	var dir_to_player := Vector3(
		player.global_position.x - global_position.x,
		0,
		player.global_position.z - global_position.z
	)
	if dir_to_player.length() > 0.1:
		var target_yaw := atan2(dir_to_player.x, dir_to_player.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 4.0 * delta)

func _find_player() -> Node:
	var parent := get_parent()
	if parent == null:
		return null
	for child in parent.get_children():
		if child != self and child.has_method("update_measurements"):
			return child
	return null

func _get_npc_color() -> Color:
	match npc_id:
		"haruka":
			return Color(0.85, 0.75, 0.90)   # 薄紫
		"senior":
			return Color(0.30, 0.55, 0.35)   # 深緑ジャージ
		"mother":
			return Color(0.72, 0.60, 0.48)   # ベージュ
		"father":
			return Color(0.35, 0.35, 0.40)   # ダークグレー
		"nurse":
			return Color(0.90, 0.90, 0.92)   # 白衣
		_:
			return Color(0.65, 0.65, 0.70)   # 汎用グレー
