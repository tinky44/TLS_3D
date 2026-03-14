extends Node

signal screenshot_saved(result: Dictionary)
signal screenshot_failed(result: Dictionary)

const CM_TO_PX: float = 2.0
const DEFAULT_TERM_PLAN: String = "school"

# プレイヤーの身体パラメータ (初期値として「高身長女性」を設定)
var current_params: Dictionary = {
	"height": 180.0,
	"ratio": 7.5,
	"legRatio": 48.0,
	"sex": "female"
}

var current_appearance: Dictionary = {
	"hair_style": "short",
	"hair_color": "#4a3c31",
	"tops_type": "t_shirt",
	"tops_color": "#ab82a8",
	"bottoms_type": "pants",
	"bottoms_color": "#3a5f8a",
	"shoes_type": "loafer",
	"shoes_color": "#4b4b52",
	"hat_type": "school_hat",
	"hat_color": "#ffd700",
	"bag_type": "none",
	"bag_color": "#c01020"
}

var system_settings: Dictionary = {
	"move_speed": 250.0
}

var current_stage_id: String = "room"
var current_slot: int = -1 # 現在使用中のスロット番号 (-1 = 未選択)
var slot_select_mode: String = "save" # "save" or "load"
var _screenshot_in_progress: bool = false

# 成長パラメータ（term=6 が小学1年・6歳のスタート）
var age: int = 6
var term: int = 6
var growth_factor: float = 1.0
var growth_type: String = "normal" # "slow" / "normal" / "fast" / "explosive"
var prev_height: float = 0.0
var growth_history: Array = []

var active_companion_id: String = "" # 現在同行しているNPCのID
var met_npcs: Array = [] # 面識のあるNPCのIDリスト
var haruka_invited_this_term: bool = false # はるかが今学期測定に誘ったか
var haruka_following: bool = false # はるかが追随中か
var senior_gym_invited: bool = false # 先輩から体育館に誘われたか（1回のみ）

# ─── バレー部ストーリーフラグ ──────────────────────────────────────
var vball_story_phase: int = 0 # 0=未出会い 1=廊下で出会った 2=入部 3=脚痛 4=相談済 5=休部 6=夏後 7=継続決定
var is_leg_pain: bool = false # 脚の痛みフラグ（歩行変化に影響）
var vball_joined: bool = false # バレー部入部フラグ

# ─── 感情パラメータ ────────────────────────────────────────────
var self_confidence: int = 0 # 自信：高身長を肯定的に受け入れた選択の累積
var self_complex: int = 0 # コンプレックス：高身長を否定的に感じた選択の累積
var stress: int = 0 # 今学期の生活で溜まるしんどさ
var pending_term_choice: bool = false # 進級時の続行/終了選択が必要か
var current_term_plan: String = DEFAULT_TERM_PLAN # "home" / "school" / "station"
var term_hotspot_flags: Dictionary = {} # 今学期に体験済みのホットスポット
var term_memory_note: String = "" # 今学期の印象的な出来事メモ

# コアNPCの定義
var core_npcs: Dictionary = {
	"haruka": {
		"name": "はるか",
		"role": "friend",
		"height_base": 155.0,
		"height_mode": "avg", # 年齢平均に近い設定
		"is_student": true,
		"greet_events": [
			"ねえ、最近また伸びた？",
			"一緒に歩くとすぐ見つけられるね。",
			"今日も目線、高いなあ。"
		],
		"appearance": {
			"hair_style": "ponytail",
			"hair_color": "#111111",
			"tops_type": "school_uniform",
			"tops_color": "#ffffff",
			"bottoms_type": "skirt_short",
			"bottoms_color": "#333333"
		}
	},
	"senior": {
		"name": "先輩",
		"role": "senior",
		"height_base": 168.0,
		"height_mode": "fixed",
		"is_student": true,
		"greet_events": [
			"お、今日も目立ってるな。",
			"ネット越しでもすぐ分かる背だな。",
			"調子どうだ？ 無理してないか。"
		],
		"appearance": {
			"hair_style": "short",
			"hair_color": "#223344",
			"tops_type": "track_suit",
			"tops_color": "#114422",
			"bottoms_type": "pants",
			"bottoms_color": "#114422"
		}
	},
	"mother": {
		"name": "お母さん",
		"role": "family",
		"height_base": 158.0,
		"height_mode": "fixed",
		"appearance": {
			"hair_style": "long",
			"hair_color": "#332211",
			"tops_type": "sweater",
			"tops_color": "#aa8866",
			"bottoms_type": "skirt_long",
			"bottoms_color": "#443322"
		}
	},
	"father": {
		"name": "お父さん",
		"role": "family",
		"height_base": 170.0,
		"height_mode": "fixed",
		"appearance": {
			"hair_style": "short",
			"hair_color": "#111111",
			"tops_type": "shirt",
			"tops_color": "#eeeeee",
			"bottoms_type": "pants",
			"bottoms_color": "#222222"
		}
	}
}

const AVG_HEIGHT_FEMALE: Dictionary = {
	3: 95.0, 4: 101.0, 5: 107.0,
	6: 113.0, 7: 119.0, 8: 124.0, 9: 130.0,
	10: 136.0, 11: 143.0, 12: 150.0,
	13: 154.0, 14: 156.0, 15: 157.0,
	16: 158.0, 17: 158.5, 18: 158.5
}

# 年齢から開始学期番号を返す（term_to_age の逆変換）
static func age_to_term(a: int) -> int:
	if a <= 2: return 0
	elif a <= 5: return (a - 3) * 2
	elif a <= 12: return 6 + (a - 6) * 3
	elif a <= 15: return 27 + (a - 13) * 3
	else: return 36 + (a - 16) * 3

static func term_to_age(t: int) -> int:
	if t < 6: return 3 + floori(t / 2.0)
	elif t < 27: return 6 + floori((t - 6) / 3.0)
	elif t < 36: return 13 + floori((t - 27) / 3.0)
	else: return 16 + min(floori((t - 36) / 3.0), 2)

static func get_school_grade_name(a: int) -> String:
	if a >= 6 and a <= 11:
		return "小学%d年生" % (a - 5)
	if a >= 12 and a <= 14:
		return "中学%d年生" % (a - 11)
	if a >= 15 and a <= 17:
		return "高校%d年生" % (a - 14)
	if a >= 18:
		return "卒業後"
	return "%d歳" % a

static func get_term_in_school_year(a: int, t: int) -> int:
	var max_terms: int = 3 if a >= 6 else 2
	var base_term: int = age_to_term(a)
	return clampi(t - base_term + 1, 1, max_terms)

static func get_school_term_label(a: int, t: int) -> String:
	if a >= 6:
		return "%s、%d学期" % [get_school_grade_name(a), get_term_in_school_year(a, t)]
	return "%d歳、%d学期" % [a, get_term_in_school_year(a, t)]

static func get_base_growth(current_age: int) -> float:
	if current_age <= 5: return 2.0
	elif current_age <= 9: return 1.8
	elif current_age <= 12: return 2.5
	elif current_age <= 15: return 3.2
	elif current_age == 16: return 2.0
	else: return 0.8

func calc_growth() -> float:
	return get_base_growth(age) * growth_factor * randf_range(0.7, 1.3)

func _ensure_growth_history() -> void:
	if growth_history.is_empty():
		record_growth_history("start")

func record_growth_history(source: String = "measurement") -> void:
	var height_now := float(current_params["height"])
	var avg_height := get_avg_height(age)
	var diff_prev := 0.0
	if prev_height > 0.0:
		diff_prev = height_now - prev_height
	growth_history.append({
		"term": term,
		"age": age,
		"height": height_now,
		"avg_height": avg_height,
		"diff_avg": height_now - avg_height,
		"diff_prev": diff_prev,
		"source": source
	})

# ─── イベントキュー ────────────────────────────────────────────
var pending_events: Array = []

func queue_event(event_id: String) -> void:
	pending_events.append(event_id)

func pop_next_event() -> String:
	if pending_events.is_empty(): return ""
	return pending_events.pop_front()

func add_stress(amount: int) -> void:
	stress = int(clamp(stress + amount, 0, 100))

func append_term_memory_note(note: String) -> void:
	if note == "":
		return
	if term_memory_note == "":
		term_memory_note = note
		return
	var existing_lines: PackedStringArray = term_memory_note.split("\n", false)
	if existing_lines.has(note):
		return
	term_memory_note += "\n" + note

func mark_term_hotspot_done(hotspot_id: String) -> void:
	term_hotspot_flags[hotspot_id] = true

func has_term_hotspot_done(hotspot_id: String) -> bool:
	return bool(term_hotspot_flags.get(hotspot_id, false))

# 学校段階を返す: 0=小低 1=小高 2=中学 3=高校 4=卒業後
static func _school_level_from_age(a: int) -> int:
	if a <= 8: return 0
	elif a <= 11: return 1
	elif a <= 14: return 2
	elif a <= 17: return 3
	return 4

# 学年に対応する制服パラメータを返す（該当なしなら空辞書）
static func get_school_uniform(a: int) -> Dictionary:
	if a >= 6 and a <= 8: # 小学校低学年（1-3年生）: サスペンダースカート
		return {
			"tops_type": "jumper_skirt",
			"tops_color": "#1a2a5e",
			"bottoms_type": "skirt",
			"bottoms_color": "#1a2a5e"
		}
	elif a <= 11: # 小学校高学年（4-6年生）: リボンブラウス
		return {
			"tops_type": "blouse_bow",
			"tops_color": "#f0e8e0",
			"bottoms_type": "skirt",
			"bottoms_color": "#1a2a5e"
		}
	elif a <= 14: # 中学校: セーラー服
		return {
			"tops_type": "sailor",
			"tops_color": "#1a2a5e",
			"bottoms_type": "skirt_sailor",
			"bottoms_color": "#1a2a5e"
		}
	elif a <= 17: # 高校: ジャンパースカート
		return {
			"tops_type": "blazer",
			"tops_color": "#212840",
			"bottoms_type": "skirt",
			"bottoms_color": "#212840"
		}
	return {}

static func get_school_stage_suffix(a: int) -> String:
	if a <= 11:
		return "elementary"
	elif a <= 14:
		return "middle"
	return "high"

static func get_school_stage_id(base_id: String, a: int) -> String:
	match base_id:
		"school", "school_hallway", "schoolyard", "infirmary", "gymnasium":
			return "%s_%s" % [base_id, get_school_stage_suffix(a)]
		_:
			return base_id

static func get_shoes_for_stage(stage_id: String) -> String:
	if stage_id == "room" or stage_id == "myroom":
		return "socks"
	if (
		stage_id == "school"
		or stage_id == "school_hallway"
		or stage_id.begins_with("school_")
		or stage_id.begins_with("infirmary")
		or stage_id.begins_with("gymnasium")
	):
		return "uwabaki"
	return "loafer"

func advance_term() -> void:
	prev_height = current_params["height"]
	var prev_age: int = age
	var prev_school_level: int = _school_level_from_age(prev_age)
	term += 1
	age = term_to_age(term)
	var school_level: int = _school_level_from_age(age)
	current_params["height"] += calc_growth()
	# 夏休み（1学期→2学期）急成長: term>=6 かつ (term-6)%3==1
	if term >= 6 and (term - 6) % 3 == 1:
		current_params["height"] += 10.0
		queue_event("summer_growth")
	# 身長に合わせて頭身を自動更新（最大9頭身）
	var h: float = current_params["height"]
	current_params["ratio"] = clamp(5.5 + (h - 100.0) / 30.0, 5.0, 9.0)
	# 進学時（学校段階が変わった場合）に制服を自動更新
	if school_level != prev_school_level:
		var uniform := get_school_uniform(age)
		for key in uniform.keys():
			current_appearance[key] = uniform[key]
		current_appearance["hat_type"] = "school_hat" if age < 12 else "none"
	record_growth_history("growth")
	queue_event("semester_start") # 学期開始イベントを予約
	haruka_invited_this_term = false
	haruka_following = false
	pending_term_choice = school_level != prev_school_level and school_level >= 1 and school_level <= 3
	current_term_plan = DEFAULT_TERM_PLAN
	term_hotspot_flags = {}
	term_memory_note = ""

func get_avg_height(a: int) -> float:
	return AVG_HEIGHT_FEMALE.get(clamp(a, 3, 18), 158.5)

func get_measurement_comment(diff_avg: float) -> String:
	if diff_avg > 50.0:
		return "……また伸びてる。身長計、足りなくなってきたかも"
	elif diff_avg > 30.0:
		return "え、また伸びてる？先月測ったばかりなのに"
	elif diff_avg > 10.0:
		return "やっぱり大きいですね。クラスで一番ですよ"
	else:
		return "標準的な身長ですね"

const SCREENSHOT_DIR = "user://screenshots"
const SAVE_PATH = "user://settings.cfg"
const SLOTS_PATH = "user://save_slots.cfg"
const SLOT_COUNT: int = 20

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	load_settings()
	_ensure_growth_history()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F12:
		request_current_viewport_screenshot()
		get_viewport().set_input_as_handled()

func request_current_viewport_screenshot(prefix: String = "", output_dir: String = SCREENSHOT_DIR) -> void:
	if _screenshot_in_progress:
		return
	var viewport := get_viewport()
	if viewport == null:
		var missing_viewport_result := {
			"ok": false,
			"error": "Viewport is not available."
		}
		screenshot_failed.emit(missing_viewport_result)
		push_warning("Screenshot save failed: viewport is not available.")
		return
	_screenshot_in_progress = true
	call_deferred("_complete_viewport_screenshot", viewport, prefix, output_dir)

func _complete_viewport_screenshot(viewport: Viewport, prefix: String, output_dir: String) -> void:
	var effective_prefix := prefix
	if effective_prefix.strip_edges() == "":
		effective_prefix = _get_default_screenshot_prefix()
	var result: Dictionary = await save_viewport_screenshot(viewport, effective_prefix, output_dir)
	_screenshot_in_progress = false
	if bool(result.get("ok", false)):
		screenshot_saved.emit(result)
		print("SCREENSHOT_SAVED=%s" % String(result.get("save_path", "")))
	else:
		screenshot_failed.emit(result)
		push_warning("Screenshot save failed: %s" % String(result.get("error", "unknown error")))

func save_viewport_screenshot(viewport: Viewport, prefix: String = "capture", output_dir: String = SCREENSHOT_DIR) -> Dictionary:
	if viewport == null:
		return {
			"ok": false,
			"error": "Viewport is not available."
		}
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	if image == null or image.is_empty():
		return {
			"ok": false,
			"error": "Viewport image is empty."
		}
	var file_info := _build_screenshot_file_info(prefix, output_dir)
	if not bool(file_info.get("ok", false)):
		return file_info
	var save_path := String(file_info.get("save_path", ""))
	var err := image.save_png(save_path)
	if err != OK:
		return {
			"ok": false,
			"error": "save_png failed with code %d." % err,
			"save_path": save_path,
			"file_name": String(file_info.get("file_name", ""))
		}
	return {
		"ok": true,
		"save_path": save_path,
		"file_name": String(file_info.get("file_name", "")),
		"output_dir": String(file_info.get("output_dir", ""))
	}

func _build_screenshot_file_info(prefix: String, output_dir: String) -> Dictionary:
	var effective_prefix := prefix.validate_filename().strip_edges()
	if effective_prefix == "":
		effective_prefix = "capture"
	var absolute_output_dir := _resolve_output_dir(output_dir)
	if absolute_output_dir == "":
		return {
			"ok": false,
			"error": "Output directory is empty."
		}
	var dir_err := _ensure_absolute_dir(absolute_output_dir)
	if dir_err != OK:
		return {
			"ok": false,
			"error": "Could not create output directory (%d)." % dir_err,
			"output_dir": absolute_output_dir
		}
	var file_name := "%s_%s.png" % [effective_prefix, _get_screenshot_timestamp()]
	return {
		"ok": true,
		"save_path": absolute_output_dir.path_join(file_name),
		"file_name": file_name,
		"output_dir": absolute_output_dir
	}

func _resolve_output_dir(output_dir: String) -> String:
	var trimmed := output_dir.strip_edges()
	if trimmed == "":
		trimmed = SCREENSHOT_DIR
	if trimmed.begins_with("user://") or trimmed.begins_with("res://"):
		return ProjectSettings.globalize_path(trimmed)
	return trimmed

func _ensure_absolute_dir(abs_dir: String) -> int:
	if DirAccess.dir_exists_absolute(abs_dir):
		return OK
	return DirAccess.make_dir_recursive_absolute(abs_dir)

func _get_default_screenshot_prefix() -> String:
	var current_scene := get_tree().current_scene
	if current_scene:
		var scene_name := String(current_scene.name).validate_filename().strip_edges()
		if scene_name != "":
			return scene_name
	return "capture"

func _get_screenshot_timestamp() -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d_%02d-%02d-%02d" % [
		int(dt.get("year", 0)),
		int(dt.get("month", 0)),
		int(dt.get("day", 0)),
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0)),
		int(dt.get("second", 0))
	]

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		current_params["height"] = config.get_value("Player", "height", current_params["height"])
		current_params["ratio"] = config.get_value("Player", "ratio", current_params["ratio"])
		current_params["legRatio"] = config.get_value("Player", "legRatio", current_params["legRatio"])
		current_params["sex"] = config.get_value("Player", "sex", current_params["sex"])
		age = config.get_value("Player", "age", age)
		term = config.get_value("Player", "term", term)
		growth_factor = config.get_value("Player", "growth_factor", growth_factor)
		growth_type = config.get_value("Player", "growth_type", growth_type)
		self_confidence = int(config.get_value("Player", "self_confidence", self_confidence))
		self_complex = int(config.get_value("Player", "self_complex", self_complex))
		stress = int(config.get_value("Player", "stress", stress))
		pending_term_choice = bool(config.get_value("Player", "pending_term_choice", pending_term_choice))
		current_term_plan = String(config.get_value("Player", "current_term_plan", current_term_plan))
		if current_term_plan == "":
			current_term_plan = DEFAULT_TERM_PLAN
		var hotspot_value: Variant = config.get_value("Player", "term_hotspot_flags", term_hotspot_flags)
		term_hotspot_flags = hotspot_value if hotspot_value is Dictionary else {}
		term_memory_note = String(config.get_value("Player", "term_memory_note", term_memory_note))
		for key in current_appearance.keys():
			current_appearance[key] = config.get_value("Appearance", key, current_appearance[key])
		for key in system_settings.keys():
			system_settings[key] = config.get_value("System", key, system_settings[key])

func save_settings():
	var config = ConfigFile.new()
	config.set_value("Player", "height", current_params["height"])
	config.set_value("Player", "ratio", current_params["ratio"])
	config.set_value("Player", "legRatio", current_params["legRatio"])
	config.set_value("Player", "sex", current_params["sex"])
	config.set_value("Player", "age", age)
	config.set_value("Player", "term", term)
	config.set_value("Player", "growth_factor", growth_factor)
	config.set_value("Player", "growth_type", growth_type)
	config.set_value("Player", "self_confidence", self_confidence)
	config.set_value("Player", "self_complex", self_complex)
	config.set_value("Player", "stress", stress)
	config.set_value("Player", "pending_term_choice", pending_term_choice)
	config.set_value("Player", "current_term_plan", current_term_plan)
	config.set_value("Player", "term_hotspot_flags", term_hotspot_flags)
	config.set_value("Player", "term_memory_note", term_memory_note)
	for key in current_appearance.keys():
		config.set_value("Appearance", key, current_appearance[key])
	for key in system_settings.keys():
		config.set_value("System", key, system_settings[key])
	config.save(SAVE_PATH)

func save_slot(slot: int) -> void:
	var config = ConfigFile.new()
	config.load(SLOTS_PATH) # 既存スロットを保持したまま上書き
	var section = "slot_%d" % slot
	config.set_value(section, "saved", true)
	config.set_value(section, "height", current_params["height"])
	config.set_value(section, "ratio", current_params["ratio"])
	config.set_value(section, "legRatio", current_params["legRatio"])
	config.set_value(section, "sex", current_params["sex"])
	config.set_value(section, "stage_id", current_stage_id)
	config.set_value(section, "age", age)
	config.set_value(section, "term", term)
	config.set_value(section, "prev_height", prev_height)
	config.set_value(section, "growth_factor", growth_factor)
	config.set_value(section, "growth_type", growth_type)
	config.set_value(section, "growth_history", growth_history)
	config.set_value(section, "self_confidence", self_confidence)
	config.set_value(section, "self_complex", self_complex)
	config.set_value(section, "stress", stress)
	config.set_value(section, "pending_term_choice", pending_term_choice)
	config.set_value(section, "current_term_plan", current_term_plan)
	config.set_value(section, "term_hotspot_flags", term_hotspot_flags)
	config.set_value(section, "term_memory_note", term_memory_note)
	config.set_value(section, "timestamp", Time.get_datetime_string_from_system())
	for key in current_appearance.keys():
		config.set_value(section, "appearance_" + key, current_appearance[key])
	config.save(SLOTS_PATH)
	current_slot = slot

func load_slot(slot: int) -> bool:
	var config = ConfigFile.new()
	if config.load(SLOTS_PATH) != OK:
		return false
	var section = "slot_%d" % slot
	if not config.get_value(section, "saved", false):
		return false
	current_params["height"] = config.get_value(section, "height", 180.0)
	current_params["ratio"] = config.get_value(section, "ratio", 7.5)
	current_params["legRatio"] = config.get_value(section, "legRatio", 48.0)
	current_params["sex"] = config.get_value(section, "sex", "female")
	current_stage_id = config.get_value(section, "stage_id", "room")
	age = config.get_value(section, "age", 6)
	term = config.get_value(section, "term", 6)
	prev_height = config.get_value(section, "prev_height", 0.0)
	growth_factor = config.get_value(section, "growth_factor", 1.0)
	growth_type = config.get_value(section, "growth_type", "normal")
	growth_history = config.get_value(section, "growth_history", [])
	self_confidence = int(config.get_value(section, "self_confidence", 0))
	self_complex = int(config.get_value(section, "self_complex", 0))
	stress = int(config.get_value(section, "stress", 0))
	pending_term_choice = bool(config.get_value(section, "pending_term_choice", false))
	current_term_plan = String(config.get_value(section, "current_term_plan", DEFAULT_TERM_PLAN))
	if current_term_plan == "":
		current_term_plan = DEFAULT_TERM_PLAN
	var hotspot_slot_value: Variant = config.get_value(section, "term_hotspot_flags", {})
	term_hotspot_flags = hotspot_slot_value if hotspot_slot_value is Dictionary else {}
	term_memory_note = String(config.get_value(section, "term_memory_note", ""))
	# 旧セーブデータのマイグレーション（age=0 or term=0 の不整合を修正）
	if age <= 0 or term == 0:
		age = 6
		term = 6
	_ensure_growth_history()
	for key in current_appearance.keys():
		current_appearance[key] = config.get_value(section, "appearance_" + key, current_appearance[key])
	current_slot = slot
	return true

func get_slot_info(slot: int) -> Dictionary:
	var config = ConfigFile.new()
	if config.load(SLOTS_PATH) != OK:
		return {}
	var section = "slot_%d" % slot
	if not config.get_value(section, "saved", false):
		return {}
	return {
		"height": config.get_value(section, "height", 180.0),
		"stage_id": config.get_value(section, "stage_id", "room"),
		"timestamp": config.get_value(section, "timestamp", ""),
		"age": config.get_value(section, "age", 6),
		"term": config.get_value(section, "term", 6),
	}

func get_growth_history_lines(limit: int = 12) -> PackedStringArray:
	_ensure_growth_history()
	var lines := PackedStringArray()
	var start := maxi(0, growth_history.size() - limit)
	for i in range(growth_history.size() - 1, start - 1, -1):
		var entry: Dictionary = growth_history[i]
		var entry_age: int = int(entry.get("age", age))
		var entry_term: int = int(entry.get("term", 0))
		lines.append(
			"%s | %d歳 | %.1fcm | 前回 %+0.1f | 平均差 %+0.1f" % [
				get_school_term_label(entry_age, entry_term),
				entry_age,
				float(entry.get("height", current_params["height"])),
				float(entry.get("diff_prev", 0.0)),
				float(entry.get("diff_avg", 0.0))
			]
		)
	return lines

func get_body_measurements() -> Dictionary:
	var h: float = current_params["height"]
	var ratio: float = current_params["ratio"]
	var leg_ratio: float = current_params["legRatio"]
	var sex: String = current_params["sex"]

	var head: float = h / ratio
	var head_width: float = head * 0.702
	var neck: float = head * 0.220
	var shoulder: float = head * 1.872 if sex == "female" else head * 1.935
	var leg: float = h * leg_ratio / 100.0
	var arm: float = h - leg - head - 2.0 * neck
	var arm_length: float = arm
	var hand: float = (h / ratio) * 0.83

	var landmarks: Dictionary = {
		"top": h,
		"eye": h - head * 0.5,
		"chin": h - head,
		"shoulder": h - head - 2.0 * neck,
		"nipple": h - head - 2.0 * neck - arm * 0.25,
		"navel": h - head - 2.0 * neck - arm * 0.60,
		"hip": h - head - 2.0 * neck - arm * 0.80,
		"crotch": leg,
		"knee": leg * 0.5,
		"foot": 0.0
	}

	return {
		"height": h,
		"head": head,
		"headWidth": head_width,
		"neck": neck,
		"shoulder": shoulder,
		"arm": arm,
		"armLength": arm_length,
		"leg": leg,
		"hand": hand,
		"landmarks": landmarks
	}

func get_custom_body_measurements(params: Dictionary) -> Dictionary:
	var h: float = params.get("height", 180.0)
	var ratio: float = params.get("ratio", 7.5)
	var leg_ratio: float = params.get("legRatio", 48.0)
	var sex: String = params.get("sex", "female")

	var head: float = h / ratio
	var head_width: float = head * 0.702
	var neck: float = head * 0.220
	var shoulder: float = head * 1.872 if sex == "female" else head * 1.935
	var leg: float = h * leg_ratio / 100.0
	var arm: float = h - leg - head - 2.0 * neck
	var arm_length: float = arm
	var hand: float = (h / ratio) * 0.83

	var landmarks: Dictionary = {
		"top": h,
		"eye": h - head * 0.5,
		"chin": h - head,
		"shoulder": h - head - 2.0 * neck,
		"nipple": h - head - 2.0 * neck - arm * 0.25,
		"navel": h - head - 2.0 * neck - arm * 0.60,
		"hip": h - head - 2.0 * neck - arm * 0.80,
		"crotch": leg,
		"knee": leg * 0.5,
		"foot": 0.0
	}

	return {
		"height": h,
		"head": head,
		"headWidth": head_width,
		"neck": neck,
		"shoulder": shoulder,
		"arm": arm,
		"armLength": arm_length,
		"leg": leg,
		"hand": hand,
		"landmarks": landmarks
	}
