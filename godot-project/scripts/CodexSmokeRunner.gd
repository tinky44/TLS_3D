extends Node

const SCENE_MAP := {
	"title": "res://scenes/TitleScene.tscn",
	"creator": "res://scenes/CharacterCreatorScene.tscn",
	"save_slot": "res://scenes/SaveSlotSelectScene.tscn",
	"main": "res://Main.tscn",
}

const DEFAULT_SCENE_KEY := "main"
const DEFAULT_STAGE_ID := "room"
const DEFAULT_WAIT_FRAMES := 12
const DEFAULT_DELAY_SEC := 0.15
const DEFAULT_OUTPUT_DIR := "user://automation_captures"
const TOPS_COLOR_MAP := {
	"sailor": "#1a2a5e",
	"blazer": "#212840",
	"blouse_bow": "#f0e8e0",
	"jumper_skirt": "#212840",
	"sweater": "#7a9a7a",
	"t_shirt": "#ab82a8",
}
const BOTTOMS_COLOR_MAP := {
	"skirt": "#3a5f8a",
	"skirt_long": "#3a5f8a",
	"skirt_sailor": "#1a2a5e",
	"pants": "#3a5f8a",
}
const POSE_ALIASES := {
	"normal": "normal",
	"stand": "normal",
	"taiiku_suwari": "taiiku_suwari",
	"taiiku": "taiiku_suwari",
	"gym_sit": "taiiku_suwari",
	"chair_sit": "chair_sit",
	"chair": "chair_sit",
	"reach_low": "reach_low",
	"reach_up": "reach_up",
	"sleep": "sleep",
}
const FACING_ALIASES := {
	"front": "front",
	"back": "back",
	"side": "side",
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	var options := _parse_args(OS.get_cmdline_user_args())
	if not bool(options.get("enabled", false)):
		_fail("missing --codex-smoke")
		return

	var global = get_node_or_null("/root/Global")
	if global == null:
		_fail("Global autoload is missing")
		return

	_prepare_global_state(global, options)

	var scene_path := String(options.get("scene_path", SCENE_MAP[DEFAULT_SCENE_KEY]))
	var packed_scene: Resource = load(scene_path)
	if packed_scene == null or not (packed_scene is PackedScene):
		_fail("could not load scene: %s" % scene_path)
		return

	var scene_instance := (packed_scene as PackedScene).instantiate()
	add_child(scene_instance)
	_apply_scene_overrides(scene_instance, options)

	await _wait_frames(int(options.get("frames", DEFAULT_WAIT_FRAMES)))
	var delay_sec := float(options.get("delay_sec", DEFAULT_DELAY_SEC))
	if delay_sec > 0.0:
		await get_tree().create_timer(delay_sec).timeout
	_apply_post_wait_overrides(scene_instance, options)
	await _wait_frames(1)

	var prefix := String(options.get("prefix", ""))
	if prefix == "":
		prefix = "smoke_%s" % String(options.get("scene", DEFAULT_SCENE_KEY))
	var output_dir := String(options.get("output_dir", DEFAULT_OUTPUT_DIR))
	var result: Dictionary = await global.save_viewport_screenshot(get_viewport(), prefix, output_dir)
	if bool(result.get("ok", false)):
		print("CODEX_CAPTURE_PATH=%s" % String(result.get("save_path", "")))
		get_tree().quit(0)
		return

	_fail(String(result.get("error", "unknown error")))

func _prepare_global_state(global, options: Dictionary) -> void:
	global.current_slot = -1
	global.pending_events = []
	global.pending_term_choice = false
	global.term_hotspot_flags = {}
	global.term_memory_note = ""
	global.current_stage_id = String(options.get("stage", DEFAULT_STAGE_ID))
	global.visited_stages[global.current_stage_id] = true

	if options.has("age"):
		global.age = int(options["age"])
	if options.has("term"):
		global.term = int(options["term"])
	if options.has("height"):
		global.current_params["height"] = float(options["height"])
	if options.has("stress"):
		global.stress = int(options["stress"])

	_apply_appearance_overrides(global, options)

	if global.has_method("_ensure_growth_history"):
		global.call("_ensure_growth_history")

func _parse_args(args: PackedStringArray) -> Dictionary:
	var options := {
		"enabled": false,
		"scene": DEFAULT_SCENE_KEY,
		"scene_path": SCENE_MAP[DEFAULT_SCENE_KEY],
		"frames": DEFAULT_WAIT_FRAMES,
		"delay_sec": DEFAULT_DELAY_SEC,
		"stage": DEFAULT_STAGE_ID,
		"output_dir": DEFAULT_OUTPUT_DIR,
	}

	for arg in args:
		if arg == "--codex-smoke":
			options["enabled"] = true
			continue
		if not arg.begins_with("--"):
			continue

		var option_body := arg.substr(2)
		var separator_index := option_body.find("=")
		if separator_index < 0:
			continue

		var key := option_body.substr(0, separator_index)
		var value := option_body.substr(separator_index + 1)

		match key:
			"scene":
				options["scene"] = value if value != "" else DEFAULT_SCENE_KEY
			"frames":
				options["frames"] = maxi(1, int(value))
			"delay-sec":
				options["delay_sec"] = maxf(0.0, float(value))
			"stage":
				options["stage"] = value if value != "" else DEFAULT_STAGE_ID
			"output-dir":
				options["output_dir"] = value if value != "" else DEFAULT_OUTPUT_DIR
			"prefix":
				options["prefix"] = value
			"age":
				options["age"] = int(value)
			"term":
				options["term"] = int(value)
			"height":
				options["height"] = float(value)
			"stress":
				options["stress"] = int(value)
			"pose":
				var pose := _normalize_pose(value)
				if pose != "":
					options["pose"] = pose
			"facing":
				var facing := _normalize_facing(value)
				if facing != "":
					options["facing"] = facing
			"dir":
				options["dir"] = -1 if int(value) < 0 else 1
			"auto-crouch":
				var parsed_bool: Variant = _parse_bool_option(value)
				if parsed_bool != null:
					options["auto_crouch"] = parsed_bool
			"target-crouch-cm":
				options["target_crouch_cm"] = float(value)
			"look-head-angle":
				options["look_head_angle"] = float(value)
			"look-pitch":
				options["look_pitch"] = float(value)
			"tops-type":
				options["tops_type"] = value
			"tops-color":
				options["tops_color"] = value
			"bottoms-type":
				options["bottoms_type"] = value
			"bottoms-color":
				options["bottoms_color"] = value
			"hair-style":
				options["hair_style"] = value
			"hair-color":
				options["hair_color"] = value
			"hat-type":
				options["hat_type"] = value
			"hat-color":
				options["hat_color"] = value
			"bag-type":
				options["bag_type"] = value
			"bag-color":
				options["bag_color"] = value
			"fit-stage":
				var fit_stage: Variant = _parse_bool_option(value)
				if fit_stage != null:
					options["fit_stage"] = fit_stage

	var scene_key := String(options.get("scene", DEFAULT_SCENE_KEY))
	options["scene_path"] = SCENE_MAP.get(scene_key, SCENE_MAP[DEFAULT_SCENE_KEY])
	return options

func _apply_appearance_overrides(global, options: Dictionary) -> void:
	var appearance_updates := {
		"tops_type": options.get("tops_type", null),
		"tops_color": options.get("tops_color", null),
		"bottoms_type": options.get("bottoms_type", null),
		"bottoms_color": options.get("bottoms_color", null),
		"hair_style": options.get("hair_style", null),
		"hair_color": options.get("hair_color", null),
		"hat_type": options.get("hat_type", null),
		"hat_color": options.get("hat_color", null),
		"bag_type": options.get("bag_type", null),
		"bag_color": options.get("bag_color", null),
	}

	for key in appearance_updates.keys():
		var value: Variant = appearance_updates[key]
		if value != null:
			global.current_appearance[key] = value

	if options.has("tops_type") and not options.has("tops_color"):
		var tops_type := String(options["tops_type"])
		if TOPS_COLOR_MAP.has(tops_type):
			global.current_appearance["tops_color"] = TOPS_COLOR_MAP[tops_type]

	if options.has("bottoms_type") and not options.has("bottoms_color"):
		var bottoms_type := String(options["bottoms_type"])
		if BOTTOMS_COLOR_MAP.has(bottoms_type):
			global.current_appearance["bottoms_color"] = BOTTOMS_COLOR_MAP[bottoms_type]

func _apply_scene_overrides(scene_instance: Node, options: Dictionary) -> void:
	var player: Node = _find_player(scene_instance)
	if player == null:
		return

	if options.has("pose"):
		player.set("pose", String(options["pose"]))
	if options.has("facing"):
		player.set("facing", String(options["facing"]))
	if options.has("dir"):
		player.set("dir", int(options["dir"]))
	if options.has("auto_crouch"):
		player.set("auto_crouch", bool(options["auto_crouch"]))
	if options.has("target_crouch_cm"):
		player.set("target_crouch_cm", float(options["target_crouch_cm"]))
	if options.has("look_head_angle"):
		player.set("look_head_angle", float(options["look_head_angle"]))
	if options.has("look_pitch"):
		player.set("look_pitch", float(options["look_pitch"]))

	if player.has_method("update_measurements"):
		player.call("update_measurements")
	else:
		var drawer: Node = player.get_node_or_null("CharacterDrawer")
		if drawer != null:
			drawer.call("queue_redraw")

func _apply_post_wait_overrides(scene_instance: Node, options: Dictionary) -> void:
	if not bool(options.get("fit_stage", false)):
		return
	_fit_camera_to_stage(scene_instance, String(options.get("stage", DEFAULT_STAGE_ID)))

func _fit_camera_to_stage(scene_instance: Node, requested_stage_id: String) -> void:
	var player: Node = _find_player(scene_instance)
	if player == null:
		return
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return

	var stage_width_px := _resolve_stage_width_px(requested_stage_id, player)
	if stage_width_px <= 1.0:
		return

	var view_size := get_viewport().get_visible_rect().size
	if view_size.x <= 1.0:
		return

	# Keep camera behavior unchanged for gameplay; this runs only in capture mode.
	var zoom_factor := view_size.x / stage_width_px
	zoom_factor = clampf(zoom_factor, 0.05, 1.0)
	cam.zoom = Vector2(zoom_factor, zoom_factor)
	cam.position_smoothing_enabled = false

	var current_pos: Vector2 = player.global_position
	current_pos.x = stage_width_px * 0.5
	player.global_position = current_pos

	if cam.has_method("force_update_scroll"):
		cam.call("force_update_scroll")

func _resolve_stage_width_px(requested_stage_id: String, player: Node) -> float:
	var global = get_node_or_null("/root/Global")
	var age := 0
	if global != null and global.get("age") != null:
		age = int(global.get("age"))

	var resolved_stage_id := StageBuilder.resolve_stage_id(requested_stage_id, age)
	var stage_data: Dictionary = StageBuilder.STAGES.get(resolved_stage_id, {})
	if stage_data.is_empty():
		stage_data = StageBuilder.STAGES.get(requested_stage_id, {})
	if stage_data.is_empty():
		return 0.0

	var p := 2.0
	if player.get("CM_TO_PX") != null:
		p = float(player.get("CM_TO_PX"))
	return float(stage_data.get("width", 0.0)) * p

func _find_player(scene_instance: Node) -> Node:
	var player := scene_instance.get_node_or_null("Player")
	if player != null:
		return player
	return scene_instance.find_child("Player", true, false)

func _normalize_pose(value: String) -> String:
	var key := value.strip_edges().to_lower()
	if key == "":
		return ""
	return String(POSE_ALIASES.get(key, key))

func _normalize_facing(value: String) -> String:
	var key := value.strip_edges().to_lower()
	if key == "":
		return ""
	return String(FACING_ALIASES.get(key, key))

func _parse_bool_option(value: String) -> Variant:
	var key := value.strip_edges().to_lower()
	if key in ["1", "true", "yes", "on"]:
		return true
	if key in ["0", "false", "no", "off"]:
		return false
	return null

func _wait_frames(frame_count: int) -> void:
	for _i in range(maxi(1, frame_count)):
		await get_tree().process_frame

func _fail(message: String) -> void:
	push_error(message)
	print("CODEX_CAPTURE_ERROR=%s" % message)
	get_tree().quit(1)
