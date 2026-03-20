extends RefCounted
class_name StageBuilder3D
## StageBuilder3D.gd — 3Dステージ構築
##
## 既存の StageBuilder.STAGES データを読み取り、
## 3Dメッシュ + コリジョンでステージを構築する。

const CM_TO_UNIT: float = 0.01  # 1cm → 0.01 Godot ユニット

# 障害物のタイプ別カラー
const OBS_COLORS: Dictionary = {
	"overhead": Color(0.65, 0.55, 0.45),   # ドア枠・天井灯 → 木目調
	"ground":   Color(0.55, 0.45, 0.35),   # 机・椅子 → 濃い木目
	"background": Color(0.75, 0.72, 0.68), # 背景装飾 → 淡い壁色
}

# ステージ別のマテリアルカラー
const FLOOR_COLORS: Dictionary = {
	"room":       Color(0.45, 0.35, 0.25),   # フローリング
	"myroom":     Color(0.48, 0.38, 0.28),   # フローリング（暖色）
	"train":      Color(0.32, 0.32, 0.35),   # 電車の床
	"outdoor":    Color(0.55, 0.53, 0.50),   # アスファルト
	"park":       Color(0.45, 0.60, 0.35),   # 草地
	"station":    Color(0.58, 0.57, 0.55),   # コンクリート
	"school":     Color(0.45, 0.35, 0.25),   # フローリング（教室）
}

const WALL_COLORS: Dictionary = {
	"room":       Color(0.40, 0.45, 0.50),   # グレー系（リビング）
	"myroom":     Color(0.90, 0.85, 0.78),   # クリーム（子供部屋）
	"train":      Color(0.90, 0.88, 0.84),   # アイボリー（車内）
	"station":    Color(0.72, 0.74, 0.78),   # 駅構内
	"school":     Color(0.82, 0.80, 0.72),   # 学校壁面
}

const CEILING_COLORS: Dictionary = {
	"room":       Color(0.92, 0.90, 0.86),
	"myroom":     Color(0.95, 0.93, 0.90),
	"train":      Color(0.85, 0.83, 0.80),
	"station":    Color(0.80, 0.80, 0.82),
	"school":     Color(0.90, 0.88, 0.85),
}

const DEFAULT_DEPTH_CM: float = 400.0  # 部屋の奥行き（cm）

# ─── メイン構築関数 ──────────────────────────────────────────────
static func build_stage(stage_id: String, parent: Node3D, age: int = 0) -> void:
	stage_id = StageBuilder.resolve_stage_id(stage_id, age)
	if not StageBuilder.STAGES.has(stage_id):
		push_error("StageBuilder3D: Stage not found: " + stage_id)
		return

	var stage_data: Dictionary = StageBuilder.STAGES[stage_id]

	# 既存のステージオブジェクトを削除
	for child in parent.get_children():
		if child.has_meta("is_stage_obj"):
			child.queue_free()

	var width_cm: float = float(stage_data["width"])
	var ceiling_cm = stage_data.get("ceiling_height", null)
	var depth_cm: float = DEFAULT_DEPTH_CM

	# 床を生成
	_create_floor(parent, width_cm, depth_cm, _get_floor_color(stage_id))

	# 壁を生成（天井のあるステージ）
	if ceiling_cm != null:
		var ceiling_h: float = float(ceiling_cm)
		_create_walls(parent, width_cm, depth_cm, ceiling_h, _get_wall_color(stage_id))
		_create_ceiling(parent, width_cm, depth_cm, ceiling_h, _get_ceiling_color(stage_id))

	# 障害物を生成
	for obs in stage_data.get("obstacles", []):
		_create_obstacle(parent, obs, depth_cm)

	# 左右の見えない壁
	_create_boundary_walls(parent, width_cm, depth_cm)

	# 屋外/公園: 追加デコレーション
	if stage_id == "outdoor" or stage_id == "park":
		_create_outdoor_background(parent, width_cm, depth_cm, stage_id)

# ─── 床 ──────────────────────────────────────────────────────────
static func _create_floor(parent: Node3D, width_cm: float, depth_cm: float, color: Color) -> void:
	var body := StaticBody3D.new()
	body.set_meta("is_stage_obj", true)
	body.name = "Floor"

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width_cm * CM_TO_UNIT, 0.1, depth_cm * CM_TO_UNIT)
	shape.shape = box
	shape.position = Vector3(width_cm * CM_TO_UNIT * 0.5, -0.05, 0)
	body.add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box.size
	mesh_inst.mesh = box_mesh
	mesh_inst.position = shape.position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	parent.add_child(body)

# ─── 壁 ──────────────────────────────────────────────────────────
static func _create_walls(parent: Node3D, width_cm: float, depth_cm: float, ceiling_cm: float, color: Color) -> void:
	var w := width_cm * CM_TO_UNIT
	var h := ceiling_cm * CM_TO_UNIT
	var d := depth_cm * CM_TO_UNIT

	# 背面の壁（Z = -depth/2）
	_create_wall_panel(parent, "BackWall",
		Vector3(w * 0.5, h * 0.5, -d * 0.5),
		Vector3(w, h, 0.05), color)

	# （左右の壁は境界壁で対応）

# ─── 天井 ────────────────────────────────────────────────────────
static func _create_ceiling(parent: Node3D, width_cm: float, depth_cm: float, ceiling_cm: float, color: Color) -> void:
	var body := StaticBody3D.new()
	body.set_meta("is_stage_obj", true)
	body.set_meta("obs_type", "ceiling")
	body.set_meta("obs_height_cm", ceiling_cm)
	body.name = "Ceiling"

	var w := width_cm * CM_TO_UNIT
	var h := ceiling_cm * CM_TO_UNIT
	var d := depth_cm * CM_TO_UNIT

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w, 0.1, d)
	shape.shape = box
	shape.position = Vector3(w * 0.5, h + 0.05, 0)
	body.add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box.size
	mesh_inst.mesh = box_mesh
	mesh_inst.position = shape.position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	parent.add_child(body)

# ─── 壁パネルユーティリティ ────────────────────────────────────
static func _create_wall_panel(parent: Node3D, panel_name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.set_meta("is_stage_obj", true)
	body.name = panel_name

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	body.add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	parent.add_child(body)

# ─── 障害物 ─────────────────────────────────────────────────────
static func _create_obstacle(parent: Node3D, obs: Dictionary, depth_cm: float) -> void:
	var x_start: float = float(obs["x"]) * CM_TO_UNIT
	var x_end: float = float(obs["x2"]) * CM_TO_UNIT
	var height_m: float = float(obs["height"]) * CM_TO_UNIT
	var width_m: float = x_end - x_start
	var depth_m: float = 0.3  # 障害物の奥行き（固定）
	var obs_type: String = String(obs.get("type", "ground"))
	var obs_id: String = String(obs.get("id", ""))

	var body := StaticBody3D.new()
	body.set_meta("is_stage_obj", true)
	body.set_meta("obs_id", obs_id)
	body.set_meta("obs_type", obs_type)
	body.set_meta("obs_height_cm", float(obs["height"]))
	body.name = "Obs_" + obs_id

	var center_x: float = (x_start + x_end) * 0.5

	match obs_type:
		"overhead":
			# 上方の障害物（ドア枠など）
			# 底面が height_m の位置にあるボックス
			var box_height: float = 0.15  # 梁の厚さ
			var pos := Vector3(center_x, height_m + box_height * 0.5, 0)
			var size := Vector3(width_m, box_height, depth_m)
			_add_collision_and_mesh(body, pos, size, _get_obs_color(obs_type, obs_id))

			# コリジョンレイヤーを設定（overhead用）
			body.collision_layer = 2

		"ground":
			# 地面に置かれた障害物
			var pos := Vector3(center_x, height_m * 0.5, 0)
			var size := Vector3(width_m, height_m, depth_m)
			_add_collision_and_mesh(body, pos, size, _get_obs_color(obs_type, obs_id))

		"background":
			# 背景装飾（コリジョンなし → 視覚のみ）
			var pos := Vector3(center_x, height_m * 0.5, -depth_cm * CM_TO_UNIT * 0.45)
			var size := Vector3(width_m, height_m, 0.05)

			var mesh_inst := MeshInstance3D.new()
			var box_mesh := BoxMesh.new()
			box_mesh.size = size
			mesh_inst.mesh = box_mesh
			mesh_inst.position = pos
			var mat := StandardMaterial3D.new()
			mat.albedo_color = _get_obs_color(obs_type, obs_id)
			mesh_inst.material_override = mat
			body.add_child(mesh_inst)

	parent.add_child(body)

static func _add_collision_and_mesh(body: StaticBody3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	body.add_child(shape)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

# ─── 境界壁 ─────────────────────────────────────────────────────
static func _create_boundary_walls(parent: Node3D, width_cm: float, depth_cm: float) -> void:
	var w := width_cm * CM_TO_UNIT
	var d := depth_cm * CM_TO_UNIT
	var wall_height := 5.0  # 5m の見えない壁

	# 左壁
	var left_wall := StaticBody3D.new()
	left_wall.set_meta("is_stage_obj", true)
	left_wall.name = "LeftBoundary"
	var left_shape := CollisionShape3D.new()
	var left_box := BoxShape3D.new()
	left_box.size = Vector3(0.2, wall_height, d)
	left_shape.shape = left_box
	left_shape.position = Vector3(-0.1, wall_height * 0.5, 0)
	left_wall.add_child(left_shape)
	parent.add_child(left_wall)

	# 右壁
	var right_wall := StaticBody3D.new()
	right_wall.set_meta("is_stage_obj", true)
	right_wall.name = "RightBoundary"
	var right_shape := CollisionShape3D.new()
	var right_box := BoxShape3D.new()
	right_box.size = Vector3(0.2, wall_height, d)
	right_shape.shape = right_box
	right_shape.position = Vector3(w + 0.1, wall_height * 0.5, 0)
	right_wall.add_child(right_shape)
	parent.add_child(right_wall)

# ─── 屋外背景デコレーション ─────────────────────────────────────
static func _create_outdoor_background(parent: Node3D, width_cm: float, depth_cm: float, stage_id: String) -> void:
	var w := width_cm * CM_TO_UNIT
	var d := depth_cm * CM_TO_UNIT

	# 空（後方の青い大きな板）
	var sky_body := StaticBody3D.new()
	sky_body.set_meta("is_stage_obj", true)
	sky_body.name = "SkyBackground"
	var sky_mesh := MeshInstance3D.new()
	var sky_box := BoxMesh.new()
	sky_box.size = Vector3(w + 20.0, 15.0, 0.1)
	sky_mesh.mesh = sky_box
	sky_mesh.position = Vector3(w * 0.5, 7.0, -d * 0.6)
	var sky_mat := StandardMaterial3D.new()
	sky_mat.albedo_color = Color(0.55, 0.78, 0.98)
	sky_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky_mesh.material_override = sky_mat
	sky_body.add_child(sky_mesh)
	parent.add_child(sky_body)

	# 地平線の建物シルエット
	if stage_id == "outdoor":
		var building_colors: Array[Color] = [
			Color(0.62, 0.65, 0.72), Color(0.58, 0.60, 0.68),
			Color(0.55, 0.58, 0.65), Color(0.60, 0.63, 0.70),
		]
		var building_data: Array = [
			[0.1, 3.0, 5.0], [0.25, 5.5, 7.0], [0.50, 2.5, 4.5],
			[0.70, 4.0, 6.5], [0.85, 3.2, 5.2],
		]
		for i in range(building_data.size()):
			var bd: Array = building_data[i]
			var bx: float = bd[0] * w
			var bh: float = bd[1]
			var btop: float = bd[2]
			var bw: float = w * 0.15
			var b_mesh := MeshInstance3D.new()
			b_mesh.set_meta("is_stage_obj", true)
			var b_box := BoxMesh.new()
			b_box.size = Vector3(bw, bh, 0.1)
			b_mesh.mesh = b_box
			b_mesh.position = Vector3(bx, bh * 0.5, -d * 0.58)
			var b_mat := StandardMaterial3D.new()
			b_mat.albedo_color = building_colors[i % building_colors.size()]
			b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			b_mesh.material_override = b_mat
			parent.add_child(b_mesh)

	# 公園: 木のシルエット（円柱の幹 + 球の葉）
	if stage_id == "park":
		var tree_positions: Array[float] = [0.08, 0.22, 0.38, 0.62, 0.78, 0.92]
		for tx in tree_positions:
			var tree_x: float = tx * w
			# 幹
			var trunk_body := Node3D.new()
			trunk_body.set_meta("is_stage_obj", true)
			var trunk_mesh := MeshInstance3D.new()
			var trunk_cyl := CylinderMesh.new()
			trunk_cyl.top_radius = 0.12
			trunk_cyl.bottom_radius = 0.15
			trunk_cyl.height = 2.5
			trunk_mesh.mesh = trunk_cyl
			trunk_mesh.position = Vector3(tree_x, 1.25, -d * 0.45)
			var trunk_mat := StandardMaterial3D.new()
			trunk_mat.albedo_color = Color(0.40, 0.28, 0.18)
			trunk_mesh.material_override = trunk_mat
			trunk_body.add_child(trunk_mesh)
			parent.add_child(trunk_body)
			# 葉
			var leaf_body := Node3D.new()
			leaf_body.set_meta("is_stage_obj", true)
			var leaf_mesh := MeshInstance3D.new()
			var leaf_sphere := SphereMesh.new()
			leaf_sphere.radius = 1.2
			leaf_sphere.height = 2.4
			leaf_mesh.mesh = leaf_sphere
			leaf_mesh.position = Vector3(tree_x, 3.7, -d * 0.45)
			var leaf_mat := StandardMaterial3D.new()
			leaf_mat.albedo_color = Color(0.28, 0.60, 0.22)
			leaf_mesh.material_override = leaf_mat
			leaf_body.add_child(leaf_mesh)
			parent.add_child(leaf_body)

# ─── カラーヘルパー ─────────────────────────────────────────────
static func _get_floor_color(stage_id: String) -> Color:
	for key in FLOOR_COLORS:
		if stage_id.begins_with(key):
			return FLOOR_COLORS[key]
	return Color(0.5, 0.5, 0.5)

static func _get_wall_color(stage_id: String) -> Color:
	for key in WALL_COLORS:
		if stage_id.begins_with(key):
			return WALL_COLORS[key]
	return Color(0.8, 0.8, 0.8)

static func _get_ceiling_color(stage_id: String) -> Color:
	for key in CEILING_COLORS:
		if stage_id.begins_with(key):
			return CEILING_COLORS[key]
	return Color(0.9, 0.9, 0.9)

static func _get_obs_color(obs_type: String, obs_id: String) -> Color:
	# 特定の障害物用のカスタムカラー
	if obs_id.begins_with("door_"):
		return Color(0.55, 0.40, 0.28)  # ドア → 木目
	if obs_id.contains("window"):
		return Color(0.55, 0.75, 0.95, 0.7)  # 窓 → 青空色
	if obs_id.contains("bed"):
		return Color(0.85, 0.82, 0.78)  # ベッド → 白系
	if obs_id.contains("desk") or obs_id.contains("table"):
		return Color(0.55, 0.42, 0.30)  # 机 → 木目
	if obs_id.contains("chair"):
		return Color(0.50, 0.38, 0.28)  # 椅子 → 木目
	if obs_id.contains("strap"):
		return Color(0.35, 0.35, 0.40)  # つり革 → 金属色
	if obs_id.contains("light"):
		return Color(1.0, 0.98, 0.90)  # 照明 → 白
	if obs_id.contains("bench"):
		return Color(0.55, 0.42, 0.28)  # ベンチ → 木目
	if obs_id.contains("fountain"):
		return Color(0.55, 0.70, 0.90)  # 噴水 → 水色
	if obs_id.contains("tree"):
		return Color(0.28, 0.55, 0.22)  # 木 → 緑
	if obs_id.contains("lamp"):
		return Color(0.80, 0.80, 0.85)  # 街灯 → 銀色

	return OBS_COLORS.get(obs_type, Color(0.6, 0.6, 0.6))
