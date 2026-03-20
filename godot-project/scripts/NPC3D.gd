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

# 腕・脚ピボット
var _arm_l_pivot: Node3D = null
var _arm_r_pivot: Node3D = null
var _leg_l_pivot: Node3D = null
var _leg_r_pivot: Node3D = null
var _walk_time: float = 0.0
var _limbs_built: bool = false

# 身長差反応
var _speech_label: Label3D = null
var _speech_timer: float = 0.0
var _reaction_cooldown: float = 0.0
var _last_height_category: String = ""
var _patrol_origin_x: float = 0.0
var _patrol_dir: int = 1
const PATROL_RANGE: float = 1.5  # 巡回半径（m）
const PATROL_SPEED_BASE: float = 0.5  # 巡回速度（m/s）

const REACTION_LINES: Dictionary = {
	"shorter": ["あ、どうも...", "こんにちは"],
	"same": ["背が揃ってますね", "同じくらいですね"],
	"slightly_tall": ["背が高いんですね...", "あ、見上げちゃう", "すらっとしてますね"],
	"tall": ["え、いつから...？", "す、すごく高いですね！", "えっ、何cmですか？"],
	"very_tall": ["す、凄い...！", "うわぁ、見上げちゃう...", "そんなに高いんですか！？"],
	"extreme": ["う、動かないで... 圧迫感が...", "わ、わた... 頭が...！", "ひ、ひぃ... でかすぎる..."],
}

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
	_patrol_origin_x = 0.0  # 配置後に MainScene から呼ばれる set_patrol_origin() で上書き

func set_patrol_origin() -> void:
	_patrol_origin_x = position.x

func _build_measurements() -> Dictionary:
	# 身長連動で頭身を計算（プレイヤーと同じ式）
	var ratio: float = clamp(5.5 + (height_cm - 100.0) / 30.0, 5.0, 9.0)
	var ht: float = height_cm / ratio
	return {
		"height": height_cm,
		"head": ht,
		"ratio": ratio,
		"landmarks": {
			"top": height_cm,
			"eye": height_cm - ht * 0.5,
			"shoulder": height_cm - ht - ht * 0.22 * 2,
		}
	}

func _build_visual() -> void:
	# 体: カプセル（胴体専用 — 腕・脚は別途 _build_limbs で生成）
	if body_mesh:
		var capsule := CapsuleMesh.new()
		var body_height: float = height_m * 0.40  # 胴体のみ
		capsule.height = body_height
		capsule.radius = height_m * 0.12
		body_mesh.mesh = capsule
		body_mesh.position.y = height_m * 0.48 + height_m * 0.40 * 0.5  # 腰の上

		var mat := StandardMaterial3D.new()
		# NPCごとのカラー
		mat.albedo_color = _get_npc_color()
		body_mesh.material_override = mat

	# 頭: 球（m["head"] ベースのサイズ）
	if head_mesh:
		var sphere := SphereMesh.new()
		var head_cm: float = m["head"]
		var head_size: float = head_cm * CM_TO_UNIT
		sphere.radius = head_size
		sphere.height = head_size * 2.0
		head_mesh.mesh = sphere
		# 頭頂基準（確実な位置）
		head_mesh.position.y = height_m - head_size

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.92, 0.82, 0.72)  # 肌色
		head_mesh.material_override = mat

	# 名前ラベル（身長表示付き）
	if name_label:
		name_label.text = "%s\n%d cm" % [npc_name, int(height_cm)]
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

	# 腕・脚
	_build_limbs()

	# セリフラベル（身長差反応表示）
	_speech_label = Label3D.new()
	_speech_label.position.y = height_m + 0.42
	_speech_label.font_size = 52
	_speech_label.outline_size = 6
	_speech_label.modulate = Color(1, 1, 0.85, 0.0)
	_speech_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_speech_label.no_depth_test = true
	add_child(_speech_label)

func _process(delta: float) -> void:
	_update_look_at_player(delta)
	_update_walk_animation(delta)
	_update_patrol(delta)
	_check_reactions(delta)
	_update_speech_label(delta)

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

func _build_limbs() -> void:
	if _limbs_built:
		return
	_limbs_built = true

	var leg_h: float = height_m * 0.48
	var body_h: float = height_m * 0.40
	var arm_h: float = body_h * 0.85
	var leg_spacing: float = height_m * 0.09
	var arm_spacing: float = height_m * 0.18
	var shoulder_y: float = leg_h + body_h
	var hip_y: float = leg_h

	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.92, 0.82, 0.72)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = _get_npc_color()

	# 腕（左: side=-1, 右: side=1）
	for side in [-1, 1]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * arm_spacing, shoulder_y, 0.0)
		add_child(pivot)
		var arm_mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = height_m * 0.035
		cyl.bottom_radius = height_m * 0.030
		cyl.height = arm_h
		arm_mesh.mesh = cyl
		arm_mesh.position.y = -arm_h * 0.5
		arm_mesh.material_override = body_mat
		pivot.add_child(arm_mesh)
		if side == -1:
			_arm_l_pivot = pivot
		else:
			_arm_r_pivot = pivot

	# 脚（左: side=-1, 右: side=1）
	for side in [-1, 1]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * leg_spacing, hip_y, 0.0)
		add_child(pivot)
		var leg_mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = height_m * 0.055
		cyl.bottom_radius = height_m * 0.045
		cyl.height = leg_h
		leg_mesh.mesh = cyl
		leg_mesh.position.y = -leg_h * 0.5
		leg_mesh.material_override = body_mat
		pivot.add_child(leg_mesh)
		if side == -1:
			_leg_l_pivot = pivot
		else:
			_leg_r_pivot = pivot

	# スカート（対象: haruka, mother, nurse）
	if _has_skirt():
		var skirt_mesh := MeshInstance3D.new()
		var skirt_cyl := CylinderMesh.new()
		var skirt_height: float = height_m * 0.18
		skirt_cyl.top_radius = height_m * 0.14      # 腰幅
		skirt_cyl.bottom_radius = height_m * 0.20   # 裾の広がり
		skirt_cyl.height = skirt_height
		skirt_mesh.mesh = skirt_cyl
		skirt_mesh.position.y = hip_y - skirt_height * 0.5
		var skirt_mat := StandardMaterial3D.new()
		skirt_mat.albedo_color = _get_skirt_color()
		skirt_mesh.material_override = skirt_mat
		add_child(skirt_mesh)

func _update_walk_animation(delta: float) -> void:
	_walk_time += delta * 2.0
	var swing: float = sin(_walk_time) * 0.25
	if _arm_l_pivot:
		_arm_l_pivot.rotation.x = swing
	if _arm_r_pivot:
		_arm_r_pivot.rotation.x = -swing
	if _leg_l_pivot:
		_leg_l_pivot.rotation.x = -swing * 0.6
	if _leg_r_pivot:
		_leg_r_pivot.rotation.x = swing * 0.6

func _update_patrol(delta: float) -> void:
	var player := _find_player()
	if player != null and player.global_position.distance_to(global_position) < 3.0:
		return

	var patrol_speed := PATROL_SPEED_BASE * (height_m / 1.7)
	var target_x: float = _patrol_origin_x + _patrol_dir * PATROL_RANGE

	if _patrol_dir > 0 and position.x >= target_x:
		_patrol_dir = -1
	elif _patrol_dir < 0 and position.x <= target_x:
		_patrol_dir = 1

	position.x += _patrol_dir * patrol_speed * delta

func _get_height_category(diff: float) -> String:
	if diff < -15.0: return "shorter"
	elif diff < 5.0: return "same"
	elif diff < 20.0: return "slightly_tall"
	elif diff < 40.0: return "tall"
	elif diff < 70.0: return "very_tall"
	else: return "extreme"

func _check_reactions(delta: float) -> void:
	if _reaction_cooldown > 0:
		_reaction_cooldown -= delta
		return

	var player := _find_player()
	if player == null:
		return

	var dist: float = player.global_position.distance_to(global_position)
	if dist > 3.5:
		_last_height_category = ""
		return

	var player_h: float = player.visual_height_cm if player.has_method("update_measurements") else 170.0
	var diff := player_h - height_cm
	var category := _get_height_category(diff)

	if category == _last_height_category:
		return

	_last_height_category = category
	_reaction_cooldown = 8.0

	var lines: Array = REACTION_LINES.get(category, [])
	if lines.is_empty():
		return
	_show_speech(lines[randi() % lines.size()])

func _show_speech(text: String) -> void:
	if not _speech_label:
		return
	_speech_label.text = text
	_speech_timer = 3.0

func _update_speech_label(delta: float) -> void:
	if not _speech_label:
		return
	if _speech_timer > 0:
		_speech_timer -= delta
		var alpha: float = 1.0
		if _speech_timer < 0.5:
			alpha = _speech_timer / 0.5
		elif _speech_timer > 2.5:
			alpha = (3.0 - _speech_timer) / 0.5
		_speech_label.modulate = Color(1, 1, 0.85, alpha)
	else:
		_speech_label.modulate.a = 0.0

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

func _has_skirt() -> bool:
	return npc_id in ["haruka", "mother", "nurse"]

func _get_skirt_color() -> Color:
	match npc_id:
		"haruka":
			return Color(0.2, 0.2, 0.3)    # 制服紺
		"mother":
			return Color(0.44, 0.33, 0.22)
		"nurse":
			return Color(0.90, 0.90, 0.92)
		_:
			return Color(0.4, 0.4, 0.45)
