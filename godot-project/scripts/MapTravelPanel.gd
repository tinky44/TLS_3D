extends Control

signal travel_requested(stage_id: String)

const NODE_RADIUS := 13.0
const EDGE_COLOR := Color(0.50, 0.55, 0.70, 0.85)
const EDGE_WIDTH := 2.0

const NODE_COLOR_DEFAULT := Color(0.35, 0.58, 0.92)
const NODE_COLOR_CURRENT := Color(0.22, 0.76, 0.40)
const NODE_COLOR_LOCKED  := Color(0.45, 0.45, 0.50)

const AREA_LABEL_COLOR  := Color(0.72, 0.78, 0.88)
const NODE_LABEL_COLOR  := Color(0.90, 0.93, 0.97)
const NODE_LOCKED_LABEL := Color(0.50, 0.50, 0.55)

const MAP_AREAS: Array[Dictionary] = [
	{
		"id":     "chuo",
		"name":   "中央町",
		"color":  Color(0.30, 0.45, 0.70, 0.18),
		"border": Color(0.40, 0.60, 0.90, 0.50),
		"rect":   Rect2(10, 10, 195, 285),
	},
	{
		"id":     "tonari",
		"name":   "隣町",
		"color":  Color(0.25, 0.55, 0.30, 0.18),
		"border": Color(0.35, 0.75, 0.45, 0.50),
		"rect":   Rect2(10, 315, 160, 95),
	},
	{
		"id":     "gakuen",
		"name":   "学園町",
		"color":  Color(0.60, 0.40, 0.20, 0.18),
		"border": Color(0.85, 0.60, 0.30, 0.50),
		"rect":   Rect2(180, 15, 90, 185),
	},
]

const MAP_NODES: Dictionary = {
	"myroom": {
		"label":    "自宅",
		"stage_id": "myroom",
		"pos":      Vector2(80, 80),
	},
	"station": {
		"label":    "中央駅",
		"stage_id": "station",
		"pos":      Vector2(120, 170),
	},
	"school_elementary": {
		"label":    "小学校",
		"stage_id": "school_elementary",
		"pos":      Vector2(60, 255),
	},
	"school_middle": {
		"label":    "中学校",
		"stage_id": "school_middle",
		"pos":      Vector2(80, 360),
	},
	"gakuenmae": {
		"label":    "学園前駅",
		"stage_id": "gakuenmae",
		"pos":      Vector2(230, 75),
	},
	"school_high": {
		"label":    "高校",
		"stage_id": "school_high",
		"pos":      Vector2(230, 155),
	},
}

const MAP_EDGES: Array = [
	["myroom",           "station"],
	["station",          "school_elementary"],
	["station",          "school_middle"],
	["station",          "gakuenmae"],
	["gakuenmae",        "school_high"],
]

var _current_stage_id: String = ""
var _age: int = 0

func refresh(current_stage_id: String, age: int) -> void:
	_current_stage_id = current_stage_id
	_age = age
	_rebuild_buttons()
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	# エリア背景
	for area in MAP_AREAS:
		var r: Rect2 = area["rect"]
		draw_rect(r, area["color"])
		draw_rect(r, area["border"], false, 1.5)
		draw_string(font, r.position + Vector2(8, 18), area["name"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, AREA_LABEL_COLOR)
	# エッジ
	for edge in MAP_EDGES:
		var p1: Vector2 = MAP_NODES[edge[0]]["pos"]
		var p2: Vector2 = MAP_NODES[edge[1]]["pos"]
		draw_line(p1, p2, EDGE_COLOR, EDGE_WIDTH, true)
	# ノード円
	for node_id in MAP_NODES:
		var def = MAP_NODES[node_id]
		var pos: Vector2 = def["pos"]
		var stage_id: String = def["stage_id"]
		var locked: bool = _is_locked(stage_id)
		var current: bool = (_current_stage_id == stage_id)
		var col: Color
		if current:
			col = NODE_COLOR_CURRENT
		elif locked:
			col = NODE_COLOR_LOCKED
		else:
			col = NODE_COLOR_DEFAULT
		draw_circle(pos, NODE_RADIUS, col)
		draw_arc(pos, NODE_RADIUS, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.25), 1.5)

func _rebuild_buttons() -> void:
	for child in get_children():
		child.queue_free()
	for node_id in MAP_NODES:
		var def = MAP_NODES[node_id]
		var stage_id: String = def["stage_id"]
		var locked: bool = _is_locked(stage_id)
		var current: bool = (_current_stage_id == stage_id)
		var pos: Vector2 = def["pos"]
		# 透明ボタン（クリック判定用）
		var btn := Button.new()
		btn.flat = true
		btn.size = Vector2(32, 32)
		btn.position = pos - Vector2(16, 16)
		btn.disabled = locked or current
		btn.focus_mode = Control.FOCUS_NONE
		if current:
			btn.tooltip_text = "今いる場所"
		elif locked:
			btn.tooltip_text = _get_lock_reason(stage_id)
		else:
			var sid := stage_id
			btn.pressed.connect(func(): travel_requested.emit(sid))
		add_child(btn)
		# ノード名ラベル
		var lbl := Label.new()
		lbl.text = def["label"]
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.position = pos + Vector2(-32, NODE_RADIUS + 3)
		lbl.size = Vector2(70, 18)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var lbl_color: Color = NODE_LOCKED_LABEL if locked else NODE_LABEL_COLOR
		lbl.add_theme_color_override("font_color", lbl_color)
		add_child(lbl)

func _is_locked(stage_id: String) -> bool:
	match stage_id:
		"school_elementary":
			return _age > 11
		"school_middle":
			return _age < 12 or _age > 14
		"school_high":
			return _age < 15
	return false

func _get_lock_reason(stage_id: String) -> String:
	match stage_id:
		"school_elementary":
			if _age > 11:
				return "懐かしいな……。今はもう、このままは入れない。"
		"school_middle":
			if _age < 12:
				return "まだこの学校に入る時期じゃない。"
			if _age > 14:
				return "今はもう、この学校には入れない。"
		"school_high":
			if _age < 15:
				return "まだこの学校に入るには早い。"
	return ""
