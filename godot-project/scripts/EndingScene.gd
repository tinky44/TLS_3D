extends Node2D

## エンディングシーン — 最終比較画面
## キャラメイク時の初期シルエット・比較NPC（はるか）・現在のキャラを並べて表示する

# はるかの体型・外見（Global.core_npcs の定義と一致）
const HARUKA_PARAMS := {
	"height": 155.0, "ratio": 7.3, "legRatio": 48.0, "sex": "female"
}
const HARUKA_APPEARANCE := {
	"hair_style": "ponytail", "hair_color": "#111111",
	"tops_type": "school_uniform", "tops_color": "#ffffff",
	"bottoms_type": "skirt_short", "bottoms_color": "#333333",
	"shoes_type": "loafer", "shoes_color": "#4b4b52",
	"hat_type": "none", "hat_color": "#000000",
	"bag_type": "none", "bag_color": "#000000",
}

@onready var _growth_label: Label  = $UI/GrowthLabel
@onready var _back_btn: Button     = $UI/BackButton


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.09, 1.0))

	var global: Node = get_node("/root/Global")
	var vp   := get_viewport().get_visible_rect().size
	var gnd  := vp.y - 60.0  # 地面 Y 座標（キャラの足元）

	# 初期パラメータが空の場合は growth_history[0] から復元（旧セーブ互換）
	var init_p:  Dictionary = global.initial_params  if not global.initial_params.is_empty()  else _fallback_params(global)
	var init_ap: Dictionary = global.initial_appearance if not global.initial_appearance.is_empty() else global.current_appearance

	# はるかの体型をゲーム内の設定（年齢連動平均身長）に合わせて動的に構築
	var haruka_core: Dictionary = global.core_npcs.get("haruka", {}) if global.get("core_npcs") != null else {}
	var haruka_height: float = HARUKA_PARAMS["height"]
	if haruka_core.get("height_mode", "") == "avg":
		haruka_height = global.get_avg_height(global.age) + haruka_core.get("height_base", 155.0) - 158.5
	var haruka_params_dynamic := HARUKA_PARAMS.duplicate()
	haruka_params_dynamic["height"] = haruka_height

	# 外見もcore_npcsの定義を優先（fallbackはHARUKA_APPEARANCE）
	var haruka_appearance_dynamic: Dictionary = HARUKA_APPEARANCE.duplicate()
	var haruka_core_appearance: Dictionary = haruka_core.get("appearance", {}) as Dictionary
	for k in haruka_core_appearance.keys():
		haruka_appearance_dynamic[k] = haruka_core_appearance[k]

	# [ 左: 初期シルエット(α0.3) ] [ 中: はるか ] [ 右: 現在のキャラ ]
	var slots := [
		{"params": init_p,                     "appearance": init_ap,                      "x": vp.x * 0.22, "alpha": 0.3},
		{"params": haruka_params_dynamic,       "appearance": haruka_appearance_dynamic,     "x": vp.x * 0.46, "alpha": 1.0},
		{"params": global.current_params,       "appearance": global.current_appearance,     "x": vp.x * 0.72, "alpha": 1.0},
	]

	# Global の current_params を一時的に各キャラ用に差し替えて update_measurements() を実行
	var saved_params:     Dictionary = global.current_params.duplicate(true)
	var saved_appearance: Dictionary = global.current_appearance.duplicate(true)

	for slot in slots:
		_spawn_player(slot, gnd, global)

	global.current_params     = saved_params
	global.current_appearance = saved_appearance

	_build_growth_text(global)

	_back_btn.pressed.connect(_on_back_pressed)
	_back_btn.modulate.a = 0.0

	# フェードイン
	modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self,        "modulate:a",      1.0, 1.2)
	tw.tween_property(_back_btn,   "modulate:a",      1.0, 1.2)
	tw.tween_property(_growth_label, "modulate:a",    1.0, 1.2)


func _spawn_player(slot: Dictionary, ground_y: float, global: Node) -> void:
	global.current_params = slot["params"].duplicate(true)

	var player: Node = load("res://Player.tscn").instantiate()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.position     = Vector2(slot["x"], ground_y)
	player.facing       = "front"
	var alpha: float = slot["alpha"]
	if alpha < 1.0:
		# CanvasGroup を使って子ノード全体をまとめてオフスクリーン合成することで
		# 素体が服の下から透けて見えるアルファブレンドの問題を防ぐ
		var canvas_group := CanvasGroup.new()
		canvas_group.modulate.a = alpha
		add_child(canvas_group)
		canvas_group.add_child(player)
	else:
		add_child(player)  # _ready() → update_measurements() がここで走る

	# 外見を上書き（CharacterDrawer が player.appearance を優先する）
	player.appearance = slot["appearance"].duplicate(true)
	player.character_drawer.queue_redraw()


func _fallback_params(global: Node) -> Dictionary:
	# initial_params が空の旧セーブ用フォールバック: growth_history[0] の身長を使う
	if not global.growth_history.is_empty():
		var h := float(global.growth_history[0].get("height", global.current_params["height"]))
		return {
			"height": h,
			"ratio":  clamp(5.5 + (h - 100.0) / 30.0, 5.0, 9.0),
			"legRatio": 48.0,
			"sex": global.current_params.get("sex", "female"),
		}
	return global.current_params.duplicate(true)


func _build_growth_text(global: Node) -> void:
	if global.growth_history.is_empty():
		return
	var h0  := float(global.growth_history[0].get("height", 0.0))
	var h1  := float(global.current_params.get("height", 0.0))
	var avg: float = global.get_avg_height(global.age)
	var lines := PackedStringArray()
	lines.append("%.0fcm → %.0fcm  (+ %.0fcm)" % [h0, h1, h1 - h0])
	lines.append("平均身長より %+.0fcm" % (h1 - avg))
	if not global.visited_stages.is_empty():
		lines.append("訪れた場所：%d か所" % global.visited_stages.size())
	_growth_label.text = "\n".join(lines)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")
