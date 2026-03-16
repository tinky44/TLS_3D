extends Node

signal screenshot_saved(result: Dictionary)
signal screenshot_failed(result: Dictionary)

const CM_TO_PX: float = 2.0

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

var current_stage_id: String = "myroom"
var current_slot: int = -1 # 現在使用中のスロット番号 (-1 = 未選択)
var slot_select_mode: String = "save" # "save" or "load"
var _screenshot_in_progress: bool = false

# 成長パラメータ（term=6 が小学1年・6歳のスタート）
var age: int = 6
var term: int = 6
var day_in_term: int = 1
var actions_today: int = 0
var max_actions_per_day: int = 3
var term_total_days: int = 3 # 一学期当たりのアクション回数。これを超えると強制学期進行
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

# ─── 汎用ストーリーフラグ ──────────────────────────────────────────────
var story_flags: Dictionary = {}      # 一度きりのイベント既読管理 (flag_id -> bool)
var story_phases: Dictionary = {}     # 続き物の進行度 (story_id -> int)
var story_term_flags: Dictionary = {} # 今学期だけの一時状態（advance_termでリセット）

# ─── 感情パラメータ ────────────────────────────────────────────
var self_confidence: int = 0 # 自信：高身長を肯定的に受け入れた選択の累積
var self_complex: int = 0 # コンプレックス：高身長を否定的に感じた選択の累積
var stress: int = 0 # 今学期の生活で溜まるしんどさ
var pending_term_choice: bool = false # 進級時の続行/終了選択が必要か
var term_hotspot_flags: Dictionary = {} # 今学期に体験済みのホットスポット
var term_memory_note: String = "" # 今学期の印象的な出来事メモ

# ─── 初期状態・通算ログ ──────────────────────────────────────────
var initial_params: Dictionary = {}      # キャラメイク確定時の体型（エンディング用）
var initial_appearance: Dictionary = {}  # キャラメイク確定時の外見（エンディング用）
var visited_stages: Dictionary = {}      # {stage_id: true} 全プレイを通じて訪れた場所
var experienced_events: Array = []       # 体験済みイベントID一覧

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

func lock_initial_state() -> void:
	initial_params = current_params.duplicate(true)
	initial_appearance = current_appearance.duplicate(true)

func record_stage_visit(stage_id: String) -> void:
	visited_stages[stage_id] = true

func is_first_visit(stage_id: String) -> bool:
	return not visited_stages.has(stage_id)

func record_event(event_id: String) -> void:
	if not event_id in experienced_events:
		experienced_events.append(event_id)

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

func has_pending_event(event_id: String) -> bool:
	return pending_events.has(event_id)

func has_experienced_event(event_id: String) -> bool:
	return experienced_events.has(event_id)

func get_story_phase(story_id: String) -> int:
	return int(story_phases.get(story_id, 0))

func set_story_phase(story_id: String, phase: int) -> void:
	story_phases[story_id] = phase

func has_story_flag(flag_id: String) -> bool:
	return bool(story_flags.get(flag_id, false))

func set_story_flag(flag_id: String, value: bool = true) -> void:
	story_flags[flag_id] = value

func has_story_term_flag(flag_id: String) -> bool:
	return bool(story_term_flags.get(flag_id, false))

func set_story_term_flag(flag_id: String, value: bool = true) -> void:
	story_term_flags[flag_id] = value

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
	day_in_term = 1
	actions_today = 0
	age = term_to_age(term)
	var school_level: int = _school_level_from_age(age)
	current_params["height"] += calc_growth()
	# 夏休み（1学期→2学期）急成長: term>=6 かつ (term-6)%3==1
	if term >= 6 and (term - 6) % 3 == 1:
		current_params["height"] += 10.0
		queue_event("summer_growth")
	# 急成長イベント: 中学〜高校初期（12〜15歳）で確率発生
	# summer_growth と重なった場合も仕様として許容（+14〜18cmになりうる）
	story_term_flags = {}
	if age >= 12 and age <= 15 and get_base_growth(age) >= 3.0 and randf() < 0.40:
		current_params["height"] += randf_range(4.0, 8.0)
		set_story_term_flag("growth_spurt_this_term")
		if not has_story_flag("growth_spurt_seen_first"):
			set_story_flag("growth_spurt_seen_first")
		queue_event("growth_spurt")
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
	# 男子成長自慢: 中学期に初回のみ
	if age >= 12 and age <= 14 and not has_story_flag("middle_boys_growth_talk_done"):
		queue_event("middle_boys_growth_talk")
	# スポーツ勧誘: 高校期 + 十分な身長（185cm超）
	if age >= 15 and not has_story_flag("high_scout_done") and float(current_params["height"]) >= 185.0:
		queue_event("high_scout_contact")
	haruka_invited_this_term = false
	haruka_following = false
	# 学校段階が変わるとき（小4進級・中学・高校・卒業）に選択ダイアログを表示
	pending_term_choice = school_level != prev_school_level and (
		(school_level >= 1 and school_level <= 3) or  # 小4進級 / 中学 / 高校 への進学
		(prev_school_level == 3 and school_level == 4) # 高校卒業
	)
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
		day_in_term = int(config.get_value("Player", "day_in_term", day_in_term))
		actions_today = int(config.get_value("Player", "actions_today", actions_today))
		growth_factor = config.get_value("Player", "growth_factor", growth_factor)
		growth_type = config.get_value("Player", "growth_type", growth_type)
		self_confidence = int(config.get_value("Player", "self_confidence", self_confidence))
		self_complex = int(config.get_value("Player", "self_complex", self_complex))
		stress = int(config.get_value("Player", "stress", stress))
		pending_term_choice = bool(config.get_value("Player", "pending_term_choice", pending_term_choice))
		var hotspot_value: Variant = config.get_value("Player", "term_hotspot_flags", term_hotspot_flags)
		term_hotspot_flags = hotspot_value if hotspot_value is Dictionary else {}
		term_memory_note = String(config.get_value("Player", "term_memory_note", term_memory_note))
		var met_npcs_value: Variant = config.get_value("Player", "met_npcs", met_npcs)
		met_npcs = met_npcs_value if met_npcs_value is Array else []
		haruka_invited_this_term = bool(config.get_value("Player", "haruka_invited_this_term", haruka_invited_this_term))
		haruka_following = bool(config.get_value("Player", "haruka_following", haruka_following))
		senior_gym_invited = bool(config.get_value("Player", "senior_gym_invited", senior_gym_invited))
		vball_story_phase = int(config.get_value("Player", "vball_story_phase", vball_story_phase))
		vball_joined = bool(config.get_value("Player", "vball_joined", vball_joined))
		is_leg_pain = bool(config.get_value("Player", "is_leg_pain", is_leg_pain))
		var pending_events_value: Variant = config.get_value("Player", "pending_events", pending_events)
		pending_events = pending_events_value if pending_events_value is Array else []
		var visited_stages_value: Variant = config.get_value("Player", "visited_stages", visited_stages)
		visited_stages = visited_stages_value if visited_stages_value is Dictionary else {}
		var experienced_events_value: Variant = config.get_value("Player", "experienced_events", experienced_events)
		experienced_events = experienced_events_value if experienced_events_value is Array else []
		var sf: Variant = config.get_value("Player", "story_flags", story_flags)
		story_flags = sf if sf is Dictionary else {}
		var sp: Variant = config.get_value("Player", "story_phases", story_phases)
		story_phases = sp if sp is Dictionary else {}
		var stf: Variant = config.get_value("Player", "story_term_flags", story_term_flags)
		story_term_flags = stf if stf is Dictionary else {}
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
	config.set_value("Player", "day_in_term", day_in_term)
	config.set_value("Player", "actions_today", actions_today)
	config.set_value("Player", "growth_factor", growth_factor)
	config.set_value("Player", "growth_type", growth_type)
	config.set_value("Player", "self_confidence", self_confidence)
	config.set_value("Player", "self_complex", self_complex)
	config.set_value("Player", "stress", stress)
	config.set_value("Player", "pending_term_choice", pending_term_choice)
	config.set_value("Player", "term_hotspot_flags", term_hotspot_flags)
	config.set_value("Player", "term_memory_note", term_memory_note)
	config.set_value("Player", "met_npcs", met_npcs.duplicate())
	config.set_value("Player", "haruka_invited_this_term", haruka_invited_this_term)
	config.set_value("Player", "haruka_following", haruka_following)
	config.set_value("Player", "senior_gym_invited", senior_gym_invited)
	config.set_value("Player", "vball_story_phase", vball_story_phase)
	config.set_value("Player", "vball_joined", vball_joined)
	config.set_value("Player", "is_leg_pain", is_leg_pain)
	config.set_value("Player", "pending_events", pending_events.duplicate())
	config.set_value("Player", "visited_stages", visited_stages.duplicate(true))
	config.set_value("Player", "experienced_events", experienced_events.duplicate())
	config.set_value("Player", "story_flags", story_flags.duplicate(true))
	config.set_value("Player", "story_phases", story_phases.duplicate(true))
	config.set_value("Player", "story_term_flags", story_term_flags.duplicate(true))
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
	config.set_value(section, "day_in_term", day_in_term)
	config.set_value(section, "actions_today", actions_today)
	config.set_value(section, "prev_height", prev_height)
	config.set_value(section, "growth_factor", growth_factor)
	config.set_value(section, "growth_type", growth_type)
	config.set_value(section, "growth_history", growth_history)
	config.set_value(section, "self_confidence", self_confidence)
	config.set_value(section, "self_complex", self_complex)
	config.set_value(section, "stress", stress)
	config.set_value(section, "pending_term_choice", pending_term_choice)
	config.set_value(section, "term_hotspot_flags", term_hotspot_flags)
	config.set_value(section, "term_memory_note", term_memory_note)
	config.set_value(section, "met_npcs", met_npcs.duplicate())
	config.set_value(section, "haruka_invited_this_term", haruka_invited_this_term)
	config.set_value(section, "haruka_following", haruka_following)
	config.set_value(section, "senior_gym_invited", senior_gym_invited)
	config.set_value(section, "vball_story_phase", vball_story_phase)
	config.set_value(section, "vball_joined", vball_joined)
	config.set_value(section, "is_leg_pain", is_leg_pain)
	config.set_value(section, "pending_events", pending_events.duplicate())
	config.set_value(section, "story_flags", story_flags.duplicate(true))
	config.set_value(section, "story_phases", story_phases.duplicate(true))
	config.set_value(section, "story_term_flags", story_term_flags.duplicate(true))
	config.set_value(section, "timestamp", Time.get_datetime_string_from_system())
	for key in current_appearance.keys():
		config.set_value(section, "appearance_" + key, current_appearance[key])
	config.set_value(section, "initial_height", initial_params.get("height", 0.0))
	config.set_value(section, "initial_ratio", initial_params.get("ratio", 7.5))
	config.set_value(section, "initial_legRatio", initial_params.get("legRatio", 48.0))
	config.set_value(section, "initial_sex", initial_params.get("sex", "female"))
	for key in current_appearance.keys():
		config.set_value(section, "initial_appearance_" + key, initial_appearance.get(key, current_appearance[key]))
	config.set_value(section, "visited_stages", visited_stages)
	config.set_value(section, "experienced_events", experienced_events)
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
	current_stage_id = config.get_value(section, "stage_id", "myroom")
	age = config.get_value(section, "age", 6)
	term = config.get_value(section, "term", 6)
	day_in_term = int(config.get_value(section, "day_in_term", 1))
	actions_today = int(config.get_value(section, "actions_today", 0))
	prev_height = config.get_value(section, "prev_height", 0.0)
	growth_factor = config.get_value(section, "growth_factor", 1.0)
	growth_type = config.get_value(section, "growth_type", "normal")
	growth_history = config.get_value(section, "growth_history", [])
	self_confidence = int(config.get_value(section, "self_confidence", 0))
	self_complex = int(config.get_value(section, "self_complex", 0))
	stress = int(config.get_value(section, "stress", 0))
	pending_term_choice = bool(config.get_value(section, "pending_term_choice", false))
	var hotspot_slot_value: Variant = config.get_value(section, "term_hotspot_flags", {})
	term_hotspot_flags = hotspot_slot_value if hotspot_slot_value is Dictionary else {}
	term_memory_note = String(config.get_value(section, "term_memory_note", ""))
	var met_npcs_value: Variant = config.get_value(section, "met_npcs", [])
	met_npcs = met_npcs_value if met_npcs_value is Array else []
	haruka_invited_this_term = bool(config.get_value(section, "haruka_invited_this_term", false))
	haruka_following = bool(config.get_value(section, "haruka_following", false))
	senior_gym_invited = bool(config.get_value(section, "senior_gym_invited", false))
	vball_story_phase = int(config.get_value(section, "vball_story_phase", 0))
	vball_joined = bool(config.get_value(section, "vball_joined", false))
	is_leg_pain = bool(config.get_value(section, "is_leg_pain", false))
	var pending_events_value: Variant = config.get_value(section, "pending_events", [])
	pending_events = pending_events_value if pending_events_value is Array else []
	# 旧セーブデータのマイグレーション（age=0 or term=0 の不整合を修正）
	if age <= 0 or term == 0:
		age = 6
		term = 6
	_ensure_growth_history()
	for key in current_appearance.keys():
		current_appearance[key] = config.get_value(section, "appearance_" + key, current_appearance[key])
	if config.has_section_key(section, "initial_height"):
		initial_params = {
			"height": config.get_value(section, "initial_height", 0.0),
			"ratio":  config.get_value(section, "initial_ratio", 7.5),
			"legRatio": config.get_value(section, "initial_legRatio", 48.0),
			"sex":    config.get_value(section, "initial_sex", "female"),
		}
		for key in current_appearance.keys():
			initial_appearance[key] = config.get_value(section, "initial_appearance_" + key, current_appearance[key])
	var vs = config.get_value(section, "visited_stages", {})
	visited_stages = vs if vs is Dictionary else {}
	var ev = config.get_value(section, "experienced_events", [])
	experienced_events = ev if ev is Array else []
	var sf: Variant = config.get_value(section, "story_flags", {})
	story_flags = sf if sf is Dictionary else {}
	var sp: Variant = config.get_value(section, "story_phases", {})
	story_phases = sp if sp is Dictionary else {}
	var stf: Variant = config.get_value(section, "story_term_flags", {})
	story_term_flags = stf if stf is Dictionary else {}
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
		"stage_id": config.get_value(section, "stage_id", "myroom"),
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
