extends CharacterBody2D

var SPEED: float = 55.0
const GRAVITY = 1200.0
const REACTION_DIST := 170.0
const HUGE_DIFF_CM := 35.0
const VERY_HUGE_DIFF_CM := 60.0
const GENERIC_PASSIVE_TRIGGER_SEC := 1.8
const GENERIC_PASSIVE_TALL_CM := 170.0
const GENERIC_PASSIVE_HUGE_CM := 180.0
const GENERIC_PASSIVE_VERY_HUGE_CM := 190.0
const GENERIC_PASSIVE_DURATION := 2.4
const GENERIC_PASSIVE_COOLDOWN := 6.0
const NAMED_GREET_TRIGGER_SEC := 2.0
const NAMED_GREET_DURATION := 2.6
const NAMED_GREET_COOLDOWN := 5.0
const GENERIC_PASSIVE_LINES := {
	"default": {
		"tall": [
			"背が高いね。",
			"モデルさんみたい。",
			"え、何年生？"
		],
		"huge": [
			"ちょっと、写真みたいに目立つね。",
			"上の棚、お願いしてもいい？",
			"すごく目を引くなあ。"
		],
		"very_huge": [
			"うわっ……何センチあるの！？",
			"遠くからでもすぐ分かった。",
			"そんなに大きい人、初めて見た。"
		]
	},
	"school": {
		"tall": [
			"背が高いね！",
			"バスケ部とか向いてそう。",
			"教室でもすぐ見つかるね。",
			"一番後ろの席、ぴったりだね。",
			"掲示物、上まで見えていいな。"
		],
		"huge": [
			"掲示物、上の方まで見やすそう。",
			"体育館でもすぐ分かりそうだね。",
			"モデルみたいで目立ってたよ。"
		],
		"very_huge": [
			"すごい……何年生？",
			"そこまで大きいと皆ふり返るね。",
			"写真に撮りたくなるくらい目立つ。"
		]
	},
	"station": {
		"tall": [
			"人混みでもすぐ見つかりそう。",
			"待ち合わせ、すごく楽そう。",
			"背、高くて目立つね。"
		],
		"huge": [
			"路線案内、上まで見やすそう。",
			"広告より先に目が行っちゃった。",
			"モデルさんみたいだね。",
			"人波から頭ひとつ抜けてる！",
			"電車、立っても大丈夫？"
		],
		"very_huge": [
			"人波から頭ひとつ抜けてる……！",
			"うわっ、何センチあるの！？",
			"駅でいちばん目立ってるかも。"
		]
	},
	"outdoor": {
		"tall": [
			"信号の向こうからでも分かった。",
			"背が高くてかっこいいね。",
			"高いところ、全部届きそう。"
		],
		"huge": [
			"上の棚、頼んでもよさそう。",
			"遠くからでもすぐ見つかったよ。",
			"モデルさんみたいでびっくりした。"
		],
		"very_huge": [
			"すごい！ 本当に大きい……！",
			"街でいちばん目立ってるかも。",
			"そんな身長、ちょっと憧れる。"
		]
	},
	"room": {
		"tall": [
			"今日もすらっとしてるね。",
			"部屋の中でも背の高さが映えるなあ。"
		],
		"huge": [
			"この部屋だと、なおさら大きく見えるね。",
			"家具とのサイズ差がすごい……。"
		],
		"very_huge": [
			"天井が近く見えそうなくらい大きい……！",
			"家の中でも存在感がすごいね。"
		]
	}
}
const GENERIC_CHILD_PASSIVE_LINES := {
	"tall": [
		"背、高いね！"
	],
	"huge": [
		"わっ、高い！",
		"ほんとに大きい……！"
	],
	"very_huge": [
		"すごい！ %dcm！？",
		"こんなに大きい人、はじめて見た！"
	]
}
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
var _last_generic_callout_text: String = ""
var _player_is_close: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var character_drawer: Node2D = $CharacterDrawer

@export var custom_params: Dictionary = {
	"height": 158.0,
	"ratio": 7.0,
	"legRatio": 45.0,
	"sex": "female"
}

# 【design task 全体】NPC の外見定義
# このDictionary に以下のキーを追加・変更することで NPC の見た目が決まります：
#
# 【Task 1】髪型追加: "hair_style" に新しい値を設定
#   現在: "short", "long", "ponytail", "side_tail"
#   例: "hair_style": "wavy"
#
# 【Task 2】帽子追加: "hat_type" / "hat_color" を追加
#   例: "hat_type": "cap", "hat_color": "#ff0000"
#
# 【Task 4】上履きのカスタマイズ: "shoes_toe_color" を追加
#   例: "shoes_toe_color": "#ff6600"
#
# 【Task 5】服装変更: "tops_type" / "bottoms_type" を変更
#   上: "t_shirt", "sweater", "sailor", "blazer", "jumper_skirt" など
#   下: "pants", "skirt_long", "sweatpants" など
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
	var player_m_value: Variant = p_node.get("m")
	if m == null or m.is_empty() or not (player_m_value is Dictionary):
		return
	var player_m: Dictionary = player_m_value
	if player_m.is_empty():
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

	_update_look_towards_player(delta, p_node, player_m, abs_dist, dist_x)

	_reaction_label.position.y = - (visual_height_cm * CM_TO_PX) - 40.0
	if npc_id == "":
		_process_generic_reaction(delta, player_m, dist_x)
	else:
		_avoid_dir = 0.0
		_process_named_passive_greet(delta)

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

func _update_look_towards_player(
	delta: float,
	player_node: Node2D,
	player_m: Dictionary,
	abs_dist: float,
	dist_x: float
) -> void:
	var self_eye_y: float = global_position.y - float(m["landmarks"]["eye"]) * CM_TO_PX
	var player_eye_y: float = player_node.global_position.y - float(player_m["landmarks"]["eye"]) * CM_TO_PX
	var diff_y_px: float = player_eye_y - self_eye_y

	var angle: float = clamp(atan2(diff_y_px, max(abs_dist, 1.0)), -PI / 3.0, PI / 3.0)
	look_head_angle = lerp_angle(look_head_angle, angle, 8.0 * delta)
	var max_pitch: float = float(m["head"]) * CM_TO_PX * 0.2
	look_pitch = lerp(look_pitch, sin(angle) * max_pitch, 8.0 * delta)

	dir = 1 if dist_x < 0.0 else -1
	facing = "side"

func _process_generic_reaction(delta: float, player_m: Dictionary, dist_x: float) -> void:
	var actual_height_diff: float = float(player_m["height"]) - float(m["height"])
	var reaction_key: String = _get_reaction_key(actual_height_diff)
	if reaction_key != _current_reaction_key:
		_current_reaction_key = reaction_key
		_show_reaction_text(_get_reaction_text(reaction_key), 1.2)

	# 不感帯: 十分離れていれば逃げるのをやめる（往復バグ防止）
	# REACTION_DIST の半分以上の距離があれば avoid_dir をゼロに向かわせる
	var avoid_dead_zone: float = REACTION_DIST * 0.55
	if reaction_key == "very_huge":
		if abs(dist_x) >= avoid_dead_zone:
			_avoid_dir = lerp(_avoid_dir, 0.0, 8.0 * delta)
		else:
			_avoid_dir = sign(dist_x)
	elif reaction_key == "huge":
		if abs(dist_x) >= avoid_dead_zone:
			_avoid_dir = lerp(_avoid_dir, 0.0, 8.0 * delta)
		else:
			_avoid_dir = sign(dist_x) * 0.45
	else:
		_avoid_dir = 0.0

	_process_generic_passive_greet(delta, player_m)

func _process_generic_passive_greet(delta: float, player_m: Dictionary) -> void:
	if _greet_cooldown_left > 0.0:
		return
	_proximity_time += delta
	if _proximity_time < GENERIC_PASSIVE_TRIGGER_SEC or _greet_triggered_for_approach:
		return

	var passive_key: String = _get_generic_passive_height_key(float(player_m["height"]))
	if passive_key == "same":
		return
	var text: String = _get_generic_passive_text(passive_key, float(player_m["height"]))
	if text == "":
		return

	_greet_triggered_for_approach = true
	_greet_cooldown_left = GENERIC_PASSIVE_COOLDOWN
	_last_generic_callout_text = text
	_show_reaction_text(text, GENERIC_PASSIVE_DURATION)

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

func _process_named_passive_greet(delta: float) -> void:
	if npc_data.is_empty():
		return
	if _greet_cooldown_left > 0.0:
		return
	_proximity_time += delta
	if _proximity_time < NAMED_GREET_TRIGGER_SEC or _greet_triggered_for_approach:
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
	_greet_cooldown_left = NAMED_GREET_COOLDOWN
	_show_reaction_text(String(greet_events[next_index]), NAMED_GREET_DURATION)

func _reset_proximity_state() -> void:
	_player_is_close = false
	_proximity_time = 0.0
	_greet_triggered_for_approach = false

func _show_reaction_text(text: String, duration: float) -> void:
	_reaction_label.text = text
	_reaction_time_left = duration if text != "" else 0.0

func _get_generic_passive_height_key(player_height_cm: float) -> String:
	if player_height_cm >= GENERIC_PASSIVE_VERY_HUGE_CM:
		return "very_huge"
	if player_height_cm >= GENERIC_PASSIVE_HUGE_CM:
		return "huge"
	if player_height_cm >= GENERIC_PASSIVE_TALL_CM:
		return "tall"
	return "same"

func _get_generic_passive_text(passive_key: String, player_height_cm: float) -> String:
	var child_text: String = _get_child_generic_passive_text(passive_key, player_height_cm)
	if child_text != "":
		return child_text

	var stage_bucket: String = _get_generic_passive_stage_bucket()
	var stage_lines: Variant = GENERIC_PASSIVE_LINES.get(stage_bucket, GENERIC_PASSIVE_LINES["default"])
	if not (stage_lines is Dictionary):
		stage_lines = GENERIC_PASSIVE_LINES["default"]
	var texts: Variant = stage_lines.get(passive_key, GENERIC_PASSIVE_LINES["default"].get(passive_key, []))
	if not (texts is Array):
		return ""
	return _pick_non_repeating_text(texts, _last_generic_callout_text)

func _get_child_generic_passive_text(passive_key: String, player_height_cm: float) -> String:
	if not _is_child_generic_npc():
		return ""
	var texts: Variant = GENERIC_CHILD_PASSIVE_LINES.get(passive_key, [])
	if not (texts is Array):
		return ""
	var text: String = _pick_non_repeating_text(texts, _last_generic_callout_text)
	if text.contains("%d"):
		return text % int(round(player_height_cm))
	return text

func _is_child_generic_npc() -> bool:
	return npc_id == "" and m != null and not m.is_empty() and float(m.get("height", 999.0)) <= 125.0

func _get_generic_passive_stage_bucket() -> String:
	var global = get_node_or_null("/root/Global")
	if global == null:
		return "default"
	var stage_id: String = String(global.current_stage_id)
	if stage_id == "station" or stage_id == "train":
		return "station"
	if stage_id == "outdoor":
		return "outdoor"
	if stage_id == "room" or stage_id == "myroom":
		return "room"
	if (
		StageBuilder.is_school_hallway_stage(stage_id)
		or StageBuilder.is_school_classroom_stage(stage_id)
		or StageBuilder.is_schoolyard_stage(stage_id)
		or StageBuilder.is_infirmary_stage(stage_id)
		or StageBuilder.is_gymnasium_stage(stage_id)
	):
		return "school"
	return "default"

func _pick_non_repeating_text(options: Array, last_text: String) -> String:
	var cleaned: Array[String] = []
	for option in options:
		var text: String = String(option).strip_edges()
		if text != "":
			cleaned.append(text)
	if cleaned.is_empty():
		return ""
	var picked_index: int = randi_range(0, cleaned.size() - 1)
	var picked_text: String = cleaned[picked_index]
	if cleaned.size() > 1 and picked_text == last_text:
		picked_text = cleaned[(picked_index + 1) % cleaned.size()]
	return picked_text

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
