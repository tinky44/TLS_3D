extends Node2D

# =============================================================
# CharacterDrawer.gd
#
# キャラクターの描画オーケストラ。
# DrawContext を構築し、facing に応じて CharacterDrawFront / CharacterDrawSide に委譲する。
#
# 【描画レイヤー順（正面・背面）】→ CharacterDrawFront 参照
# 【描画レイヤー順（側面）】→ CharacterDrawSide 参照
# =============================================================

@onready var player = get_parent()

@export var part_shapes = {
	"head": "ellipse",
	"torso_lower": "trapezoid",
	"torso_upper": "trapezoid",
	"torso_front_lower": "pentagon",
	"torso_front_upper": "rect",
	"limb": "stick",
	"neck": "limb",
}

func _draw() -> void:
	var p = player.CM_TO_PX
	var m = player.m
	var dir = player.dir
	var facing = player.facing

	if m == null or m.is_empty():
		return

	var d = CharacterPoseCalculator.calculate_pose_data(player, m, p)
	var flip = (dir == -1 and facing == "side")

	var appearance = player.get("appearance")
	if appearance == null or appearance.is_empty():
		appearance = Global.current_appearance

	var ctx = DrawContext.new()
	ctx.canvas = self
	ctx.m = m
	ctx.p = p
	ctx.d = d
	ctx.appearance = appearance
	ctx.part_shapes = part_shapes
	ctx.facing = facing
	ctx.flip = flip

	# 色の設定
	ctx.skin_color = Color("#ffe4c4")
	ctx.base_shirt_color = Color(appearance.get("tops_color", "#ab82a8"))
	ctx.pants_color = Color(appearance.get("bottoms_color", "#e5d6ba"))
	# サスペンダースカートは下に白いブラウスを着るのでベースシャツ色を白に上書き
	if appearance.get("tops_type", "t_shirt") == "jumper_skirt":
		ctx.base_shirt_color = Color(0.97, 0.97, 0.97)
	ctx.skin_dark = ctx.skin_color.darkened(0.15)
	ctx.pants_dark = ctx.pants_color.darkened(0.15)
	ctx.shirt_dark = ctx.base_shirt_color.darkened(0.15)

	# サイズの設定
	var width_scale = 0.35 if facing == "side" else 1.0
	ctx.shoulder_w = (m["shoulder"] if m.has("shoulder") else 35.0) * p * width_scale
	ctx.hip_w = ctx.shoulder_w * 0.70 # 側面台形: 上が広く下がやや狭い
	ctx.thigh_w = 9.0 * p
	ctx.shin_w = 6.5 * p
	ctx.arm_w = 5.5 * p
	ctx.neck_w = 4.5 * p

	# 服装タイプのキャッシュ
	ctx.tops_type = appearance.get("tops_type", "t_shirt")
	ctx.bottoms_type = appearance.get("bottoms_type", "pants")
	ctx.is_skirt = ctx.bottoms_type.begins_with("skirt")
	ctx.hair_style = appearance.get("hair_style", "short")
	ctx.hair_color = Color(appearance.get("hair_color", "#4a3c31"))
	ctx.shoe_color = Color(appearance.get("shoes_color", "#f0f0f0"))
	ctx.head_r = d["head_h"] / 2.0

	# プレイヤー依存の値をキャッシュ（サブクラスが player を参照しないで済むように）
	var look_pitch = player.get("look_pitch")
	ctx.look_pitch = look_pitch if look_pitch != null else 0.0
	var look_head_angle = player.get("look_head_angle")
	ctx.look_head_angle = look_head_angle if look_head_angle != null else 0.0

	if flip:
		draw_set_transform(Vector2.ZERO, 0, Vector2(-1, 1))

	if facing == "front" or facing == "back":
		CharacterDrawFront.draw(ctx)
	else:
		CharacterDrawSide.draw(ctx)

	if flip:
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
