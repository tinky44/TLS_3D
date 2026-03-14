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

	await _wait_frames(int(options.get("frames", DEFAULT_WAIT_FRAMES)))
	var delay_sec := float(options.get("delay_sec", DEFAULT_DELAY_SEC))
	if delay_sec > 0.0:
		await get_tree().create_timer(delay_sec).timeout

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
	global.current_term_plan = ""
	global.term_hotspot_flags = {}
	global.term_memory_note = ""
	global.current_stage_id = String(options.get("stage", DEFAULT_STAGE_ID))

	if options.has("age"):
		global.age = int(options["age"])
	if options.has("term"):
		global.term = int(options["term"])
	if options.has("height"):
		global.current_params["height"] = float(options["height"])

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

	var scene_key := String(options.get("scene", DEFAULT_SCENE_KEY))
	options["scene_path"] = SCENE_MAP.get(scene_key, SCENE_MAP[DEFAULT_SCENE_KEY])
	return options

func _wait_frames(frame_count: int) -> void:
	for _i in range(maxi(1, frame_count)):
		await get_tree().process_frame

func _fail(message: String) -> void:
	push_error(message)
	print("CODEX_CAPTURE_ERROR=%s" % message)
	get_tree().quit(1)
