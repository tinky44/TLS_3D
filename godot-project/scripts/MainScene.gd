extends Node2D

# const STAGES = ["room", "train", "outdoor", "school"]
var p: float = 2.0

@onready var player: Node = $Player

# UI用
var ui_layer: CanvasLayer
var sidebar: PanelContainer # Qキーでトグル表示するステータスサイドバー
var status_label: Label
var bubble_panel: PanelContainer
var bubble_label: Label
var daily_guide_panel: PanelContainer
var daily_guide_label: Label

var minimap_bg: ColorRect
var minimap_player: ColorRect
var action_label: Label
var stage_title_label: Label

# ポーズメニュー用
var pause_menu: Control
var pause_save_label: Label
var pause_fast_travel_panel: VBoxContainer

# ステージ遷移用
var _nearby_transition_door: String = ""
var _nearby_height_scale: bool = false
var _nearby_npc: Node = null # Eキーで話しかけられる近くのNPC
var _nearby_term_hotspot: String = ""
var _nearby_obs_id: String = ""
var _nearby_standup: bool = false
var _nearby_bed: bool = false

# アクションヒントパネル（Q キーで切り替え）
var action_hint_panel: PanelContainer
var action_hint_label: Label

# 測定結果パネル
var measurement_panel: Control
var measurement_content_scroll: ScrollContainer
var measurement_content_label: Label
var _measurement_returns_to_myroom: bool = false
var history_panel: Control
var history_header_label: Label
var growth_graph: Control
var bump_alert_label: Label
var achievement_popup: Control
var achievement_viewer: Control
var _ach_name_label: Label
var _ach_popup_panel: PanelContainer
var _ach_popup_queue: Array = []
var _ach_popup_showing: bool = false
var _bump_alert_time_left: float = 0.0
var mood_feedback_label: Label
var _mood_feedback_time_left: float = 0.0

# ─── ダイアログシステム ──────────────────────────────────────────
var dialogue_panel: Control
var dialogue_name_label: Label
var dialogue_text_label: Label
var dialogue_hint_label: Label
var choice_container: VBoxContainer
var _in_dialogue: bool = false
var _choice_pending: bool = false
var _dialogue_lines: Array = []
var _dialogue_index: int = 0
var _current_dialogue_npc: String = ""
var _current_dialogue_key: String = ""
var _dialogue_restore_pose: String = ""
var _sit_front_nodes: Array = []  # 着席中に前面表示した obs ノードのリスト
var _choice_buttons: Array = []
var _choice_selected_index: int = -1
const DialogueDatabase = preload("res://scripts/DialogueDatabase.gd")
var _dialogues: Dictionary = DialogueDatabase.DATA

# ─── 進級選択 ──────────────────────────────────────────────────
var term_choice_panel: Control
var term_choice_header_label: Label
var _term_choice_showing: bool = false
var _ending_overlay_showing: bool = false
var _school_day_transition_running: bool = false
var sleep_menu: Control
var sleep_menu_options: VBoxContainer
var _sleep_menu_showing: bool = false
var _sleep_menu_current_options: Array[String] = []
var _edge_transition_running: bool = false
var _last_soft_limit_notice_key: String = ""

const GRADE_CHOICE_ORDER = ["continue", "ending"]
const GRADE_CHOICES: Dictionary = {
	"continue": {
		"title": "1. 続ける",
		"summary": "新しい学年で、このまま物語を続ける。"
	},
	"ending": {
		"title": "2. エンディングへ",
		"summary": "ここで物語を区切り、仮エンディングのあとタイトルへ戻る。"
	},
}

const FAST_TRAVEL_STAGES: Array[Dictionary] = [
	{"id": "myroom", "label": "自室"},
	{"id": "room", "label": "部屋（リビング）"},
	{"id": "outdoor", "label": "屋外（街）"},
	{"id": "school_hallway", "label": "学校（廊下）"},
	{"id": "station", "label": "駅"},
	{"id": "train", "label": "電車"},
	{"id": "adjacent_town", "label": "隣町"},
	{"id": "gakuenmachi", "label": "学園街"},
]

const TERM_HOTSPOT_ORDER = [
	"home_mirror",
	"home_table",
	"school_seat",
	"school_infirmary",
	"station_bench",
	"station_vending",
	"gymnasium_basket",
	"randoseru_farewell",
	"schoolyard_tease",
	"bookshelf_interact",
]
const TERM_HOTSPOTS: Dictionary = {
	"home_mirror": {
		"stage_id": "room",
		"obs_id": "washstand",
		"prompt": "鏡を見る",
		"dialogue_npc": "player",
		"dialogue_key": "term_home_mirror",
		"stress_delta": -4,
		"feedback": "鏡の前で呼吸が少し整う",
		"memory_note": "洗面台の鏡の前で、自分の背丈を静かに見つめた。"
	},
	"home_table": {
		"stage_id": "room",
		"obs_ids": ["chair_left", "chair_right", "table"],
		"trigger_obs_ids": ["chair_left", "chair_right"],
		"prompt": "食卓で一息つく",
		"dialogue_npc": "player",
		"dialogue_key": "term_home_table",
		"pose": "chair_sit",
		"seat_height_cm": 45.0,
		"desk_height_cm": 72.0,
		"repeatable": true
	},
	"school_seat": {
		"stage_id": "school",
		"obs_ids": ["desk_1", "student_chair_1", "desk_2", "student_chair_2"],
		"prompt": "自分の席に座る",
		"dialogue_npc": "player",
		"dialogue_key": "term_school_seat",
		"pose": "chair_sit",
		"sit_dir": -1,
		"stress_delta": 2,
		"feedback": "席に座ると少しだけ視線を意識する",
		"memory_note": "教室の自分の席に座り、視線の中で過ごす実感が残った。",
		"repeatable": true
	},
	"school_infirmary": {
		"stage_id": "infirmary",
		"obs_id": "infirmary_bed",
		"prompt": "保健室で相談する",
		"dialogue_npc": "player",
		"dialogue_key": "term_school_infirmary",
		"pose": "taiiku_suwari"
	},
	"station_bench": {
		"stage_id": "station",
		"obs_id": "station_bench",
		"prompt": "ベンチで一息つく",
		"dialogue_npc": "player",
		"dialogue_key": "term_station_bench",
		"pose": "chair_sit",
		"stress_delta": -4,
		"feedback": "人波から少し距離を取れた",
		"memory_note": "駅のベンチで一息つき、人の流れを少し離れて眺めた。",
		"seat_height_cm": 45.0,
		"repeatable": true
	},
	"station_vending": {
		"stage_id": "station",
		"obs_id": "station_vending",
		"prompt": "自販機の前で立ち止まる",
		"dialogue_npc": "player",
		"dialogue_key": "term_station_vending",
		"pose": "reach_low",
		"stress_delta": 3,
		"feedback": "立ち止まると視線が集まりやすい",
		"memory_note": "駅の自販機の前で、立ち止まるだけでも目立つと感じた。",
		"repeatable": true
	},
	"gymnasium_basket": {
		"stage_id": "gymnasium",
		"obs_id": "basketball_board",
		"prompt": "バスケゴールに手を伸ばす",
		"dialogue_npc": "player",
		"dialogue_key": "gymnasium_basket_reach",
		"pose": "reach_up",
		"height_min": 185.0,
		"stress_delta": -5,
		"feedback": "手を上げた瞬間、体の伸びやかさに少し気持ちがほぐれた。",
		"memory_note": "バスケゴールに手を伸ばしたら、いつもより高さが近く感じられた。",
		"repeatable": true
	},
	"randoseru_farewell": {
		"stage_id": "myroom",
		"obs_id": "randoseru",
		"prompt": "ランドセルを見る",
		"dialogue_npc": "player",
		"dialogue_key": "randoseru_farewell",
		"age_min": 11,
		"story_flag_done": "randoseru_farewell_done",
		"memory_note": "引き出しの中のランドセルを取り出し、しばらく眺めた。"
	},
	"schoolyard_tease": {
		"stage_id": "schoolyard",
		"obs_id": "jungle_gym",
		"prompt": "遊具の近くへ行く",
		"dialogue_npc": "player",
		"dialogue_key": "elem_tease",
		"age_max": 11,
		"stress_delta": 2,
		"feedback": "視線を感じる場所では少し気を張ってしまう",
		"memory_note": "校庭の遊具の近くで、男子に声をかけられた。"
	},
	"bookshelf_interact": {
		"stage_id": "myroom",
		"obs_id": "bookshelf",
		"prompt": "本棚を調べる",
		"repeatable": true,
		"custom_action": "open_achievements",
	},
}

const STRESS_PREFIX_KEYS: Array[String] = ["default", "tall", "huge", "check"]
const NPC_STRESS_OPENERS: Dictionary = {
	"haruka": {
		"low": {"speaker": "はるか", "text": "今日は少し顔つきがやわらかいね。"},
		"mid": {"speaker": "はるか", "text": "無理してない？ ちょっと肩に力が入ってる。"},
		"high": {"speaker": "はるか", "text": "かなりしんどそう。少し端で話そっか。"},
	},
	"mother": {
		"low": {"speaker": "母", "text": "今日は少し楽そうな顔をしてるね。"},
		"mid": {"speaker": "母", "text": "背中、少し丸くなってるわよ。無理してない？"},
		"high": {"speaker": "母", "text": "顔がこわばってる。今日は休めるところで休みなさい。"},
	},
	"father": {
		"low": {"speaker": "父", "text": "今日はいつもより落ち着いて見えるな。"},
		"mid": {"speaker": "父", "text": "少し疲れてるか。気を張りすぎるなよ。"},
		"high": {"speaker": "父", "text": "かなり参ってる顔だ。ひとりで抱え込むなよ。"},
	},
	"nurse": {
		"low": {"speaker": "保健の先生", "text": "今日は呼吸が落ち着いてるね。"},
		"mid": {"speaker": "保健の先生", "text": "少し張ってるね。話すだけでも楽になるよ。"},
		"high": {"speaker": "保健の先生", "text": "かなりしんどそう。まずは座って、息を整えよう。"},
	},
	"senior": {
		"low": {"speaker": "バレー部先輩", "text": "今日は動けそうな顔してるじゃん。"},
		"mid": {"speaker": "バレー部先輩", "text": "視線が気になる日か。呼吸だけでも合わせてみる？"},
		"high": {"speaker": "バレー部先輩", "text": "かなり張ってるね。無理する前に言ってよ。"},
	},
	"generic": {
		"low": {"speaker": "通りすがり", "text": "背が高いね。なんだか今日は堂々として見える。"},
		"mid": {"speaker": "通りすがり", "text": "大丈夫？ ちょっと疲れて見えるけど。"},
		"high": {"speaker": "通りすがり", "text": "平気？ 顔色、あまりよくないみたい。"},
	},
}
const STRESS_IDLE_MONOLOGUES: Dictionary = {
	"home": {
		"low": "家の中では、ちょっと気が楽だ。",
		"mid": "家ではゆっくりしたい。外みたいに背筋を張らなくていい。",
		"high": "今日は疲れた。少し横になりたい。",
	},
	"school": {
		"low": "今日は授業に集中できそう。",
		"mid": "教室に入る前に、少し深呼吸しよう。",
		"high": "しんどい。はるかか保健室に声をかけよう。",
	},
	"station": {
		"low": "混んでるけど、まあ大丈夫。",
		"mid": "視線が気になる。人の波を少し外れたい。",
		"high": "人が多くて疲れてきた。ベンチで休もう。",
	},
	"default": {
		"low": "今日はわりと落ち着いてる。",
		"mid": "少し気持ちが揺れてる。ゆっくり行こう。",
		"high": "気持ちが張りつめてる。少し休まないと。",
	},
}

func _ready() -> void:
	# 既存のテスト用古いノード群があれば削除
	if has_node("Floor"): get_node("Floor").queue_free()
	if has_node("ObstacleHigh"): get_node("ObstacleHigh").queue_free()
	if has_node("ObstacleLow"): get_node("ObstacleLow").queue_free()
	
	# Globalスケール取得
	var global = get_node_or_null("/root/Global")
	if global:
		p = global.CM_TO_PX
		var saved_handler := Callable(self, "_on_screenshot_saved")
		if not global.is_connected("screenshot_saved", saved_handler):
			global.connect("screenshot_saved", saved_handler)
		var failed_handler := Callable(self, "_on_screenshot_failed")
		if not global.is_connected("screenshot_failed", failed_handler):
			global.connect("screenshot_failed", failed_handler)
		
	process_mode = Node.PROCESS_MODE_ALWAYS
	if player:
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		
	_setup_ui()
	_setup_bubble() # bubble_panel を先に追加（下層に描画）
	_setup_dialogue_panel() # ダイアログパネル（bubble_panelの上）
	_setup_pause_menu() # pause_menu を後に追加（最前面に描画）
	_setup_measurement_panel()
	_setup_sleep_menu()
	_setup_term_choice_panel()
	_setup_achievement_popup()
	_load_stage()

func _setup_appearance_debug(vbox: VBoxContainer) -> void:
	var section_label = Label.new()
	section_label.text = "【服装】"
	section_label.add_theme_font_size_override("font_size", 14)
	section_label.add_theme_color_override("font_color", Color("#6c757d"))
	vbox.add_child(section_label)

	# トップス選択（全6種類）
	var tops_row = HBoxContainer.new()
	vbox.add_child(tops_row)
	var tops_label = Label.new()
	tops_label.text = "トップス:"
	tops_label.custom_minimum_size = Vector2(76, 0)
	tops_row.add_child(tops_label)
	var tops_opt = OptionButton.new()
	tops_opt.focus_mode = Control.FOCUS_NONE
	tops_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tops_values = ["sailor", "blazer", "blouse_bow", "jumper_skirt", "sweater", "t_shirt"]
	tops_opt.add_item("セーラー服", 0)
	tops_opt.add_item("ジャンパースカート", 1)
	tops_opt.add_item("リボンブラウス", 2)
	tops_opt.add_item("サスペンダースカート", 3)
	tops_opt.add_item("スウェッター", 4)
	tops_opt.add_item("Tシャツ", 5)
	var cur_tops = tops_values.find(Global.current_appearance.get("tops_type", "t_shirt"))
	tops_opt.selected = max(0, cur_tops)
	tops_opt.item_selected.connect(func(idx: int) -> void:
		_apply_tops_type(tops_values[idx])
	)
	tops_row.add_child(tops_opt)

	# ボトムス選択
	var bottoms_row = HBoxContainer.new()
	vbox.add_child(bottoms_row)
	var bottoms_label = Label.new()
	bottoms_label.text = "ボトムス:"
	bottoms_label.custom_minimum_size = Vector2(76, 0)
	bottoms_row.add_child(bottoms_label)
	var bottoms_opt = OptionButton.new()
	bottoms_opt.focus_mode = Control.FOCUS_NONE
	bottoms_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bottoms_values = ["skirt", "skirt_long", "skirt_sailor", "pants"]
	bottoms_opt.add_item("スカート", 0)
	bottoms_opt.add_item("ロングスカート", 1)
	bottoms_opt.add_item("セーラースカート", 2)
	bottoms_opt.add_item("パンツ", 3)
	var cur_btm = bottoms_values.find(Global.current_appearance.get("bottoms_type", "pants"))
	bottoms_opt.selected = max(0, cur_btm)
	bottoms_opt.item_selected.connect(func(idx: int) -> void:
		Global.current_appearance["bottoms_type"] = bottoms_values[idx]
		var drawer = player.get_node_or_null("CharacterDrawer")
		if drawer: drawer.queue_redraw()
	)
	bottoms_row.add_child(bottoms_opt)

	# 髪型選択
	var hair_row = HBoxContainer.new()
	vbox.add_child(hair_row)
	var hair_label = Label.new()
	hair_label.text = "髪型:"
	hair_label.custom_minimum_size = Vector2(76, 0)
	hair_row.add_child(hair_label)
	var hair_opt = OptionButton.new()
	hair_opt.focus_mode = Control.FOCUS_NONE
	hair_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hair_values = ["short", "long", "ponytail", "side_tail"]
	hair_opt.add_item("ショート", 0)
	hair_opt.add_item("ロング", 1)
	hair_opt.add_item("ポニーテール", 2)
	hair_opt.add_item("サイドテール", 3)
	hair_opt.selected = max(0, hair_values.find(Global.current_appearance.get("hair_style", "short")))
	hair_opt.item_selected.connect(func(idx: int) -> void:
		Global.current_appearance["hair_style"] = hair_values[idx]
		var drawer = player.get_node_or_null("CharacterDrawer")
		if drawer: drawer.queue_redraw()
	)
	hair_row.add_child(hair_opt)

	# 帽子選択
	var hat_row = HBoxContainer.new()
	vbox.add_child(hat_row)
	var hat_label = Label.new()
	hat_label.text = "帽子:"
	hat_label.custom_minimum_size = Vector2(76, 0)
	hat_row.add_child(hat_label)
	var hat_opt = OptionButton.new()
	hat_opt.focus_mode = Control.FOCUS_NONE
	hat_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hat_values = ["none", "school_hat"]
	hat_opt.add_item("なし", 0)
	hat_opt.add_item("学校帽", 1)
	var cur_hat = hat_values.find(Global.current_appearance.get("hat_type", "none"))
	hat_opt.selected = max(0, cur_hat)
	hat_opt.item_selected.connect(func(idx: int) -> void:
		Global.current_appearance["hat_type"] = hat_values[idx]
		var drawer = player.get_node_or_null("CharacterDrawer")
		if drawer: drawer.queue_redraw()
	)
	hat_row.add_child(hat_opt)

	# バッグ選択
	var bag_row = HBoxContainer.new()
	vbox.add_child(bag_row)
	var bag_label = Label.new()
	bag_label.text = "バッグ:"
	bag_label.custom_minimum_size = Vector2(76, 0)
	bag_row.add_child(bag_label)
	var bag_opt = OptionButton.new()
	bag_opt.focus_mode = Control.FOCUS_NONE
	bag_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bag_values = ["none", "randoseru"]
	bag_opt.add_item("なし", 0)
	bag_opt.add_item("ランドセル", 1)
	var cur_bag = bag_values.find(Global.current_appearance.get("bag_type", "none"))
	bag_opt.selected = max(0, cur_bag)
	bag_opt.item_selected.connect(func(idx: int) -> void:
		Global.current_appearance["bag_type"] = bag_values[idx]
		var drawer = player.get_node_or_null("CharacterDrawer")
		if drawer: drawer.queue_redraw()
	)
	bag_row.add_child(bag_opt)

	# ヒント
	var hint_lbl = Label.new()
	hint_lbl.text = "[Q] 服装パネルを開閉"
	hint_lbl.add_theme_font_size_override("font_size", 12)
	hint_lbl.add_theme_color_override("font_color", Color("#888"))
	vbox.add_child(hint_lbl)

func _setup_bubble():
	bubble_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.5)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.2, 0.2, 0.5)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	bubble_panel.add_theme_stylebox_override("panel", style)
	
	bubble_label = Label.new()
	bubble_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	bubble_label.add_theme_font_size_override("font_size", 14)
	# 改行対応
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.custom_minimum_size = Vector2(200, 0)
	
	bubble_panel.add_child(bubble_label)
	# CanvasLayer (ui_layer) に追加することで、2DのZ順に影響されず常に最前面に描画
	ui_layer.add_child(bubble_panel)
	bubble_panel.hide()

func _setup_dialogue_panel() -> void:
	dialogue_panel = Control.new()
	dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.custom_minimum_size = Vector2(0, 160)
	dialogue_panel.offset_top = -160
	dialogue_panel.offset_bottom = 0
	dialogue_panel.hide()
	dialogue_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.18, 0.5)
	bg.border_color = Color("#e8c872")
	bg.border_width_top = 2
	bg.content_margin_left = 24
	bg.content_margin_right = 24
	bg.content_margin_top = 16
	bg.content_margin_bottom = 16

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", bg)
	dialogue_panel.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	dialogue_name_label = Label.new()
	dialogue_name_label.add_theme_font_size_override("font_size", 16)
	dialogue_name_label.add_theme_color_override("font_color", Color("#e8c872"))
	vbox.add_child(dialogue_name_label)

	dialogue_text_label = Label.new()
	dialogue_text_label.add_theme_font_size_override("font_size", 20)
	dialogue_text_label.add_theme_color_override("font_color", Color.WHITE)
	dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(dialogue_text_label)

	# 選択肢コンテナ
	choice_container = VBoxContainer.new()
	choice_container.add_theme_constant_override("separation", 6)
	choice_container.hide()
	vbox.add_child(choice_container)

	dialogue_hint_label = Label.new()
	dialogue_hint_label.text = "Eキーで次へ"
	dialogue_hint_label.add_theme_font_size_override("font_size", 13)
	dialogue_hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	dialogue_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(dialogue_hint_label)

	ui_layer.add_child(dialogue_panel)

func _setup_term_choice_panel() -> void:
	term_choice_panel = ColorRect.new()
	term_choice_panel.color = Color(0, 0, 0, 0.72)
	term_choice_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	term_choice_panel.hide()
	term_choice_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	term_choice_panel.add_child(center)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#16202c")
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "進級の節目"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	term_choice_header_label = Label.new()
	term_choice_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	term_choice_header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	term_choice_header_label.custom_minimum_size = Vector2(580, 0)
	term_choice_header_label.add_theme_font_size_override("font_size", 17)
	term_choice_header_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.94))
	vbox.add_child(term_choice_header_label)

	for choice_id: String in GRADE_CHOICE_ORDER:
		var choice: Dictionary = GRADE_CHOICES[choice_id]
		var btn = Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(580, 74)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "%s\n%s" % [
			String(choice.get("title", choice_id)),
			String(choice.get("summary", ""))
		]
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_grade_choice_selected.bind(choice_id))
		vbox.add_child(btn)

	var hint = Label.new()
	hint.text = "[1][2] でも選択できます"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.72, 0.79, 0.86))
	vbox.add_child(hint)

	ui_layer.add_child(term_choice_panel)

func _show_term_choice_panel() -> void:
	if _term_choice_showing:
		return
	var global = get_node_or_null("/root/Global")
	if not global or not global.pending_term_choice:
		return
	_term_choice_showing = true
	term_choice_header_label.text = "%s\n%d歳 / %s\n%s" % [
		_get_grade_transition_title(int(global.age)),
		int(global.age),
		Global.get_school_term_label(int(global.age), int(global.term)),
		_get_grade_transition_summary(int(global.age))
	]
	term_choice_panel.show()
	get_tree().paused = true

func _hide_term_choice_panel() -> void:
	_term_choice_showing = false
	term_choice_panel.hide()
	get_tree().paused = false

func _resolve_stage_id(stage_id: String) -> String:
	var global = get_node_or_null("/root/Global")
	var age_value: int = int(global.age) if global else 0
	return StageBuilder.resolve_stage_id(stage_id, age_value)

func _get_stage_uniform_age(stage_id: String) -> int:
	var global = get_node_or_null("/root/Global")
	var fallback_age: int = int(global.age) if global else 6
	if stage_id.ends_with("_elementary"):
		return 10
	if stage_id.ends_with("_middle"):
		return 13
	if stage_id.ends_with("_high"):
		return 16
	return fallback_age

func _get_shoe_color_for_type(shoes_type: String) -> String:
	match shoes_type:
		"uwabaki":
			return "#f7f7f2"
		"loafer":
			return "#4b4b52"
		"socks":
			return "#f5f4fb"
		_:
			return "#f0f0f0"

func _build_stage_shoe_overrides(stage_id: String) -> Dictionary:
	var shoes_type: String = Global.get_shoes_for_stage(stage_id)
	return {
		"shoes_type": shoes_type,
		"shoes_color": _get_shoe_color_for_type(shoes_type),
	}

func _build_stage_uniform_appearance(stage_id: String, hair_style: String, hair_color: String) -> Dictionary:
	var appearance: Dictionary = Global.get_school_uniform(_get_stage_uniform_age(stage_id)).duplicate(true)
	var shoe_overrides: Dictionary = _build_stage_shoe_overrides(stage_id)
	appearance["hair_style"] = hair_style
	appearance["hair_color"] = hair_color
	for key in shoe_overrides.keys():
		appearance[key] = shoe_overrides[key]
	return appearance

func _sync_player_stage_appearance(stage_id: String) -> void:
	var global = get_node_or_null("/root/Global")
	if not global:
		return
	var shoes_type: String = Global.get_shoes_for_stage(stage_id)
	global.current_appearance["shoes_type"] = shoes_type
	global.current_appearance["shoes_color"] = _get_shoe_color_for_type(shoes_type)
	var drawer = player.get_node_or_null("CharacterDrawer") if player else null
	if drawer:
		drawer.queue_redraw()

func _get_stage_lock_message(stage_id: String) -> String:
	var global = get_node_or_null("/root/Global")
	if not global:
		return ""
	var age_value: int = int(global.age)
	match stage_id:
		"school_hallway_elementary", "school_elementary":
			if age_value > 11:
				return "懐かしいな……。今はもう、このままは入れない。"
		"school_hallway_middle":
			if age_value < 12:
				return "まだこの廊下に入る時期じゃない。"
			if age_value > 14:
				return "今はもう、この廊下には入れない。"
		"school_middle":
			if age_value < 12:
				return "まだこの教室に入る時期じゃない。"
			if age_value > 14:
				return "今はもう、この教室じゃない。"
		"infirmary_middle":
			if age_value < 12:
				return "まだこの保健室に入る時期じゃない。"
			if age_value > 14:
				return "今はもう、この保健室には入れない。"
		"gymnasium_middle":
			if age_value < 12:
				return "まだこの体育館に入る時期じゃない。"
			if age_value > 14:
				return "今はもう、この体育館には入れない。"
		"schoolyard_middle":
			if age_value < 12:
				return "まだここには入れない。"
			if age_value > 14:
				return "今はもう、この校庭には入れない。"
		"school_high":
			if age_value < 15:
				return "まだこの教室に入るには早い。"
		"school_hallway_high":
			if age_value < 15:
				return "まだこの通学路に向かう時期じゃない。"
	return ""

func _get_transition_lock_message(door_id: String) -> String:
	if not door_id.begins_with("door_to_"):
		return ""
	var destination: String = door_id.substr("door_to_".length())
	return _get_stage_lock_message(destination)

func _on_grade_choice_selected(choice_id: String) -> void:
	var global = get_node_or_null("/root/Global")
	if not global:
		return
	if not GRADE_CHOICES.has(choice_id):
		return

	global.pending_term_choice = false
	_hide_term_choice_panel()
	global.save_settings()

	if choice_id == "continue":
		return

	get_tree().change_scene_to_file("res://scenes/EndingScene.tscn")

func _get_grade_transition_title(age_value: int) -> String:
	match age_value:
		9:
			return "小学4年生になりました"
		12:
			return "中学生になりました"
		15:
			return "高校生になりました"
		_:
			return "新しい学年になりました"

func _get_grade_transition_summary(age_value: int) -> String:
	if age_value == 12 or age_value == 15:
		return "制服も通う場所も変わる節目です。ここから先の物語を続けるか選んでください。"
	if age_value == 9:
		return "学校生活の景色が少しずつ変わっていきます。ここで物語を区切ることもできます。"
	return "ここから先の物語を続けるか、いったん区切るか選んでください。"

func _show_temp_ending_and_return_to_title() -> void:
	_ending_overlay_showing = true
	get_tree().paused = true

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 220
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "ここで物語はいったん一区切り"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	vbox.add_child(title)

	var body = Label.new()
	body.text = "エンディング本編は後日実装予定です。\n今回は仮エンディングとして、タイトルへ戻ります。"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(520, 0)
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92))
	vbox.add_child(body)

	var tw = overlay.create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.35)
	await tw.finished
	await get_tree().create_timer(1.35, true).timeout
	_ending_overlay_showing = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")

func _is_term_intro_dialogue() -> bool:
	if _current_dialogue_npc != "player":
		return false
	return _current_dialogue_key in [
		"new_semester",
		"entrance_elementary",
		"entrance_middle",
		"entrance_high",
		"summer_growth",
		"summer_growth_vball"
	]

func _get_stress_state_text(stress_value: int) -> String:
	if stress_value >= 75:
		return "かなり張りつめている"
	if stress_value >= 45:
		return "少ししんどい"
	if stress_value >= 20:
		return "やや緊張している"
	return "落ち着いている"

func _get_stress_band(stress_value: int) -> String:
	if stress_value >= 70:
		return "high"
	if stress_value >= 35:
		return "mid"
	return "low"

func _build_dialogue_sequence(npc_id: String, key: String) -> Array:
	var npc_data: Dictionary = _dialogues.get(npc_id, {})
	var base_lines: Array = npc_data.get(key, []).duplicate(true)
	if base_lines.is_empty():
		return []
	if npc_id == "player":
		return base_lines
	if not STRESS_PREFIX_KEYS.has(key):
		return base_lines
	# 初対面（first_meet相当）のキーには感情openerを追加しない
	if key == "first_meet":
		return base_lines
	# Globalで面識なしのNPCには感情openerを追加しない
	var global = get_node_or_null("/root/Global")
	if global and npc_id != "" and npc_id != "generic":
		if not global.met_npcs.has(npc_id):
			return base_lines
	var opener: Dictionary = _get_stress_dialogue_opener(npc_id)
	if opener.is_empty():
		return base_lines
	var merged_lines: Array = [opener]
	merged_lines.append_array(base_lines)
	return merged_lines

func _get_stress_dialogue_opener(npc_id: String) -> Dictionary:
	var global = get_node_or_null("/root/Global")
	if not global:
		return {}
	var band: String = _get_stress_band(int(global.stress))
	var opener_set: Dictionary = NPC_STRESS_OPENERS.get(npc_id, NPC_STRESS_OPENERS.get("generic", {}))
	var opener: Variant = opener_set.get(band, {})
	return opener.duplicate(true) if opener is Dictionary else {}

func _get_stage_mood_bucket(stage_id: String) -> String:
	if stage_id == "room" or stage_id == "myroom":
		return "home"
	if stage_id in ["station", "platform", "train", "outdoor", "adjacent_town", "gakuenmae", "gakuenmachi"]:
		return "station"
	if StageBuilder.is_school_stage(stage_id):
		return "school"
	return "default"

func _get_idle_monologue_text(global: Node) -> String:
	if not global:
		return ""
	var stage_bucket: String = _get_stage_mood_bucket(String(global.current_stage_id))
	var monologue_set: Dictionary = STRESS_IDLE_MONOLOGUES.get(stage_bucket, STRESS_IDLE_MONOLOGUES.get("default", {}))
	return String(monologue_set.get(_get_stress_band(int(global.stress)), ""))

func _get_default_action_hint_text() -> String:
	var global = get_node_or_null("/root/Global")
	if not global:
		return "[Q] 設定  [G] 記録  [E] 調べる"
	var band: String = _get_stress_band(int(global.stress))
	var stage_bucket: String = _get_stage_mood_bucket(String(global.current_stage_id))
	var vball_phase: int = Global.vball_story_phase
	if stage_bucket == "school":
		if vball_phase == 0 and Global.senior_gym_invited:
			return "体育館で先輩に話しかけてみよう"
		if vball_phase == 1:
			return "先輩に返事をしに行こう"
		if vball_phase == 2:
			return "バレー部と教室、どちらも気にしてみよう"
		if vball_phase == 3 and Global.is_leg_pain:
			return "脚のことを誰かに相談してみよう"
	match stage_bucket:
		"home":
			if band == "high":
				return "少し休める場所を探そう  [E] 調べる  [G] 記録"
			if band == "mid":
				return "家の中で落ち着ける場所を見てみよう  [E] 調べる  [G] 記録"
			return "家で一息つけそうな物を調べよう  [E] 調べる  [G] 記録"
		"school":
			if band == "high":
				return "しんどさを抱えすぎる前に誰かと話してみよう  [E] 話す"
			if band == "mid":
				return "席や保健室で少し気持ちを整えよう  [E] 話す  [G] 記録"
			return "教室や保健室で出来ることを探そう  [E] 話す  [G] 記録"
		"station":
			if band == "high":
				return "人の少ない場所でひと息つこう  [E] 調べる"
			if band == "mid":
				return "ベンチや自販機で気分を切り替えよう  [E] 調べる"
			return "近くで出来る小さな行動を探そう  [E] 調べる"
	if band == "high":
		return "無理をしすぎる前に、落ち着ける場所を探そう"
	if band == "mid":
		return "少し気分転換してみよう  [Q] 設定  [G] 記録"
	return "[Q] 設定  [G] 記録  [E] 調べる"

func _get_term_reflection_text(global: Node) -> String:
	var stage_bucket: String = _get_stage_mood_bucket(String(global.current_stage_id))
	var balance: int = int(global.self_confidence) - int(global.self_complex)
	match stage_bucket:
		"home":
			if balance >= 0:
				return "家でゆっくりできたから、次の学期も何とかなりそう。"
			return "家にいてもなんとなく落ち着けなかった。次は早めに休みたい。"
		"school":
			if balance >= 0:
				return "色々あったけど、以前よりは学校に慣れてきた気がする。"
			return "学校はまだしんどい。でも来学期も行くしかない。"
		"station":
			if balance >= 0:
				return "人の多い場所も、だんだんやり過ごせるようになってきた。"
			return "視線が気になるのはいつも通りだった。ベンチで一息つけただけよかった。"
	return "今学期も色々あった。来学期はもう少し楽になるといいな。"

func _get_term_hotspot_id_for_obstacle(obs_id: String) -> String:
	var global = get_node_or_null("/root/Global")
	if not global:
		return ""
	for hotspot_id in TERM_HOTSPOT_ORDER:
		var hotspot_data: Dictionary = TERM_HOTSPOTS[hotspot_id]
		if _resolve_stage_id(String(hotspot_data.get("stage_id", ""))) != String(global.current_stage_id):
			continue
		var height_min: float = float(hotspot_data.get("height_min", 0.0))
		if height_min > 0.0 and float(global.current_params.get("height", 0.0)) < height_min:
			continue
		var age_min: int = int(hotspot_data.get("age_min", 0))
		var age_max: int = int(hotspot_data.get("age_max", 9999))
		var cur_age: int = int(global.age)
		if age_min > 0 and cur_age < age_min:
			continue
		if age_max < 9999 and cur_age > age_max:
			continue
		var story_flag_done: String = String(hotspot_data.get("story_flag_done", ""))
		if story_flag_done != "" and global.has_story_flag(story_flag_done):
			continue
		var matched: bool = false
		# trigger_obs_ids が指定されている場合はそちらを優先（obs_ids は前面描画用途も兼ねるため）
		var trigger_ids: Variant = hotspot_data.get("trigger_obs_ids", null)
		var hotspot_obs_ids: Variant = hotspot_data.get("obs_ids", null)
		var check_ids: Variant = trigger_ids if trigger_ids is Array else hotspot_obs_ids
		if check_ids is Array:
			for candidate in check_ids:
				if String(candidate) == obs_id:
					matched = true
					break
		elif String(hotspot_data.get("obs_id", "")) == obs_id:
			matched = true
		if not matched:
			continue
		if global.has_term_hotspot_done(hotspot_id):
			# repeatable なホットスポットはセリフ済みでもインタラクト可能
			if not bool(hotspot_data.get("repeatable", false)):
				return ""
		return hotspot_id
	return ""

func _get_term_hotspot_prompt(hotspot_id: String) -> String:
	if not TERM_HOTSPOTS.has(hotspot_id):
		return ""
	return String(TERM_HOTSPOTS[hotspot_id].get("prompt", "調べる"))

func _trigger_term_hotspot(hotspot_id: String) -> void:
	var global = get_node_or_null("/root/Global")
	if not global or not TERM_HOTSPOTS.has(hotspot_id):
		return
	var hotspot_data: Dictionary = TERM_HOTSPOTS[hotspot_id]
	var height_min: float = float(hotspot_data.get("height_min", 0.0))
	if height_min > 0.0 and float(global.current_params.get("height", 0.0)) < height_min:
		return
	# repeatable なホットスポットは「初回かどうか」を記録してからマーク
	var already_done: bool = global.has_term_hotspot_done(hotspot_id)
	global.mark_term_hotspot_done(hotspot_id)
	# ストーリー系副作用（フラグ・ストレス・記憶）は初回のみ
	if not already_done:
		var story_flag_done: String = String(hotspot_data.get("story_flag_done", ""))
		if story_flag_done != "" and global.has_method("set_story_flag"):
			global.set_story_flag(story_flag_done)
		var stress_delta: int = int(hotspot_data.get("stress_delta", 0))
		if stress_delta != 0:
			global.add_stress(stress_delta)
			_show_stress_feedback(stress_delta, String(hotspot_data.get("feedback", "")))
		var memory_note: String = String(hotspot_data.get("memory_note", ""))
		if memory_note != "":
			global.append_term_memory_note(memory_note)
	var pose_name: String = String(hotspot_data.get("pose", ""))
	if pose_name != "" and player:
		_dialogue_restore_pose = String(player.pose)
		# chair_sit の場合は座面・机の高さを sit_context にセット、机を前面表示
		if pose_name == "chair_sit" and player.get("sit_context") != null:
			var seat_h: float = float(hotspot_data.get("seat_height_cm", -1.0))
			var desk_h: float = float(hotspot_data.get("desk_height_cm", -1.0))
			var hotspot_obs_ids: Array = []
			var oi = hotspot_data.get("obs_ids", null)
			if oi is Array:
				hotspot_obs_ids = oi
			else:
				var single = String(hotspot_data.get("obs_id", ""))
				if single != "":
					hotspot_obs_ids = [single]
			_sit_front_nodes.clear()
			for child in get_children():
				if not child.has_meta("obs_id"):
					continue
				var o_id: String = String(child.get_meta("obs_id"))
				if not (o_id in hotspot_obs_ids):
					continue
				var oh: float = float(child.get_meta("obs_height_cm", 0.0))
				if ("chair" in o_id or "bench" in o_id or "seat" in o_id) and seat_h < 0.0:
					seat_h = oh
				elif "desk" in o_id or "table" in o_id:
					if desk_h < 0.0:
						desk_h = oh
					# 机を前面に描画
					child.z_index = 1
					_sit_front_nodes.append(child)
			player.sit_context = {"seat_h_cm": seat_h, "desk_h_cm": desk_h}
		# 向きの設定: obs_id から判定 → fallback として hotspot の sit_dir を使用
		var sit_dir_val: int = int(hotspot_data.get("sit_dir", 0))
		if _nearby_obs_id == "chair_right":
			player.dir = -1  # 右椅子 → 左向き
		elif _nearby_obs_id == "chair_left":
			player.dir = 1   # 左椅子 → 右向き
		elif sit_dir_val != 0:
			player.dir = sit_dir_val
		# 背もたれにキャラクターの背中を合わせるためX位置を補正
		# chair_left/right: _nearby_obs_id から直接、その他: hotspot obs_ids の中から最近接 chair を探す
		var chair_node_target: Node = null
		var chair_obs_id_for_pos: String = ""
		if "chair_left" in _nearby_obs_id or "chair_right" in _nearby_obs_id:
			chair_obs_id_for_pos = _nearby_obs_id
			for obs_child in get_children():
				if obs_child.has_meta("obs_id") and String(obs_child.get_meta("obs_id")) == _nearby_obs_id:
					chair_node_target = obs_child
					break
		elif pose_name == "chair_sit":
			# hotspot の全 obs_ids から "chair" を含む最近接ノードを探す
			var all_obs_v = hotspot_data.get("obs_ids", null)
			var all_obs_arr: Array = []
			if all_obs_v is Array:
				all_obs_arr = all_obs_v
			elif hotspot_data.has("obs_id"):
				all_obs_arr = [String(hotspot_data.get("obs_id", ""))]
			var min_chair_dist: float = INF
			for obs_child in get_children():
				if not obs_child.has_meta("obs_id"):
					continue
				var oc_id: String = String(obs_child.get_meta("obs_id"))
				if "chair" not in oc_id:
					continue
				if not (oc_id in all_obs_arr):
					continue
				var chair_cx: float = (float(obs_child.get_meta("obs_x")) + float(obs_child.get_meta("obs_x2"))) / 2.0 * player.CM_TO_PX
				var dist: float = absf(player.position.x - chair_cx)
				if dist < min_chair_dist:
					min_chair_dist = dist
					chair_obs_id_for_pos = oc_id
					chair_node_target = obs_child
		if chair_node_target != null:
			var obs_x_cm := float(chair_node_target.get_meta("obs_x"))
			var obs_x2_cm := float(chair_node_target.get_meta("obs_x2"))
			var c2p: float = player.CM_TO_PX
			var m_dict: Dictionary = player.m
			var head_val: float
			if m_dict.has("headWidth"):
				head_val = float(m_dict["headWidth"])
			else:
				head_val = float(m_dict.get("head", 22.0)) * 0.702
			var half_t: float = head_val * c2p * 0.85 / 2.0
			if "chair_left" in chair_obs_id_for_pos:
				# dir=1: 背面 = player.x - half_t → 背もたれ右面に合わせる
				player.position.x = obs_x_cm * c2p + 8.0 + half_t
			else:
				# dir=-1 (flip): 背面 = player.x + half_t → 背もたれ左面に合わせる
				player.position.x = obs_x2_cm * c2p - 8.0 - half_t
		if player.has_method("set_pose_immediately"):
			player.call("set_pose_immediately", pose_name)
		else:
			player.pose = pose_name
			var drawer := player.get_node_or_null("CharacterDrawer")
			if drawer:
				drawer.queue_redraw()
	global.save_settings()
	_nearby_term_hotspot = ""
	# カスタムアクション（ダイアログを使わない特殊処理）
	var custom_action: String = String(hotspot_data.get("custom_action", ""))
	if custom_action == "open_achievements":
		if not global.has_story_flag("bookshelf_checked"):
			global.set_story_flag("bookshelf_checked")
		_open_achievement_viewer()
		return
	# セリフは初回のみ（repeatable なホットスポットの2回目以降はスキップ）
	if not already_done:
		_start_dialogue(
			String(hotspot_data.get("dialogue_npc", "player")),
			String(hotspot_data.get("dialogue_key", "default"))
		)
	elif pose_name != "" and pose_name != "chair_sit":
		# ダイアログなしで pose を適用した場合、0.8秒後に自動復帰してフリーズを防ぐ
		var _saved_pose := _dialogue_restore_pose
		_dialogue_restore_pose = ""
		get_tree().create_timer(0.8, true).timeout.connect(func():
			if player and is_instance_valid(player) and String(player.pose) == pose_name:
				if player.has_method("set_pose_immediately"):
					player.call("set_pose_immediately", _saved_pose if _saved_pose != "" else "normal")
				else:
					player.pose = _saved_pose if _saved_pose != "" else "normal"
		)

func _do_standup() -> void:
	if not player:
		return
	var restore_pose: String = _dialogue_restore_pose if _dialogue_restore_pose != "" else "normal"
	if player.has_method("set_pose_immediately"):
		player.call("set_pose_immediately", restore_pose)
	else:
		player.pose = restore_pose
		var drawer := player.get_node_or_null("CharacterDrawer")
		if drawer:
			drawer.queue_redraw()
	if player.get("sit_context") != null:
		player.sit_context = {"seat_h_cm": -1.0, "desk_h_cm": -1.0}
	for n in _sit_front_nodes:
		if is_instance_valid(n):
			n.z_index = -1
	_sit_front_nodes.clear()
	_dialogue_restore_pose = ""
	_nearby_standup = false

func _start_dialogue(npc_id: String, key: String = "default") -> void:
	if _in_dialogue or _measurement_showing or _term_choice_showing:
		return
	if not _dialogues.has(npc_id):
		return
	var npc_data: Dictionary = _dialogues[npc_id]
	if not npc_data.has(key):
		return

	var global = get_node_or_null("/root/Global")
	if global:
		global.record_event(npc_id + "_" + key)
	_current_dialogue_npc = npc_id
	_current_dialogue_key = key
	_dialogue_lines = _build_dialogue_sequence(npc_id, key)
	_dialogue_index = 0
	_in_dialogue = true
	get_tree().paused = true
	dialogue_panel.show()
	_show_dialogue_line()

func _show_dialogue_line() -> void:
	if _dialogue_index >= _dialogue_lines.size():
		_end_dialogue()
		return
	var line: Dictionary = _dialogue_lines[_dialogue_index]
	dialogue_name_label.text = line.get("speaker", "")
	dialogue_text_label.text = line.get("text", "")
	if line.has("choices"):
		_show_choices(line["choices"])
	else:
		_clear_choice_buttons()
		choice_container.hide()
		_choice_pending = false
		dialogue_hint_label.text = "Eキーで次へ"
		dialogue_hint_label.show()

func _show_choices(choices: Array) -> void:
	_choice_pending = true
	dialogue_hint_label.text = "↑↓で選択  Eキーで決定"
	dialogue_hint_label.show()
	_clear_choice_buttons()
	for child in choice_container.get_children():
		child.queue_free()
	var choice_style = StyleBoxFlat.new()
	choice_style.bg_color = Color("#2a2a44")
	choice_style.border_color = Color("#e8c872")
	choice_style.border_width_bottom = 1
	choice_style.content_margin_left = 12
	choice_style.content_margin_right = 12
	choice_style.content_margin_top = 6
	choice_style.content_margin_bottom = 6
	var hover_style = choice_style.duplicate()
	hover_style.bg_color = Color("#3a3a60")
	for c in choices:
		var btn = Button.new()
		btn.text = c.get("label", "")
		btn.focus_mode = Control.FOCUS_ALL
		btn.add_theme_font_size_override("font_size", 17)
		btn.add_theme_stylebox_override("normal", choice_style.duplicate())
		btn.add_theme_stylebox_override("hover", hover_style.duplicate())
		btn.add_theme_stylebox_override("focus", hover_style.duplicate())
		btn.add_theme_stylebox_override("pressed", hover_style.duplicate())
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.mouse_entered.connect(_on_choice_button_hovered.bind(_choice_buttons.size()))
		btn.focus_entered.connect(_on_choice_button_focused.bind(_choice_buttons.size()))
		btn.connect("pressed", _on_choice_selected.bind(c))
		_choice_buttons.append(btn)
		choice_container.add_child(btn)
	choice_container.show()
	_set_choice_selection(0)

func _clear_choice_buttons() -> void:
	_choice_buttons.clear()
	_choice_selected_index = -1

func _set_choice_selection(index: int) -> void:
	if _choice_buttons.is_empty():
		_choice_selected_index = -1
		return
	_choice_selected_index = wrapi(index, 0, _choice_buttons.size())
	var btn: Button = _choice_buttons[_choice_selected_index]
	if is_instance_valid(btn):
		btn.grab_focus()

func _move_choice_selection(delta: int) -> void:
	if _choice_buttons.is_empty():
		return
	var base_index := _choice_selected_index if _choice_selected_index >= 0 else 0
	_set_choice_selection(base_index + delta)

func _activate_selected_choice() -> void:
	if _choice_buttons.is_empty():
		return
	if _choice_selected_index < 0:
		_set_choice_selection(0)
	var btn: Button = _choice_buttons[_choice_selected_index]
	if is_instance_valid(btn):
		btn.emit_signal("pressed")

func _on_choice_button_hovered(index: int) -> void:
	_set_choice_selection(index)

func _on_choice_button_focused(index: int) -> void:
	_choice_selected_index = index

func _on_choice_selected(choice: Dictionary) -> void:
	_choice_pending = false
	_clear_choice_buttons()
	choice_container.hide()
	dialogue_hint_label.text = "Eキーで次へ"
	dialogue_hint_label.show()
	# 感情パラメータ更新
	var emotion: String = choice.get("emotion", "")
	var global = get_node_or_null("/root/Global")
	if global and emotion != "":
		if emotion == "confidence":
			global.self_confidence += 1
		elif emotion == "complex":
			global.self_complex += 1
	# アクション処理（バレー部ストーリーなど）
	var action: String = choice.get("action", "")
	if global and action != "":
		_process_choice_action(action, global)
	if global:
		global.save_settings()
	# 分岐先へ
	var next_key: String = choice.get("next", "")
	if next_key != "":
		var npc_data: Dictionary = _dialogues.get(_current_dialogue_npc, {})
		if npc_data.has(next_key):
			_dialogue_lines = npc_data[next_key]
			_dialogue_index = 0
			_show_dialogue_line()
			return
	_advance_dialogue()

func _process_choice_action(action: String, global: Node) -> void:
	var action_parts: PackedStringArray = action.split(",", false)
	for part in action_parts:
		var action_id: String = String(part).strip_edges()
		if action_id == "":
			continue
		if action_id.begins_with("stress:"):
			var delta_text: String = action_id.substr("stress:".length())
			if delta_text.is_valid_int():
				var stress_delta: int = int(delta_text)
				global.add_stress(stress_delta)
				_show_stress_feedback(stress_delta)
			continue
		if action_id.begins_with("note:"):
			global.append_term_memory_note(action_id.substr("note:".length()))
			continue
		match action_id:
			"vball_join":
				global.vball_joined = true
				global.vball_story_phase = 2
			"vball_pain_report":
				global.vball_story_phase = 4
				global.queue_event("vball_tell_senior")
			"vball_rejoin":
				global.vball_joined = true
				global.is_leg_pain = false
				global.vball_story_phase = 7
			"vball_manager_role":
				global.vball_joined = false
				global.is_leg_pain = false
				global.vball_story_phase = 7
			"high_scout_interest":
				global.set_story_phase("high_scout", 1)

func _advance_dialogue() -> void:
	if _choice_pending: return
	_dialogue_index += 1
	_show_dialogue_line()

func _end_dialogue() -> void:
	var should_show_term_choice := false
	var global = get_node_or_null("/root/Global")
	if global and global.pending_term_choice and _is_term_intro_dialogue():
		should_show_term_choice = true

	_in_dialogue = false
	_choice_pending = false
	_clear_choice_buttons()
	choice_container.hide()
	dialogue_hint_label.text = "Eキーで次へ"
	dialogue_hint_label.show()
	get_tree().paused = false
	dialogue_panel.hide()
	if player and _dialogue_restore_pose != "":
		if player.has_method("set_pose_immediately"):
			player.call("set_pose_immediately", _dialogue_restore_pose)
		else:
			player.pose = _dialogue_restore_pose
			var drawer := player.get_node_or_null("CharacterDrawer")
			if drawer:
				drawer.queue_redraw()
		if _dialogue_restore_pose != "chair_sit" and player.get("sit_context") != null:
			player.sit_context = {"seat_h_cm": -1.0, "desk_h_cm": -1.0}
		_dialogue_restore_pose = ""
	# 前面表示していた机ノードを元の z_index に戻す
	for n in _sit_front_nodes:
		if is_instance_valid(n):
			n.z_index = -1
	_sit_front_nodes.clear()

	if _current_dialogue_npc == "haruka" and _current_dialogue_key == "measure_invite":
		if global:
			global.haruka_following = true
		for child in get_children():
			if child.has_meta("is_npc") and child.get("npc_id") == "haruka":
				child.follow_target = player
				break
	elif _current_dialogue_npc == "senior" and _current_dialogue_key == "first_meet":
		if global and global.vball_story_phase == 0:
			global.vball_story_phase = 1
	elif _current_dialogue_npc == "senior" and _current_dialogue_key == "practice_first":
		if global and global.vball_joined:
			global.is_leg_pain = true
			global.vball_story_phase = 3
	elif _current_dialogue_npc == "senior" and _current_dialogue_key == "pain_concern":
		if global:
			global.is_leg_pain = false
			global.vball_joined = false
			global.vball_story_phase = 5
	elif _current_dialogue_npc == "teacher" and _current_dialogue_key == "semester_start":
		if global and StageBuilder.is_school_classroom_stage(String(global.current_stage_id)):
			call_deferred("_start_dialogue", "player", "term_school")
	elif _should_run_school_day_transition(global):
		call_deferred("_run_school_day_transition")

	if global:
		global._check_all_achievements()
	if should_show_term_choice:
		call_deferred("_show_term_choice_panel")

func _should_run_school_day_transition(global: Node) -> bool:
	if _school_day_transition_running:
		return false
	if _current_dialogue_npc != "player" or _current_dialogue_key != "term_school":
		return false
	if global == null:
		return false
	return StageBuilder.is_school_classroom_stage(String(global.current_stage_id))

func _run_school_day_transition() -> void:
	var global = get_node_or_null("/root/Global")
	if not _should_run_school_day_transition(global):
		return

	_school_day_transition_running = true
	_nearby_npc = null
	_nearby_term_hotspot = ""
	_nearby_transition_door = ""
	_nearby_height_scale = false
	get_tree().paused = true

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var text_label := Label.new()
	text_label.text = "放課後になった。"
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_font_size_override("font_size", 34)
	text_label.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	text_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.95))
	text_label.add_theme_constant_override("outline_size", 6)
	text_label.modulate.a = 0.0
	center.add_child(text_label)

	ui_layer.add_child(overlay)

	var intro_tween := create_tween()
	intro_tween.tween_property(overlay, "color:a", 0.82, 0.5)
	intro_tween.parallel().tween_property(text_label, "modulate:a", 1.0, 0.2)
	intro_tween.tween_interval(0.9)
	intro_tween.tween_property(text_label, "modulate:a", 0.0, 0.2)
	await intro_tween.finished

	# 放課後はイベント開始前の位置にとどまる（ステージ変更なし）

	text_label.text = "帰り道のことを考える。"
	var outro_tween := create_tween()
	outro_tween.tween_property(text_label, "modulate:a", 1.0, 0.2)
	outro_tween.tween_interval(0.9)
	outro_tween.parallel().tween_property(text_label, "modulate:a", 0.0, 0.25)
	outro_tween.parallel().tween_property(overlay, "color:a", 0.0, 0.45)
	await outro_tween.finished

	overlay.queue_free()
	get_tree().paused = false
	_school_day_transition_running = false

func _get_bubble_screen_pos() -> Vector2:
	var cam = player.get_node_or_null("Camera2D")
	var screen_pos: Vector2
	if cam:
		screen_pos = player.global_position - cam.get_screen_center_position() + get_viewport().get_visible_rect().size / 2.0
	else:
		screen_pos = player.global_position
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var bubble_size: Vector2 = bubble_panel.get_combined_minimum_size()
	bubble_size.x = maxf(bubble_size.x, bubble_panel.size.x)
	bubble_size.y = maxf(bubble_size.y, bubble_panel.size.y)
	var head_offset_y: float = -float(player.get("visual_height_cm")) * p
	if player.has_method("get_head_screen_y_offset"):
		head_offset_y = float(player.call("get_head_screen_y_offset"))
	var bubble_gap_y: float = bubble_size.y + 20.0
	var screen_margin: float = 12.0
	var min_x: float = viewport_rect.position.x + screen_margin
	var max_x: float = viewport_rect.position.x + viewport_rect.size.x - bubble_size.x - screen_margin
	var min_y: float = viewport_rect.position.y + screen_margin
	var max_y: float = viewport_rect.position.y + viewport_rect.size.y - bubble_size.y - screen_margin
	var bubble_pos: Vector2 = screen_pos + Vector2(-bubble_size.x / 2.0, head_offset_y - bubble_gap_y)
	if bubble_pos.y < min_y:
		var player_m: Dictionary = player.get("m") if player.get("m") != null else {}
		var body_half_w: float = 48.0
		if not player_m.is_empty():
			var shoulder_half_w: float = float(player_m.get("shoulder", 35.0)) * p * 0.5
			var head_half_w: float = float(player_m.get("headWidth", 24.0)) * p * 0.7
			body_half_w = maxf(body_half_w, maxf(shoulder_half_w, head_half_w))
		var side_gap_x: float = 24.0
		var right_x: float = screen_pos.x + body_half_w + side_gap_x
		var left_x: float = screen_pos.x - body_half_w - side_gap_x - bubble_size.x
		var free_right: float = (viewport_rect.position.x + viewport_rect.size.x - screen_margin) - right_x
		var free_left: float = (screen_pos.x - body_half_w - side_gap_x) - (viewport_rect.position.x + screen_margin)
		var side_y: float = screen_pos.y + head_offset_y - bubble_size.y * 0.5
		if free_right >= bubble_size.x or free_right >= free_left:
			bubble_pos = Vector2(right_x, side_y)
		else:
			bubble_pos = Vector2(left_x, side_y)
	bubble_pos.x = clampf(bubble_pos.x, min_x, max_x)
	bubble_pos.y = clampf(bubble_pos.y, min_y, max_y)
	return bubble_pos

func _get_nearby_named_npc(dist_px: float) -> Node:
	if not player: return null
	for child in get_children():
		if child.has_meta("is_npc"):
			var d = abs(child.global_position.x - player.global_position.x)
			if d <= dist_px:
				return child
	return null

func _interact_with_npc(npc: Node) -> void:
	if not npc or not player: return
	# フレーム間でNPCが離れた場合の保護
	if abs(npc.global_position.x - player.global_position.x) > 200.0: return
	
	var npc_id: String = npc.get("npc_id") if npc.get("npc_id") != null else ""
	var is_generic = false
	if npc_id == "":
		npc_id = "generic"
		is_generic = true

	# 身長差に応じてセリフキーを選択
	var player_m = player.get("m")
	var npc_m = npc.get("m")
	var key = "default"
	if player_m and npc_m:
		var npc_data: Dictionary = _dialogues.get(npc_id, _dialogues.get("generic", {}))
		var diff = float(player_m["height"]) - float(npc_m["height"])
		var global = get_node_or_null("/root/Global")
		var vball_phase = global.vball_story_phase if global else 0
		
		# 初対面判定 (Globalのメタデータを使って記憶を維持)
		var unique_npc_key = npc_id
		var has_met = false
		if is_generic:
			has_met = false # 名無しNPCは常に初対面扱い
		elif global:
			has_met = global.met_npcs.has(unique_npc_key)
		else:
			has_met = npc.get_meta("met_player", false)

		if is_generic:
			if diff >= 35.0:
				key = "huge"
			elif diff >= 15.0:
				key = "tall"
			else:
				key = "default"
		elif npc_data.has("first_meet") and not has_met:
			key = "first_meet"
			if global:
				global.met_npcs.append(unique_npc_key)
			else:
				npc.set_meta("met_player", true)
		elif npc_id == "senior":
			# バレー部ストーリーフェーズによる分岐
			if vball_phase == 1:
				key = "join_invite"
			elif vball_phase == 2 and global and global.vball_joined:
				key = "practice_first"
			elif vball_phase == 3 and global and global.is_leg_pain:
				key = "pain_concern"
			elif vball_phase == 6:
				key = "senior_after_summer"
			elif diff >= 35.0 and npc_data.has("huge"):
				key = "huge"
		elif npc_id == "haruka":
			if global and StageBuilder.is_school_classroom_stage(String(global.current_stage_id)) and not global.has_term_hotspot_done("school_haruka_support"):
				key = "term_school_haruka_support"
				global.mark_term_hotspot_done("school_haruka_support")
			elif global and global.is_leg_pain and vball_phase == 3:
				key = "vball_pain_consult"
			elif global and not global.haruka_invited_this_term:
				key = "measure_invite"
				global.haruka_invited_this_term = true
			elif diff >= 35.0 and npc_data.has("huge"):
				key = "huge"
			elif diff >= 15.0 and npc_data.has("tall"):
				key = "tall"
		elif diff >= 35.0 and npc_data.has("huge"):
			key = "huge"
		elif diff >= 15.0 and npc_data.has("tall"):
			key = "tall"
		elif (npc_id == "mother" or npc_id == "father") and npc_data.has("check"):
			key = "check"
	_start_dialogue(npc_id, key)

func _setup_bump_alert() -> void:
	bump_alert_label = Label.new()
	bump_alert_label.hide()
	bump_alert_label.add_theme_font_size_override("font_size", 18)
	bump_alert_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.75))
	bump_alert_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	bump_alert_label.add_theme_constant_override("outline_size", 5)
	bump_alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bump_alert_label.size = Vector2(360, 30)
	ui_layer.add_child(bump_alert_label)

func _setup_mood_feedback() -> void:
	mood_feedback_label = Label.new()
	mood_feedback_label.hide()
	mood_feedback_label.anchor_left = 0.5
	mood_feedback_label.anchor_right = 0.5
	mood_feedback_label.offset_left = -260
	mood_feedback_label.offset_right = 260
	mood_feedback_label.offset_top = 36
	mood_feedback_label.offset_bottom = 68
	mood_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mood_feedback_label.add_theme_font_size_override("font_size", 20)
	mood_feedback_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	mood_feedback_label.add_theme_constant_override("outline_size", 6)
	ui_layer.add_child(mood_feedback_label)

func _update_bump_alert(delta: float) -> void:
	if not bump_alert_label:
		return
	if _bump_alert_time_left <= 0.0:
		bump_alert_label.hide()
		return

	_bump_alert_time_left = max(0.0, _bump_alert_time_left - delta)
	if _bump_alert_time_left <= 0.0:
		bump_alert_label.hide()
		return

	if not player:
		return

	var cam = player.get_node_or_null("Camera2D")
	var screen_pos: Vector2
	if cam:
		screen_pos = player.global_position - cam.get_screen_center_position() + get_viewport().get_visible_rect().size / 2.0
	else:
		screen_pos = player.global_position
	bump_alert_label.position = screen_pos + Vector2(-bump_alert_label.size.x / 2.0, -player.visual_height_cm * p - 120.0)
	bump_alert_label.show()

func _update_mood_feedback(delta: float) -> void:
	if not mood_feedback_label:
		return
	if _mood_feedback_time_left <= 0.0:
		mood_feedback_label.hide()
		return
	_mood_feedback_time_left = max(0.0, _mood_feedback_time_left - delta)
	if _mood_feedback_time_left <= 0.0:
		mood_feedback_label.hide()
		return
	mood_feedback_label.show()

func _show_bump_alert(text: String) -> void:
	if not bump_alert_label:
		_setup_bump_alert()
	bump_alert_label.text = text
	_bump_alert_time_left = 0.9
	bump_alert_label.show()

func _show_mood_feedback(text: String, positive: bool) -> void:
	if not mood_feedback_label:
		_setup_mood_feedback()
	mood_feedback_label.text = text
	var font_color: Color = Color(0.95, 0.82, 0.72)
	if positive:
		font_color = Color(0.80, 0.94, 0.82)
	mood_feedback_label.add_theme_color_override("font_color", font_color)
	_mood_feedback_time_left = 1.5
	mood_feedback_label.show()

func _show_stress_feedback(delta: int, detail: String = "") -> void:
	if delta == 0:
		return
	var feedback_text: String = "%+d stress" % delta
	if detail != "":
		feedback_text += "  " + detail
	_show_mood_feedback(feedback_text, delta < 0)

func _on_screenshot_saved(result: Dictionary) -> void:
	var file_name := String(result.get("file_name", "capture.png"))
	_show_mood_feedback("Screenshot saved: %s" % file_name, true)

func _on_screenshot_failed(result: Dictionary) -> void:
	var error_text := String(result.get("error", "unknown error"))
	_show_mood_feedback("Screenshot failed: %s" % error_text, false)


func _process(delta: float) -> void:
	_update_actions_hud()
	_update_ui()
	_update_bubble()
	_update_minimap()
	_update_bump_alert(delta)
	_update_mood_feedback(delta)
	if action_hint_label and action_hint_panel and action_hint_panel.visible:
		action_hint_label.text = _get_action_hint_text()
	_check_edge_transition()

func _check_edge_transition() -> void:
	if _edge_transition_running or not player:
		return
	var global = get_node_or_null("/root/Global")
	if not global:
		return
	var stage_id := String(global.current_stage_id)
	var player_x_cm: float = player.global_position.x / p
	if stage_id == "outdoor":
		var stage_w: float = float(StageBuilder.STAGES["outdoor"]["width"])
		if player_x_cm >= stage_w - 10.0:
			_enter_edge_transition("adjacent_town")
	elif stage_id == "adjacent_town":
		if player_x_cm <= 10.0:
			_enter_edge_transition("outdoor")
	elif stage_id == "station":
		var stage_w: float = float(StageBuilder.STAGES["station"]["width"])
		# station は右端に見えない壁があるため、少し手前で遷移判定する
		if player_x_cm >= stage_w - 150.0:
			_enter_edge_transition("platform")
	elif stage_id == "platform":
		# platform は左端に見えない壁があるため、少し手前で遷移判定する
		if player_x_cm <= 150.0:
			_enter_edge_transition("station")

func _update_minimap():
	if not player or not minimap_bg or not minimap_player: return
	var global = get_node_or_null("/root/Global")
	var stage_id = global.current_stage_id if global else "room"
	var stage_w_cm = 2000.0
	if StageBuilder.STAGES.has(stage_id):
		stage_w_cm = float(StageBuilder.STAGES[stage_id]["width"])
		
	var px_cm = clamp(player.global_position.x / p, 0.0, stage_w_cm)
	var ratio = px_cm / max(1.0, stage_w_cm)
	
	# clamp to keep within the bar visually
	var target_x = ratio * minimap_bg.size.x - minimap_player.size.x * 0.5
	minimap_player.position.x = target_x
	
func _update_bubble():
	if not player or not bubble_panel: return

	var m = player.get("m")
	if not m: return
	if _sleep_menu_showing:
		bubble_panel.hide()
		return

	var px = player.global_position.x / p
	var hit_dist = 60.0 # 60cm以内に近づいたら表示
	var closest_obs: Node2D = null
	var min_dist = INF

	# NPC検知を先に行う（ステージオブジェクトより優先）
	_nearby_npc = _get_nearby_named_npc(150.0)
	if _nearby_npc:
		_nearby_transition_door = ""
		_nearby_height_scale = false
		_nearby_term_hotspot = ""
		_nearby_bed = false
		bubble_label.text = "[Eキー] 話しかける"
		bubble_panel.show()
		bubble_panel.position = _get_bubble_screen_pos()
		return

	for child in get_children():
		if child.has_meta("is_stage_obj") and child.has_meta("obs_x"):
			# AABBチェックのようなもの。
			var ox1 = float(child.get_meta("obs_x"))
			var ox2 = float(child.get_meta("obs_x2"))
			var dist = 0.0
			if px < ox1: dist = ox1 - px
			elif px > ox2: dist = px - ox2

			if dist < hit_dist and dist < min_dist:
				min_dist = dist
				closest_obs = child

	if closest_obs:
		var obs_id = closest_obs.get_meta("obs_id")
		var oh = closest_obs.get_meta("obs_height_cm")
		var h = m["height"]
		var hotspot_id: String = _get_term_hotspot_id_for_obstacle(String(obs_id))

		bubble_label.text = StageBuilder.get_obstacle_comment(obs_id, h, oh)
		var global = get_node_or_null("/root/Global")

		# 近くのオブジェクトに応じたインタラクションヒントを追加
		if obs_id == "bed" and global and String(global.current_stage_id) == "myroom":
			_nearby_transition_door = ""
			_nearby_height_scale = false
			_nearby_term_hotspot = ""
			_nearby_bed = true
			bubble_label.text += "\n[E] 休む"
		elif hotspot_id != "":
			_nearby_transition_door = ""
			_nearby_height_scale = false
			_nearby_bed = false
			_nearby_obs_id = String(obs_id)
			# 着席中かつ chair_sit ホットスポットなら「立ち上がる」に切り替え
			var hotspot_pose: String = String(TERM_HOTSPOTS[hotspot_id].get("pose", ""))
			if player and String(player.pose) == "chair_sit" and hotspot_pose == "chair_sit":
				_nearby_term_hotspot = ""
				_nearby_standup = true
				bubble_label.text += "\n[E] 立ち上がる"
			else:
				_nearby_term_hotspot = hotspot_id
				_nearby_standup = false
				bubble_label.text += "\n[E] %s" % _get_term_hotspot_prompt(hotspot_id)
		elif obs_id.begins_with("door_to_"):
			var lock_message: String = _get_transition_lock_message(String(obs_id))
			_nearby_height_scale = false
			_nearby_term_hotspot = ""
			_nearby_obs_id = ""
			_nearby_standup = false
			_nearby_bed = false
			if lock_message != "":
				_nearby_transition_door = ""
				bubble_label.text = lock_message
			else:
				_nearby_transition_door = obs_id
				bubble_label.text += "\n[Eキーで移動]"
		elif obs_id == "height_scale":
			_nearby_transition_door = ""
			_nearby_height_scale = true
			_nearby_term_hotspot = ""
			_nearby_obs_id = ""
			_nearby_standup = false
			_nearby_bed = false
			bubble_label.text += "\n[Eキー] 身長を測る"
		else:
			_nearby_transition_door = ""
			_nearby_height_scale = false
			_nearby_term_hotspot = ""
			_nearby_obs_id = ""
			_nearby_standup = false
			_nearby_bed = false

		bubble_panel.show()
		bubble_panel.position = _get_bubble_screen_pos()
	else:
		_nearby_transition_door = ""
		_nearby_height_scale = false
		_nearby_term_hotspot = ""
		_nearby_obs_id = ""
		_nearby_standup = false
		_nearby_bed = false
		if _in_dialogue or _measurement_showing or _term_choice_showing or _sleep_menu_showing:
			bubble_panel.hide()
			return
		var global = get_node_or_null("/root/Global")
		var idle_monologue: String = _get_idle_monologue_text(global)
		if idle_monologue == "":
			bubble_panel.hide()
		else:
			bubble_label.text = idle_monologue
			bubble_panel.show()
			bubble_panel.position = _get_bubble_screen_pos()

func _setup_ui():
	ui_layer = CanvasLayer.new()
	
	# サイドバー全体を覆うパネル（クラス変数を使用）
	sidebar = PanelContainer.new()
	sidebar.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	sidebar.custom_minimum_size = Vector2(320, 0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#f8f9fa") # 明るい背景
	style.border_width_right = 2
	style.border_color = Color("#dee2e6")
	sidebar.add_theme_stylebox_override("panel", style)
	
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sidebar.add_child(scroll)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	status_label = Label.new()
	status_label.add_theme_color_override("font_color", Color("#212529"))
	status_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(status_label)

	var speed_label = Label.new()
	speed_label.text = "歩き速度"
	speed_label.add_theme_color_override("font_color", Color("#495057"))
	speed_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(speed_label)
	
	var speed_slider = HSlider.new()
	speed_slider.min_value = 50.0
	speed_slider.max_value = 600.0
	speed_slider.step = 10.0
	speed_slider.value = Global.system_settings.get("move_speed", 250.0)
	
	# 初期値をプレイヤーに適用
	if player and player.has_method("refresh_movement_tuning"):
		player.call("refresh_movement_tuning")

	speed_slider.value_changed.connect(func(v: float):
		Global.system_settings["move_speed"] = v
		if player and player.has_method("refresh_movement_tuning"):
			player.call("refresh_movement_tuning")
	)
	speed_slider.drag_ended.connect(func(_val: bool):
		Global.save_settings()
	)
	vbox.add_child(speed_slider)

	vbox.add_child(HSeparator.new())
	_setup_appearance_debug(vbox)

	sidebar.hide() # 初期状態は非表示。Qキーでトグル
	ui_layer.add_child(sidebar)

	# ─── アクションヒントパネル（画面右下・常時表示）─────────────
	action_hint_panel = PanelContainer.new()
	var ah_style = StyleBoxFlat.new()
	ah_style.bg_color = Color(0, 0, 0, 0.55)
	ah_style.corner_radius_top_left = 8
	ah_style.corner_radius_top_right = 8
	ah_style.corner_radius_bottom_right = 8
	ah_style.corner_radius_bottom_left = 8
	ah_style.content_margin_left = 14
	ah_style.content_margin_right = 14
	ah_style.content_margin_top = 8
	ah_style.content_margin_bottom = 8
	action_hint_panel.add_theme_stylebox_override("panel", ah_style)
	action_hint_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	action_hint_panel.offset_left = -360
	action_hint_panel.offset_top = -64
	action_hint_panel.offset_right = -16
	action_hint_panel.offset_bottom = -16
	action_hint_label = Label.new()
	action_hint_label.add_theme_font_size_override("font_size", 14)
	action_hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	action_hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	action_hint_label.add_theme_constant_override("outline_size", 3)
	action_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_hint_label.custom_minimum_size = Vector2(300, 0)
	action_hint_panel.add_child(action_hint_label)
	ui_layer.add_child(action_hint_panel)

	daily_guide_panel = PanelContainer.new()
	var dg_style = StyleBoxFlat.new()
	dg_style.bg_color = Color(0, 0, 0, 0.50)
	dg_style.corner_radius_top_left = 8
	dg_style.corner_radius_top_right = 8
	dg_style.corner_radius_bottom_right = 8
	dg_style.corner_radius_bottom_left = 8
	dg_style.content_margin_left = 12
	dg_style.content_margin_right = 12
	dg_style.content_margin_top = 6
	dg_style.content_margin_bottom = 6
	daily_guide_panel.add_theme_stylebox_override("panel", dg_style)
	daily_guide_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	daily_guide_panel.offset_left = 16
	daily_guide_panel.offset_top = -58
	daily_guide_panel.offset_right = 420
	daily_guide_panel.offset_bottom = -16
	daily_guide_panel.hide()
	daily_guide_label = Label.new()
	daily_guide_label.add_theme_font_size_override("font_size", 14)
	daily_guide_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.92))
	daily_guide_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.88))
	daily_guide_label.add_theme_constant_override("outline_size", 3)
	daily_guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	daily_guide_panel.add_child(daily_guide_label)
	ui_layer.add_child(daily_guide_panel)

	# 常時表示する「Q: ステータス設定」ヒントラベル
	var hint = Label.new()
	hint.text = "Q: ステータス設定"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 4)
	hint.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hint.position = Vector2(20, 10)
	ui_layer.add_child(hint)

	# ステージ上の自分の位置を示す線（ミニマップ）
	minimap_bg = ColorRect.new()
	minimap_bg.color = Color(0, 0, 0, 0.5)
	minimap_bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	minimap_bg.position = Vector2(20, 32)
	minimap_bg.size = Vector2(200, 4)
	ui_layer.add_child(minimap_bg)
	
	minimap_player = ColorRect.new()
	minimap_player.color = Color(0.2, 0.8, 1.0, 1.0) # 水色
	minimap_player.position = Vector2(0, -2)
	minimap_player.size = Vector2(6, 8)
	minimap_bg.add_child(minimap_player)

	action_label = Label.new()
	action_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	action_label.offset_left = -300
	action_label.offset_top = 16
	action_label.offset_right = -20
	action_label.offset_bottom = 44
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	action_label.add_theme_font_size_override("font_size", 16)
	action_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	action_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	action_label.add_theme_constant_override("outline_size", 4)
	ui_layer.add_child(action_label)

	stage_title_label = Label.new()
	stage_title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	stage_title_label.offset_left = 240
	stage_title_label.offset_top = 10
	stage_title_label.offset_right = -240
	stage_title_label.offset_bottom = 40
	stage_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_title_label.add_theme_font_size_override("font_size", 18)
	stage_title_label.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
	stage_title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.88))
	stage_title_label.add_theme_constant_override("outline_size", 4)
	ui_layer.add_child(stage_title_label)

	add_child(ui_layer)
	# ui_layer は _setup_ui() で add_child 済み。_setup_bubble() / _setup_pause_menu() はその後に呼ぶ

func _setup_pause_menu() -> void:
	pause_menu = ColorRect.new()
	pause_menu.color = Color(0, 0, 0, 0.6) # 半透明黒背景
	pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.hide()
	# ポーズメニュー自体は常に動作するようにする（親がALWAYSなので継承でも可だが念のため）
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(center)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#212529")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 40
	style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 28)
	panel.add_child(hbox)

	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 20)
	left_vbox.custom_minimum_size = Vector2(280, 0)
	hbox.add_child(left_vbox)

	var title = Label.new()
	title.text = "PAUSE MENU"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	left_vbox.add_child(title)
	
	# セパレータ
	left_vbox.add_child(HSeparator.new())
	
	var resume_btn = Button.new()
	resume_btn.text = "ゲームに戻る (ESC)"
	resume_btn.custom_minimum_size = Vector2(250, 50)
	resume_btn.add_theme_font_size_override("font_size", 18)
	resume_btn.focus_mode = Control.FOCUS_NONE
	resume_btn.pressed.connect(_toggle_pause)
	left_vbox.add_child(resume_btn)
	
	var save_btn = Button.new()
	save_btn.text = "セーブする"
	save_btn.custom_minimum_size = Vector2(250, 50)
	save_btn.add_theme_font_size_override("font_size", 18)
	save_btn.focus_mode = Control.FOCUS_NONE
	save_btn.pressed.connect(_on_pause_save_pressed)
	left_vbox.add_child(save_btn)
	
	pause_save_label = Label.new()
	pause_save_label.add_theme_color_override("font_color", Color("#28a745"))
	pause_save_label.add_theme_font_size_override("font_size", 14)
	pause_save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_vbox.add_child(pause_save_label)
	
	var skip_term_btn = Button.new()
	skip_term_btn.text = "学期をスキップ"
	skip_term_btn.custom_minimum_size = Vector2(250, 50)
	skip_term_btn.add_theme_font_size_override("font_size", 18)
	skip_term_btn.focus_mode = Control.FOCUS_NONE
	skip_term_btn.pressed.connect(_on_skip_term_pressed)
	left_vbox.add_child(skip_term_btn)

	var title_btn = Button.new()
	title_btn.text = "タイトルに戻る"
	title_btn.custom_minimum_size = Vector2(250, 50)
	title_btn.add_theme_font_size_override("font_size", 18)
	title_btn.focus_mode = Control.FOCUS_NONE
	title_btn.pressed.connect(_on_title_pressed)
	left_vbox.add_child(title_btn)

	var quit_btn = Button.new()
	quit_btn.text = "ゲームを終了する"
	quit_btn.custom_minimum_size = Vector2(250, 50)
	quit_btn.add_theme_font_size_override("font_size", 18)
	quit_btn.focus_mode = Control.FOCUS_NONE
	quit_btn.pressed.connect(_on_quit_pressed)
	left_vbox.add_child(quit_btn)

	var right_panel = PanelContainer.new()
	var right_style = StyleBoxFlat.new()
	right_style.bg_color = Color(0.08, 0.10, 0.12, 0.75)
	right_style.corner_radius_top_left = 12
	right_style.corner_radius_top_right = 12
	right_style.corner_radius_bottom_right = 12
	right_style.corner_radius_bottom_left = 12
	right_style.content_margin_left = 20
	right_style.content_margin_right = 20
	right_style.content_margin_top = 20
	right_style.content_margin_bottom = 20
	right_panel.add_theme_stylebox_override("panel", right_style)
	hbox.add_child(right_panel)

	pause_fast_travel_panel = VBoxContainer.new()
	pause_fast_travel_panel.add_theme_constant_override("separation", 10)
	pause_fast_travel_panel.custom_minimum_size = Vector2(280, 0)
	right_panel.add_child(pause_fast_travel_panel)
	_rebuild_fast_travel_panel()
	
	ui_layer.add_child(pause_menu)

func _rebuild_fast_travel_panel() -> void:
	if not is_instance_valid(pause_fast_travel_panel):
		return
	for child in pause_fast_travel_panel.get_children():
		child.queue_free()

	var global = get_node_or_null("/root/Global")
	if not global:
		return

	var current_stage_id: String = String(global.current_stage_id)
	var age_value: int = int(global.age)
	var current_stage_name: String = StageBuilder.get_stage_name(current_stage_id, age_value)

	var title = Label.new()
	title.text = "地図（ファストトラベル）"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	pause_fast_travel_panel.add_child(title)

	var current = Label.new()
	current.text = "現在地: %s" % current_stage_name
	current.add_theme_font_size_override("font_size", 14)
	current.add_theme_color_override("font_color", Color(0.74, 0.84, 0.96))
	pause_fast_travel_panel.add_child(current)

	pause_fast_travel_panel.add_child(HSeparator.new())

	for entry in FAST_TRAVEL_STAGES:
		var stage_id: String = _resolve_stage_id(String(entry.get("id", "")))
		if stage_id == "" or not StageBuilder.STAGES.has(stage_id):
			continue
		var btn = Button.new()
		btn.text = String(entry.get("label", stage_id))
		btn.custom_minimum_size = Vector2(250, 42)
		btn.focus_mode = Control.FOCUS_NONE
		var lock_msg: String = _get_stage_lock_message(stage_id)
		if stage_id == current_stage_id:
			btn.disabled = true
			btn.tooltip_text = "今いる場所"
		elif lock_msg != "":
			btn.disabled = true
			btn.tooltip_text = lock_msg
		else:
			btn.pressed.connect(_on_fast_travel_pressed.bind(stage_id))
		pause_fast_travel_panel.add_child(btn)

func _on_fast_travel_pressed(stage_id: String) -> void:
	var global = get_node_or_null("/root/Global")
	if not global:
		return
	var resolved_stage_id: String = _resolve_stage_id(stage_id)
	if resolved_stage_id == "" or not StageBuilder.STAGES.has(resolved_stage_id):
		return
	var lock_msg: String = _get_stage_lock_message(resolved_stage_id)
	if lock_msg != "":
		_show_bump_alert(lock_msg)
		return
	if String(global.current_stage_id) == resolved_stage_id:
		return
	_toggle_pause()
	global.current_stage_id = resolved_stage_id
	global.actions_today += 1
	_update_actions_hud()
	_load_stage()

func _setup_sleep_menu() -> void:
	if sleep_menu:
		return

	sleep_menu = ColorRect.new()
	sleep_menu.color = Color(0, 0, 0, 0.6)
	sleep_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	sleep_menu.hide()
	sleep_menu.process_mode = Node.PROCESS_MODE_ALWAYS

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	sleep_menu.add_child(center)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1d2630")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "休む"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "今日はここまでにしようか。"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.86, 0.96))
	vbox.add_child(subtitle)

	vbox.add_child(HSeparator.new())

	sleep_menu_options = VBoxContainer.new()
	sleep_menu_options.add_theme_constant_override("separation", 12)
	vbox.add_child(sleep_menu_options)

	var close_hint = Label.new()
	close_hint.text = "[ESC] 閉じる"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.add_theme_font_size_override("font_size", 13)
	close_hint.add_theme_color_override("font_color", Color(0.72, 0.80, 0.90))
	vbox.add_child(close_hint)

	ui_layer.add_child(sleep_menu)

func _show_sleep_menu(options: Array) -> void:
	if not sleep_menu:
		_setup_sleep_menu()
	_sleep_menu_current_options.clear()
	for child in sleep_menu_options.get_children():
		child.queue_free()
	for option in options:
		var option_text := String(option)
		_sleep_menu_current_options.append(option_text)
		var button = Button.new()
		button.text = option_text
		button.custom_minimum_size = Vector2(260, 46)
		button.add_theme_font_size_override("font_size", 17)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_sleep_menu_selected.bind(option_text))
		sleep_menu_options.add_child(button)
	_sleep_menu_showing = true
	sleep_menu.show()
	get_tree().paused = true

func _hide_sleep_menu() -> void:
	_sleep_menu_showing = false
	_sleep_menu_current_options.clear()
	if sleep_menu:
		sleep_menu.hide()
	get_tree().paused = false

func _confirm_sleep_menu_default() -> void:
	if _sleep_menu_current_options.is_empty():
		return
	_on_sleep_menu_selected(_sleep_menu_current_options[0])

func _trigger_bed_interaction() -> void:
	var global = get_node_or_null("/root/Global")
	if not global:
		return
	var opts: Array = ["今日を終える"]
	if int(global.day_in_term) < int(global.term_total_days) - 2:
		opts.append("学期末まで一気に進める")
	_show_sleep_menu(opts)

func _on_sleep_menu_selected(choice: String) -> void:
	var global = get_node_or_null("/root/Global")
	if not global:
		return
	global.day_in_term = clampi(int(global.day_in_term), 1, int(global.term_total_days))
	_hide_sleep_menu()
	match choice:
		"今日を終える":
			global.day_in_term = mini(int(global.day_in_term) + 1, int(global.term_total_days))
		"学期末まで一気に進める":
			global.day_in_term = global.term_total_days
		_:
			return
	global.actions_today = 0
	if int(global.day_in_term) >= int(global.term_total_days):
		if not global.has_pending_event("term_end_measurement"):
			global.queue_event("term_end_measurement")
	call_deferred("_run_sleep_transition")

func _run_sleep_transition() -> void:
	var global = get_node_or_null("/root/Global")
	if not global:
		return
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.z_index = 110
	fade.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(fade)
	var tw = create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.35)
	await tw.finished
	global.current_stage_id = "myroom"
	if player and player.has_method("update_measurements"):
		player.call("update_measurements")
	await _load_stage()
	_update_actions_hud()
	var tw_out = create_tween()
	tw_out.tween_property(fade, "color:a", 0.0, 0.45)
	await tw_out.finished
	fade.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _ending_overlay_showing:
		return
	if _school_day_transition_running:
		return
	if _sleep_menu_showing and event.is_action_pressed("ui_cancel"):
		_hide_sleep_menu()
		return
	if _sleep_menu_showing:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
			_confirm_sleep_menu_default()
		return
	if _term_choice_showing and event.is_action_pressed("ui_cancel"):
		return
	if _term_choice_showing and event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_on_grade_choice_selected("continue")
			KEY_2:
				_on_grade_choice_selected("ending")
		return

	if event.is_action_pressed("ui_cancel"): # デフォルトでESCキー
		if achievement_viewer and is_instance_valid(achievement_viewer) and achievement_viewer.visible:
			achievement_viewer.hide()
			get_tree().paused = false
		else:
			_toggle_pause()
	elif event is InputEventKey and event.pressed and not event.echo:
		if _in_dialogue and _choice_pending:
			if event.is_action_pressed("ui_up"):
				_move_choice_selection(-1)
				get_viewport().set_input_as_handled()
				return
			elif event.is_action_pressed("ui_down"):
				_move_choice_selection(1)
				get_viewport().set_input_as_handled()
				return
		if event.keycode == KEY_Q:
			if sidebar: sidebar.visible = not sidebar.visible
			_toggle_action_hint()
		elif event.keycode == KEY_G:
			_toggle_history_panel()
		elif event.keycode == KEY_E:
			if _in_dialogue:
				if _choice_pending:
					_activate_selected_choice()
				else:
					_advance_dialogue()
			elif _measurement_showing:
				_on_close_measurement_pressed()
			elif _nearby_standup:
				_do_standup()
			elif _nearby_bed:
				_trigger_bed_interaction()
			elif _nearby_term_hotspot != "":
				_trigger_term_hotspot(_nearby_term_hotspot)
			elif _nearby_transition_door != "":
				_enter_transition_door()
			elif _nearby_height_scale:
				_show_measurement_result()
			elif _nearby_npc:
				_interact_with_npc(_nearby_npc)

# 服装タイプを適用するヘルパー（サイドバーのドロップダウンから使用）
func _apply_tops_type(tops_type: String) -> void:
	const COLOR_MAP = {
		"sailor": "#1a2a5e",
		"blazer": "#212840",
		"blouse_bow": "#f0e8e0",
		"jumper_skirt": "#212840",
		"sweater": "#7a9a7a",
		"t_shirt": "#ab82a8",
	}
	Global.current_appearance["tops_type"] = tops_type
	if COLOR_MAP.has(tops_type):
		Global.current_appearance["tops_color"] = COLOR_MAP[tops_type]
	var drawer = player.get_node_or_null("CharacterDrawer") if player else null
	if drawer: drawer.queue_redraw()


func _toggle_action_hint() -> void:
	if action_hint_panel:
		action_hint_panel.visible = not action_hint_panel.visible

func _get_action_hint_text() -> String:
	if _sleep_menu_showing:
		return "[ESC] 閉じる"
	if _term_choice_showing:
		return "[1][2] 進級後の進み方を選ぶ"
	if _in_dialogue:
		return "[E] 次へ"
	if _measurement_showing:
		return "[E] 閉じる"
	if _nearby_bed:
		return "[E] 休む"
	if _measurement_showing:
		return "[E] 次の学期へ進む"
	if _nearby_term_hotspot != "":
		return "[E] %s" % _get_term_hotspot_prompt(_nearby_term_hotspot)
	if _nearby_transition_door != "":
		var dest = _nearby_transition_door.substr("door_to_".length())
		var dest_name = StageBuilder.get_stage_name(dest, Global.age) if StageBuilder.STAGES.has(dest) else dest
		return "[E] %s へ移動" % dest_name
	if _nearby_height_scale:
		return "[E] 身長を測る"
	if _nearby_npc:
		var npc_id: String = _nearby_npc.get("npc_id") if _nearby_npc.get("npc_id") != null else ""
		if npc_id != "":
			return "[E] 話しかける"
	return _get_default_action_hint_text()

func _toggle_pause() -> void:
	if pause_menu:
		var is_paused = not get_tree().paused
		get_tree().paused = is_paused
		pause_menu.visible = is_paused
		if is_paused:
			_rebuild_fast_travel_panel()
		if pause_save_label:
			pause_save_label.text = ""

func _on_pause_save_pressed() -> void:
	_on_save_pressed()
	if pause_save_label:
		var global = get_node_or_null("/root/Global")
		if global and global.current_slot >= 1:
			pause_save_label.text = "セーブしました (SLOT %02d)" % global.current_slot
			await get_tree().create_timer(2.0).timeout
			if pause_save_label: pause_save_label.text = ""
		else:
			pause_save_label.text = "スロットが選択されていません"

func _on_title_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/TitleScene.tscn")

func _on_quit_pressed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.replace(new URL('./', window.location.href).toString());")
	else:
		get_tree().quit()

func _on_skip_term_pressed() -> void:
	# ポーズメニューを閉じて学期をスキップする
	_toggle_pause()
	var global = get_node_or_null("/root/Global")
	if not global:
		return
	# 学期末測定イベントをキューに積む（term_end_measurementと同じ流れ）
	if not global.has_pending_event("term_end_measurement"):
		global.queue_event("term_end_measurement")
	global.current_stage_id = "myroom"
	if player and player.has_method("update_measurements"):
		player.call("update_measurements")
	_load_stage()

func _update_actions_hud() -> void:
	if not action_label:
		return
	var global = get_node_or_null("/root/Global")
	if not global:
		action_label.text = ""
		return
	action_label.text = "%d日目  行動 %d/%d" % [
		int(global.day_in_term),
		int(global.actions_today),
		int(global.max_actions_per_day),
	]
	var font_color = Color(0.95, 0.97, 1.0)
	if int(global.actions_today) >= int(global.max_actions_per_day):
		font_color = Color(1.0, 0.86, 0.78)
		var notice_key = "%d:%d" % [int(global.term), int(global.day_in_term)]
		if _last_soft_limit_notice_key != notice_key:
			_show_bump_alert("もう夕方だ。今日を終えよう。")
			_last_soft_limit_notice_key = notice_key
	else:
		_last_soft_limit_notice_key = ""
	action_label.add_theme_color_override("font_color", font_color)


func _update_ui():
	if not player or not status_label: return
	
	var global = get_node_or_null("/root/Global")
	var stage_id: String = global.current_stage_id if global else "room"
	var stage_name: String = StageBuilder.get_stage_name(stage_id, global.age if global else 0)
	if stage_title_label:
		stage_title_label.text = stage_name
	var m = player.get("m")
	if not m: return
	
	var params = global.current_params if global else m
	
	var age_val: int = global.age if global else 0
	var term_val: int = global.term if global else 0
	var stress_val: int = global.stress if global else 0
	var text = "【基本情報】\n"
	text += "Stage: %s\n" % stage_name
	text += "day %d/%d  action %d/%d\n" % [
		int(global.day_in_term) if global else 1,
		int(global.term_total_days) if global else 30,
		int(global.actions_today) if global else 0,
		int(global.max_actions_per_day) if global else 3,
	]
	text += "%d歳 / %s\n" % [age_val, Global.get_school_term_label(age_val, term_val)]
	text += "stress: %d / 100 (%s)\n" % [int(stress_val), _get_stress_state_text(int(stress_val))]
	var confidence_val: int = global.self_confidence if global else 0
	var complex_val: int = global.self_complex if global else 0
	text += "気持ち: 受容 %d / 戸惑い %d\n" % [confidence_val, complex_val]
	text += "身長: %.1f cm  頭身: %.1f  股下: %.1f%%\n" % [params["height"], params["ratio"], params["legRatio"]]
	text += "Pose: %s ([1]-[5], [S]キー)\n" % player.pose
	
	text += "\n【操作方法】\n"
	text += "矢印キー左右: 移動\n"
	text += "矢印キー下: 正面向き\n"
	text += "矢印キー上: 後ろ向き\n"
	text += "Eキー: ドアを通る\n"
	
	text += "F12: Screenshot save\n"
	status_label.text = text
	_update_daily_guide()

func _update_daily_guide() -> void:
	if not is_instance_valid(daily_guide_panel) or not is_instance_valid(daily_guide_label):
		return
	var global = get_node_or_null("/root/Global")
	if not global:
		daily_guide_label.text = ""
		daily_guide_panel.hide()
		return

	var stage_id: String = String(global.current_stage_id)
	var actions: int = int(global.actions_today)
	var max_actions: int = int(global.max_actions_per_day)
	var in_school_classroom: bool = StageBuilder.is_school_classroom_stage(stage_id)
	var hint_text := ""

	if stage_id == "myroom" and actions == 0:
		hint_text = "Hint: 朝だ。学校に向かおう"
	elif in_school_classroom:
		hint_text = "Hint: 授業を受けよう"
	elif stage_id == "myroom" and actions >= max_actions:
		hint_text = "Hint: ベッドで休もう"
	elif actions >= max_actions:
		hint_text = "Hint: 夕方だ。家に帰ろう"

	daily_guide_label.text = hint_text
	daily_guide_panel.visible = hint_text != ""

func _queue_dialogue_event_once(global: Node, event_id: String, npc_id: String, dialogue_key: String) -> void:
	if global == null:
		return
	if global.has_pending_event(event_id):
		return
	if global.has_experienced_event("%s_%s" % [npc_id, dialogue_key]):
		return
	global.queue_event(event_id)

func _get_first_visit_dialogue_key(stage_id: String) -> String:
	if StageBuilder.is_gymnasium_stage(stage_id):
		return "npc_firstvisit_gymnasium"
	return ""

func _is_public_milestone_stage(stage_id: String) -> bool:
	return stage_id in ["station", "platform", "train", "outdoor", "adjacent_town", "gakuenmae", "gakuenmachi"]

func _queue_stage_arrival_events(global: Node, stage_id: String, was_first_visit: bool) -> void:
	if global == null:
		return
	if was_first_visit:
		var first_visit_key: String = _get_first_visit_dialogue_key(stage_id)
		if first_visit_key != "":
			_queue_dialogue_event_once(global, "npc_firstvisit_%s" % stage_id, "generic", first_visit_key)
	var height_cm: float = float(global.current_params.get("height", 0.0))
	if height_cm >= 170.0 and StageBuilder.is_school_stage(stage_id):
		_queue_dialogue_event_once(global, "npc_talk_tall", "generic", "npc_talk_tall")
	if height_cm >= 180.0 and _is_public_milestone_stage(stage_id):
		_queue_dialogue_event_once(global, "npc_talk_huge", "generic", "npc_talk_huge")
	if height_cm >= 190.0:
		_queue_dialogue_event_once(global, "npc_talk_veryhuge", "generic", "npc_talk_veryhuge")

func _defer_pending_stage_event(global: Node, ev: String) -> void:
	if global == null or ev == "":
		return
	global.pending_events.push_back(ev)

func _handle_pending_stage_event(global: Node, stage_id: String, ev: String) -> bool:
	if global == null or ev == "":
		return false
	if ev == "semester_start":
		if StageBuilder.is_school_classroom_stage(stage_id):
			await get_tree().create_timer(0.5).timeout
			_start_dialogue("teacher", "semester_start")
			if not global.senior_gym_invited:
				global.senior_gym_invited = true
				global.queue_event("gym_senior_invite")
			return true
		else:
			_defer_pending_stage_event(global, ev)
			return false
	elif ev == "gym_senior_invite":
		if StageBuilder.is_gymnasium_stage(stage_id):
			await get_tree().create_timer(0.8).timeout
			_start_dialogue("senior", "first_meet")
			return true
		else:
			_defer_pending_stage_event(global, ev)
			return false
	elif ev == "npc_talk_tall":
		if StageBuilder.is_school_stage(stage_id):
			await get_tree().create_timer(0.45).timeout
			_start_dialogue("generic", "npc_talk_tall")
			return true
		else:
			_defer_pending_stage_event(global, ev)
			return false
	elif ev == "npc_talk_huge":
		if _is_public_milestone_stage(stage_id):
			await get_tree().create_timer(0.45).timeout
			_start_dialogue("generic", "npc_talk_huge")
			return true
		else:
			_defer_pending_stage_event(global, ev)
			return false
	elif ev == "npc_talk_veryhuge":
		# 家の中では街のNPCのつぶやきは発火しない
		if stage_id == "room" or stage_id == "myroom":
			_defer_pending_stage_event(global, ev)
			return false
		await get_tree().create_timer(0.35).timeout
		_start_dialogue("generic", "npc_talk_veryhuge")
		return true
	elif ev.begins_with("npc_firstvisit_"):
		if ev == "npc_firstvisit_%s" % stage_id:
			var first_visit_key: String = _get_first_visit_dialogue_key(stage_id)
			if first_visit_key != "":
				await get_tree().create_timer(0.45).timeout
				_start_dialogue("generic", first_visit_key)
				return true
			return false
		else:
			_defer_pending_stage_event(global, ev)
			return false
	elif ev == "summer_growth":
		if stage_id == "room":
			await get_tree().create_timer(0.8).timeout
			var summer_key = "summer_growth"
			if global.vball_joined and global.vball_story_phase >= 2:
				summer_key = "summer_growth_vball"
			_start_dialogue("player", summer_key)
			if global.vball_story_phase >= 2 and global.vball_story_phase < 6:
				global.vball_story_phase = 6
			return true
		else:
			_defer_pending_stage_event(global, ev)
			return false
	elif ev == "vball_tell_senior":
		if StageBuilder.is_gymnasium_stage(stage_id):
			await get_tree().create_timer(0.8).timeout
			_start_dialogue("senior", "pain_concern")
			return true
		else:
			_defer_pending_stage_event(global, ev)
			return false
	elif ev == "entrance_ceremony":
		if stage_id == "myroom":
			await get_tree().create_timer(1.2).timeout
			_start_dialogue("player", _get_term_intro_dialogue_key(int(global.age), int(global.term)))
			return true
		else:
			_defer_pending_stage_event(global, ev)
			return false
	elif ev == "term_end_measurement":
		if stage_id == "myroom":
			await get_tree().create_timer(0.4).timeout
			global.advance_term()
			if player and player.has_method("update_measurements"):
				player.call("update_measurements")
			_show_measurement_result(true)
			return true
		else:
			_defer_pending_stage_event(global, ev)
			return false
	elif ev == "growth_spurt":
		if stage_id == "room" or stage_id == "myroom":
			await get_tree().create_timer(1.0).timeout
			_start_dialogue("player", "growth_spurt")
			return true
		else:
			_defer_pending_stage_event(global, ev)
			return false
	elif ev == "high_scout_contact":
		if stage_id in ["room", "myroom", "gakuenmachi"]:
			await get_tree().create_timer(0.8).timeout
			_start_dialogue("player", "high_scout_contact")
			global.set_story_flag("high_scout_done")
			return true
		else:
			_defer_pending_stage_event(global, ev)
			return false
	elif ev == "middle_boys_growth_talk":
		if stage_id == "school_hallway_middle":
			await get_tree().create_timer(0.6).timeout
			_start_dialogue("generic", "middle_boys_growth_talk")
			global.set_story_flag("middle_boys_growth_talk_done")
			return true
		else:
			_defer_pending_stage_event(global, ev)
			return false
	return false

func _load_stage():
	var global = get_node_or_null("/root/Global")
	var stage_id = global.current_stage_id if global else "myroom"
	stage_id = _resolve_stage_id(String(stage_id))
	var was_first_visit := false
	if global:
		global.current_stage_id = stage_id
		was_first_visit = global.is_first_visit(stage_id)
		global.record_stage_visit(stage_id)
		_queue_stage_arrival_events(global, stage_id, was_first_visit)
	_sync_player_stage_appearance(stage_id)

	StageBuilder.build_stage(stage_id, self, p, global.age if global else 0)
	_bind_edge_triggers()
	_spawn_npcs(stage_id)

	if global and global.current_slot >= 1:
		global.save_slot(global.current_slot)

	if player:
		player.position = Vector2(100 * p, 0)
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			var stage_width_px := int(float(StageBuilder.STAGES[stage_id]["width"]) * p) if StageBuilder.STAGES.has(stage_id) else 0
			var m = player.get("m")
			var ceiling_h = StageBuilder.STAGES[stage_id].get("ceiling_height", null) if StageBuilder.STAGES.has(stage_id) else null
			var is_gym: bool = stage_id == "gymnasium" or StageBuilder.is_gymnasium_stage(stage_id)
			var is_schoolyard: bool = stage_id == "schoolyard" or StageBuilder.is_schoolyard_stage(stage_id)
			if m and m.has("height"):
				cam.offset = Vector2(0, -m["height"] * p * 0.4)
			# 体育館・校庭: zoom アウトで視野を広げる。limit_bottom が上端を適切に固定する
			var should_zoom_out: bool = (is_gym and ceiling_h != null) or is_schoolyard
			cam.zoom = Vector2(0.75, 0.75) if should_zoom_out else Vector2(1.0, 1.0)
			cam.limit_left = 0
			cam.limit_right = stage_width_px
			# zoom=0.75 時: limit_bottom=333 → 上端が約420cm（840px）に固定される
			# 計算: top = limit_bottom - viewport_height_world = 333 - (880/0.75) ≈ -840px
			cam.limit_bottom = 333 if should_zoom_out else 250
		var bump_handler := Callable(self, "_on_player_head_bump")
		if player.has_signal("head_bump") and not player.is_connected("head_bump", bump_handler):
			player.connect("head_bump", bump_handler)

	if global:
		var pending_count := int(global.pending_events.size())
		for _event_index in range(pending_count):
			var next_event: String = global.pop_next_event()
			if next_event == "":
				break
			var handled: bool = await _handle_pending_stage_event(global, stage_id, next_event)
			if handled:
				break
		_update_actions_hud()
		if global.current_slot >= 1:
			global.save_slot(global.current_slot)

func _bind_edge_triggers() -> void:
	for child in get_children():
		if child is Area2D and child.has_meta("edge_target_stage"):
			var area := child as Area2D
			var target_stage: String = String(area.get_meta("edge_target_stage"))
			var handler := Callable(self, "_on_edge_trigger_body_entered").bind(target_stage)
			if not area.is_connected("body_entered", handler):
				area.body_entered.connect(handler)

func _on_edge_trigger_body_entered(body: Node, target_stage: String) -> void:
	if body != player:
		return
	if _edge_transition_running or _in_dialogue or _measurement_showing or _term_choice_showing or _sleep_menu_showing:
		return
	_enter_edge_transition(target_stage)

func _enter_edge_transition(target_stage: String) -> void:
	if _edge_transition_running:
		return
	var global = get_node_or_null("/root/Global")
	if not global:
		return
	var resolved_target = _resolve_stage_id(target_stage)
	if not StageBuilder.STAGES.has(resolved_target):
		return
	var from_stage_id: String = String(global.current_stage_id)
	_edge_transition_running = true
	global.current_stage_id = resolved_target
	global.actions_today += 1
	_nearby_bed = false
	_update_actions_hud()
	_load_stage()
	if player:
		var stage_width = float(StageBuilder.STAGES[resolved_target]["width"])
		var spawn_x = 80.0
		if from_stage_id == "adjacent_town" and resolved_target == "outdoor":
			spawn_x = stage_width - 80.0
		elif from_stage_id == "station" and resolved_target == "platform":
			spawn_x = 270.0  # ホーム左側に到着
		elif from_stage_id == "platform" and resolved_target == "station":
			spawn_x = stage_width - 260.0  # 駅右側に到着
		player.position = Vector2(spawn_x * p, 0)
	_edge_transition_running = false

func _get_entrance_dialogue_key(age: int) -> String:
	if age <= 6:
		return "entrance_elementary"
	if age <= 12:
		return "entrance_middle"
	return "entrance_high"

func _is_entrance_term(age: int, term_value: int) -> bool:
	if not age in [6, 12, 15]:
		return false
	return Global.get_term_in_school_year(age, term_value) == 1

func _get_term_intro_dialogue_key(age: int, term_value: int) -> String:
	if _is_entrance_term(age, term_value):
		return _get_entrance_dialogue_key(age)
	return "new_semester"

func _on_player_head_bump(obs_id: String, obs_height_cm: float) -> void:
	_show_bump_alert(StageBuilder.get_head_bump_comment(obs_id, obs_height_cm))

func _spawn_stage_npc(
	npc_scene: PackedScene,
	position_cm: float,
	params: Dictionary = {},
	app: Dictionary = {},
	npc_id: String = "",
	patrol_cm: float = 80.0
) -> Node:
	var npc = npc_scene.instantiate()
	npc.set_meta("is_npc", true)
	if npc_id != "":
		npc.npc_id = npc_id
	if not params.is_empty():
		npc.custom_params = params
	if not app.is_empty():
		npc.custom_appearance = app
	npc.position = Vector2(position_cm * p, 0)
	npc.patrol_range = patrol_cm
	add_child(npc)
	return npc

func _spawn_npcs(stage_id: String) -> void:
	var npc_scene = load("res://NPC.tscn")
	if not npc_scene: return
	
	for child in get_children():
		if child.has_meta("is_npc"):
			child.queue_free()

	var shoe_overrides: Dictionary = _build_stage_shoe_overrides(stage_id)
	var hall_student_params := {
		"elementary": {"height": 132.0, "ratio": 6.0, "legRatio": 43.0, "sex": "female"},
		"middle": {"height": 149.0, "ratio": 6.4, "legRatio": 44.0, "sex": "female"},
		"high": {"height": 160.0, "ratio": 6.8, "legRatio": 45.0, "sex": "female"},
	}
	var classmate_params := {
		"elementary": {"height": 128.0, "ratio": 5.9, "legRatio": 43.0, "sex": "female"},
		"middle": {"height": 147.0, "ratio": 6.3, "legRatio": 44.0, "sex": "female"},
		"high": {"height": 158.0, "ratio": 6.7, "legRatio": 45.0, "sex": "female"},
	}
	var stage_suffix := ""
	if stage_id.ends_with("_elementary"):
		stage_suffix = "elementary"
	elif stage_id.ends_with("_middle"):
		stage_suffix = "middle"
	elif stage_id.ends_with("_high"):
		stage_suffix = "high"

	if stage_id == "outdoor":
		_spawn_stage_npc(npc_scene, 300.0, {
			"height": 158.0,
			"ratio": 7.0,
			"legRatio": 45.0,
			"sex": "female"
		}, {}, "", 120.0)
		
		# 街にいる小さな子供
		_spawn_stage_npc(npc_scene, 500.0, {
			"height": 110.0,
			"ratio": 5.5,
			"legRatio": 45.0,
			"sex": "female"
		}, {
			"hair_style": "short",
			"hair_color": "#885533",
			"tops_type": "t_shirt",
			"tops_color": "#ffdd00",
			"bottoms_type": "pants",
			"bottoms_color": "#33aa33",
			"shoes_type": "sneakers",
			"shoes_color": "#ffffff"
		}, "", 90.0)

	elif stage_id == "adjacent_town":
		var middle_uniform: Dictionary = _build_stage_uniform_appearance("school_hallway_middle", "short", "#4f382b")
		_spawn_stage_npc(npc_scene, 520.0, hall_student_params["middle"], middle_uniform, "", 70.0)
		_spawn_stage_npc(npc_scene, 860.0, {
			"height": 160.0,
			"ratio": 6.9,
			"legRatio": 44.0,
			"sex": "female"
		}, {}, "", 90.0)

	elif stage_id == "platform":
		_spawn_stage_npc(npc_scene, 760.0, {
			"height": 162.0,
			"ratio": 6.9,
			"legRatio": 44.0,
			"sex": "female"
		}, {}, "", 110.0)

	elif stage_id == "gakuenmae":
		var high_uniform_station: Dictionary = _build_stage_uniform_appearance("school_hallway_high", "short", "#4c3329")
		_spawn_stage_npc(npc_scene, 820.0, hall_student_params["high"], high_uniform_station, "", 80.0)

	elif stage_id == "gakuenmachi":
		var high_uniform_town: Dictionary = _build_stage_uniform_appearance("school_hallway_high", "side_tail", "#413026")
		_spawn_stage_npc(npc_scene, 760.0, hall_student_params["high"], high_uniform_town, "", 85.0)
		_spawn_stage_npc(npc_scene, 1240.0, {
			"height": 158.0,
			"ratio": 6.8,
			"legRatio": 44.0,
			"sex": "female"
		}, {
			"hair_style": "short",
			"hair_color": "#6a4b3b",
			"tops_type": "sweater",
			"tops_color": "#b78b6e",
			"bottoms_type": "skirt_long",
			"bottoms_color": "#4c3d37",
			"shoes_type": "loafer",
			"shoes_color": "#4b4b52"
		}, "", 60.0)

	elif stage_id == "room":
		_spawn_stage_npc(npc_scene, 400.0, {}, {}, "mother", 0.0)
		_spawn_stage_npc(npc_scene, 700.0, {"height": 170.0, "ratio": 7.3, "legRatio": 46.0, "sex": "male"}, {}, "father", 0.0)

	elif StageBuilder.is_school_hallway_stage(stage_id):
		var hall_student_appearance: Dictionary = _build_stage_uniform_appearance(stage_id, "side_tail", "#5b4334")
		_spawn_stage_npc(npc_scene, 700.0, hall_student_params.get(stage_suffix, hall_student_params["middle"]), hall_student_appearance, "", 70.0)
		_spawn_stage_npc(npc_scene, 1180.0 if stage_suffix == "high" else 980.0, {"height": 152.0, "ratio": 6.8, "legRatio": 44.0, "sex": "female"}, {}, "haruka", 55.0)
		if stage_suffix == "high":
			_spawn_stage_npc(npc_scene, 1450.0, {"height": 168.0, "ratio": 7.1, "legRatio": 45.0, "sex": "female"}, {}, "senior", 85.0)

	elif StageBuilder.is_school_classroom_stage(stage_id):
		_spawn_stage_npc(npc_scene, 300.0, {"height": 152.0, "ratio": 6.8, "legRatio": 44.0, "sex": "female"}, {}, "haruka", 40.0)
		var classmate_appearance: Dictionary = _build_stage_uniform_appearance(stage_id, "short", "#553a2b")
		_spawn_stage_npc(npc_scene, 1120.0, classmate_params.get(stage_suffix, classmate_params["middle"]), classmate_appearance, "", 30.0)
		if stage_suffix == "high":
			_spawn_stage_npc(npc_scene, 760.0, {"height": 168.0, "ratio": 7.1, "legRatio": 45.0, "sex": "female"}, {}, "senior", 45.0)

	elif StageBuilder.is_schoolyard_stage(stage_id):
		if stage_suffix == "elementary":
			# 小学校の男子同級生（遊具エリアにいる）
			_spawn_stage_npc(npc_scene, 880.0, {
				"height": 124.0, "ratio": 5.9, "legRatio": 45.0, "sex": "male"
			}, {
				"hair_style": "short", "hair_color": "#3a2e28",
				"tops_type": "t_shirt", "tops_color": "#4a7fc1",
				"bottoms_type": "pants", "bottoms_color": "#444466",
				"shoes_type": "sneakers", "shoes_color": "#eeeeee"
			}, "", 70.0)
			_spawn_stage_npc(npc_scene, 1080.0, {
				"height": 127.0, "ratio": 6.0, "legRatio": 45.0, "sex": "male"
			}, {
				"hair_style": "short", "hair_color": "#5a4030",
				"tops_type": "t_shirt", "tops_color": "#cc5544",
				"bottoms_type": "pants", "bottoms_color": "#334455",
				"shoes_type": "sneakers", "shoes_color": "#cccccc"
			}, "", 80.0)
		elif stage_suffix == "middle":
			# 中学校の男子（体操服風）
			_spawn_stage_npc(npc_scene, 1500.0, {
				"height": 155.0, "ratio": 6.5, "legRatio": 45.0, "sex": "male"
			}, {
				"hair_style": "short", "hair_color": "#2e2620",
				"tops_type": "t_shirt", "tops_color": "#ffffff",
				"bottoms_type": "pants", "bottoms_color": "#1a1a2e",
				"shoes_type": "sneakers", "shoes_color": "#dddddd"
			}, "", 90.0)

	elif StageBuilder.is_gymnasium_stage(stage_id):
		_spawn_stage_npc(npc_scene, 1200.0, {"height": 168.0, "ratio": 7.1, "legRatio": 45.0, "sex": "female"}, {}, "senior", 90.0)

	elif StageBuilder.is_infirmary_stage(stage_id):
		# 保健室の先生（小柄な女性、机の前に立っている）
		var nurse_app: Dictionary = {
			"hair_style": "short",
			"hair_color": "#334422",
			"tops_type": "blouse",
			"tops_color": "#ffffff",
			"bottoms_type": "skirt_long",
			"bottoms_color": "#ffffff",
		}
		for key in shoe_overrides.keys():
			nurse_app[key] = shoe_overrides[key]
		_spawn_stage_npc(npc_scene, 680.0, {
			"height": 155.0,
			"ratio": 6.8,
			"legRatio": 44.0,
			"sex": "female"
		}, nurse_app, "nurse", 0.0)
		# はるかが追随中なら身長計の横にスポーン
		var global_inf = get_node_or_null("/root/Global")
		if global_inf and global_inf.haruka_following:
			_spawn_stage_npc(npc_scene, 350.0, {
				"height": 152.0,
				"ratio": 6.8,
				"legRatio": 44.0,
				"sex": "female"
			}, {}, "haruka", 0.0)

func _on_save_pressed() -> void:
	var global = get_node_or_null("/root/Global")
	if not global: return
	if global.current_slot >= 1:
		global.save_slot(global.current_slot)

func _enter_transition_door() -> void:
	# "door_to_XXX" → 遷移先ステージID = "XXX"
	var new_stage_id = _nearby_transition_door.substr("door_to_".length())
	var lock_message: String = _get_stage_lock_message(new_stage_id)
	if lock_message != "":
		_show_bump_alert(lock_message)
		return
	new_stage_id = _resolve_stage_id(new_stage_id)
	if not StageBuilder.STAGES.has(new_stage_id):
		return

	var from_stage_id = ""
	var global = get_node_or_null("/root/Global")
	if global:
		from_stage_id = global.current_stage_id
		global.current_stage_id = new_stage_id
		global.actions_today += 1
		_update_actions_hud()

	_nearby_transition_door = ""
	_nearby_bed = false
	_load_stage()

	# 遷移先の「戻り口ドア」の近くにスポーン
	if player and from_stage_id != "" and StageBuilder.STAGES.has(new_stage_id):
		var return_door_id = "door_to_" + from_stage_id
		var stage_width = float(StageBuilder.STAGES[new_stage_id]["width"])
		var cur_age = global.age if global else 0
		var spawned := false
		for obs in StageBuilder.get_obstacles(new_stage_id, cur_age):
			if obs["id"] == return_door_id:
				var obs_x = float(obs["x"])
				var obs_x2 = float(obs["x2"])
				var obs_center = (obs_x + obs_x2) / 2.0
				var spawn_x: float
				# ドアが右半分 → 左に出現、左半分 → 右に出現
				if obs_center > stage_width / 2.0:
					spawn_x = obs_x - 50.0
				else:
					spawn_x = obs_x2 + 50.0
				spawn_x = clamp(spawn_x, 50.0, stage_width - 50.0)
				player.position = Vector2(spawn_x * p, 0)
				spawned = true
				break
		# station には door_to_platform を置かない設計なので、platform から戻る時は右側に出す
		if not spawned and new_stage_id == "station" and from_stage_id == "platform":
			player.position = Vector2((stage_width - 260.0) * p, 0)

# ─── 成長システム ───────────────────────────────────────────────

# 測定パネル内の動的ラベル（アニメ用）
var _meas_height_label: Label = null
var _meas_diff_label: Label = null
var _meas_btn_row: HBoxContainer = null
var _measurement_showing: bool = false
var _mini_proxy: Node2D = null
var _mini_drawer: Node2D = null
var _meas_graph: Control = null

func _setup_measurement_panel() -> void:
	measurement_panel = ColorRect.new()
	measurement_panel.color = Color(0, 0, 0, 0.0)
	measurement_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	measurement_panel.hide()
	measurement_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	measurement_panel.add_child(center)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1a2a3a")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 48
	style.content_margin_right = 48
	style.content_margin_top = 40
	style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	panel.add_child(hbox)

	# --- 左: ミニアバタービュー ---
	var svc = SubViewportContainer.new()
	svc.custom_minimum_size = Vector2(160, 0)
	svc.stretch = true
	svc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(svc)

	var sv = SubViewport.new()
	sv.size = Vector2i(160, 380)
	sv.transparent_bg = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.process_mode = Node.PROCESS_MODE_ALWAYS
	svc.add_child(sv)

	_mini_proxy = Node2D.new()
	_mini_proxy.set_script(load("res://scripts/MiniPlayerProxy.gd"))
	_mini_proxy.position = Vector2(80, 365)
	_mini_proxy.process_mode = Node.PROCESS_MODE_ALWAYS
	sv.add_child(_mini_proxy)

	_mini_drawer = Node2D.new()
	_mini_drawer.set_script(load("res://scripts/CharacterDrawer.gd"))
	_mini_drawer.process_mode = Node.PROCESS_MODE_ALWAYS
	_mini_proxy.add_child(_mini_drawer)

	# --- 右: テキストUI ---
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	hbox.add_child(vbox)

	var title = Label.new()
	title.text = "身体測定結果"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# 身長数値（カウントアップアニメ対象）
	_meas_height_label = Label.new()
	_meas_height_label.add_theme_font_size_override("font_size", 48)
	_meas_height_label.add_theme_color_override("font_color", Color.WHITE)
	_meas_height_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meas_height_label.text = "--- cm"
	vbox.add_child(_meas_height_label)

	# 前回比（ポップアップアニメ対象）
	_meas_diff_label = Label.new()
	_meas_diff_label.add_theme_font_size_override("font_size", 28)
	_meas_diff_label.add_theme_color_override("font_color", Color("#7fffb0"))
	_meas_diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meas_diff_label.modulate.a = 0.0
	vbox.add_child(_meas_diff_label)

	# 成長グラフ（測定パネル内インライン表示）
	var GrowthGraphScript = load("res://scripts/GrowthGraph.gd")
	_meas_graph = GrowthGraphScript.new()
	_meas_graph.custom_minimum_size = Vector2(380, 110)
	vbox.add_child(_meas_graph)

	vbox.add_child(HSeparator.new())

	# 詳細テキスト（平均比較・コメント）
	measurement_content_scroll = ScrollContainer.new()
	measurement_content_scroll.custom_minimum_size = Vector2(380, 180)
	measurement_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	measurement_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	measurement_content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(measurement_content_scroll)

	measurement_content_label = Label.new()
	measurement_content_label.add_theme_font_size_override("font_size", 16)
	measurement_content_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	measurement_content_label.custom_minimum_size = Vector2(380, 0)
	measurement_content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	measurement_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	measurement_content_label.modulate.a = 0.0
	measurement_content_scroll.add_child(measurement_content_label)

	vbox.add_child(HSeparator.new())

	_meas_btn_row = HBoxContainer.new()
	_meas_btn_row.add_theme_constant_override("separation", 24)
	_meas_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_meas_btn_row.modulate.a = 0.0
	vbox.add_child(_meas_btn_row)

	var close_btn = Button.new()
	close_btn.text = "閉じる"
	close_btn.text = "閉じる"
	close_btn.custom_minimum_size = Vector2(140, 48)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.pressed.connect(_on_close_measurement_pressed)
	_meas_btn_row.add_child(close_btn)

	var next_btn = Button.new()
	next_btn.hide()
	next_btn.text = "閉じる"
	next_btn.text = "次の学期へ"
	next_btn.custom_minimum_size = Vector2(160, 48)
	next_btn.add_theme_font_size_override("font_size", 16)
	next_btn.focus_mode = Control.FOCUS_NONE
	next_btn.pressed.connect(_on_close_measurement_pressed)
	_meas_btn_row.add_child(next_btn)

	ui_layer.add_child(measurement_panel)

func _update_mini_avatar(h_cm: float) -> void:
	if not is_instance_valid(_mini_proxy) or not is_instance_valid(_mini_drawer):
		return
	var global = get_node_or_null("/root/Global")
	if not global:
		return
	var temp_params = global.current_params.duplicate()
	temp_params["height"] = h_cm
	_mini_proxy.m = global.get_custom_body_measurements(temp_params)
	_mini_proxy.visual_height_cm = h_cm
	_mini_drawer.queue_redraw()

func _show_measurement_result(return_to_myroom: bool = false) -> void:
	var global = get_node_or_null("/root/Global")
	if not global: return

	var h: float = global.current_params["height"]
	var prev_h: float = global.prev_height
	var animate_growth: bool = return_to_myroom and prev_h > 0.0 and absf(h - prev_h) > 0.01
	var a: int = global.age
	var avg_h: float = global.get_avg_height(a)
	var diff_avg: float = h - avg_h
	var diff_prev: float = h - prev_h if prev_h > 0.0 else 0.0

	# 詳細テキスト（後でフェードイン）
	var detail = "年齢：%d歳  %s\n" % [a, Global.get_school_term_label(a, global.term)]
	detail += "同学年平均：%.1f cm  （差：%+.1f cm）\n\n" % [avg_h, diff_avg]
	detail += global.get_measurement_comment(diff_avg)
	detail += "\n\n【今学期の手触り】\n"
	detail += "stress %d / 100 (%s)\n" % [int(global.stress), _get_stress_state_text(int(global.stress))]
	if global.term_memory_note != "":
		detail += "%s\n" % String(global.term_memory_note)
	detail += _get_term_reflection_text(global)
	measurement_content_label.text = detail
	_reset_measurement_content_scroll()

	# 前回比ラベル
	if prev_h > 0.0:
		_meas_diff_label.text = "前回比  %+.1f cm" % diff_prev if return_to_myroom else "現在値（前回比 %+.1f cm）" % diff_prev
	else:
		_meas_diff_label.text = "はじめての測定"

	# 初期状態リセット
	_meas_height_label.text = "%.1f cm" % (prev_h if animate_growth else h)
	_meas_diff_label.modulate.a = 0.0
	measurement_content_label.modulate.a = 0.0
	_meas_btn_row.modulate.a = 0.0
	_meas_diff_label.scale = Vector2(0.7, 0.7)
	_update_mini_avatar(prev_h if animate_growth else h)

	# 学期末測定のみ成長演出。任意測定は現在値をそのまま表示する。
	if _meas_graph:
		if animate_growth:
			var preview = global.growth_history.duplicate()
			preview.append({
				"height": h, "avg_height": avg_h,
				"age": a, "term": global.term,
				"diff_prev": diff_prev, "diff_avg": diff_avg,
			})
			_meas_graph.set_data(preview)
			_meas_graph.animate_new_point(1.4) # カウントアップ(1.4秒)と同期
		else:
			_meas_graph.set_data(global.growth_history)

	_measurement_returns_to_myroom = return_to_myroom
	_measurement_showing = true
	measurement_panel.show()
	get_tree().paused = true

	# 背景フェードイン（MainScene は PROCESS_MODE_ALWAYS なので pause 中でも動作する）
	var tween = create_tween()
	tween.tween_property(measurement_panel, "color", Color(0, 0, 0, 0.75), 0.4)

	# 学期末測定のみ、前回値から現在値へカウントアップする
	if animate_growth:
		tween.tween_method(func(v: float):
			_meas_height_label.text = "%.1f cm" % v
			_update_mini_avatar(v)
		, prev_h, h, 1.4)
	else:
		tween.tween_interval(0.25)

	# 前回比ポップアップ
	tween.tween_property(_meas_diff_label, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(_meas_diff_label, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(_meas_diff_label, "scale", Vector2(1.0, 1.0), 0.1)

	# 詳細とボタンをフェードイン
	tween.tween_interval(0.2)
	tween.tween_property(measurement_content_label, "modulate:a", 1.0, 0.4)
	tween.tween_property(_meas_btn_row, "modulate:a", 1.0, 0.3)

func _reset_measurement_content_scroll() -> void:
	if not is_instance_valid(measurement_content_scroll):
		return
	measurement_content_scroll.set_deferred("scroll_vertical", 0)
	measurement_content_scroll.set_deferred("scroll_horizontal", 0)

func _on_close_measurement_pressed() -> void:
	_measurement_showing = false
	measurement_panel.hide()
	get_tree().paused = false
	_nearby_height_scale = false
	var global = get_node_or_null("/root/Global")
	var should_return_to_myroom := _measurement_returns_to_myroom
	_measurement_returns_to_myroom = false
	if should_return_to_myroom:
		if global:
			global.current_stage_id = "myroom"
		if player and player.has_method("update_measurements"):
			player.call("update_measurements")
		_load_stage()
		return
	if global and global.haruka_following:
		global.haruka_following = false
		_start_dialogue("haruka", "measure_after")

func _on_measurement_panel_closed() -> void:
	_on_close_measurement_pressed()
	return
	_measurement_showing = false
	measurement_panel.hide()
	get_tree().paused = false
	# はるかが追随中なら測定後セリフを再生
	var global = get_node_or_null("/root/Global")
	if global and global.haruka_following:
		global.haruka_following = false
		_start_dialogue("haruka", "measure_after")

func _on_next_term_pressed() -> void:
	_on_close_measurement_pressed()
	return
	_measurement_showing = false
	measurement_panel.hide()
	get_tree().paused = false
	_nearby_height_scale = false

	# フェードオーバーレイを生成
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.z_index = 100
	ui_layer.add_child(fade)

	# フェードアウト（0.5秒）
	var tw = create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.5)
	await tw.finished

	# 学期を進めて自室へ
	var global = get_node_or_null("/root/Global")
	if global:
		global.advance_term()
		global.current_stage_id = "myroom"

	if player:
		player.update_measurements()

	_load_stage()

	# 黒画面中に学期テキストを表示
	if global:
		var lbl = Label.new()
		lbl.text = Global.get_school_term_label(int(global.age), int(global.term))
		lbl.add_theme_font_size_override("font_size", 36)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
		lbl.modulate.a = 0.0
		lbl.set_anchors_preset(Control.PRESET_CENTER)
		lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
		lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
		fade.add_child(lbl)
		var tw_lbl = create_tween()
		tw_lbl.tween_property(lbl, "modulate:a", 1.0, 0.3)
		tw_lbl.tween_interval(0.5)
		tw_lbl.tween_property(lbl, "modulate:a", 0.0, 0.3)

	# フェードイン（0.8秒）
	var tw2 = create_tween()
	tw2.tween_property(fade, "color:a", 0.0, 0.8)
	await tw2.finished
	fade.queue_free()

	# 少し歩き込んでから主人公モノローグ（入学年は入学式セリフ）
	await get_tree().create_timer(1.8).timeout
	var mono_key = "new_semester"
	if global:
		mono_key = _get_term_intro_dialogue_key(int(global.age), int(global.term))
	_start_dialogue("player", mono_key)

func _setup_achievement_popup() -> void:
	var global = get_node_or_null("/root/Global")
	if not global:
		return

	achievement_popup = Control.new()
	achievement_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievement_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchor(SIDE_LEFT, 1.0)
	panel.set_anchor(SIDE_TOP, 1.0)
	panel.set_anchor(SIDE_RIGHT, 1.0)
	panel.set_anchor(SIDE_BOTTOM, 1.0)
	panel.offset_left = -288
	panel.offset_top = -76
	panel.offset_right = -12
	panel.offset_bottom = -12
	panel.modulate.a = 0.0

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.92)
	style.border_width_left = 3
	style.border_color = Color(0.8, 0.7, 0.3)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var icon_label = Label.new()
	icon_label.name = "IconLabel"
	icon_label.text = "★"
	icon_label.add_theme_font_size_override("font_size", 20)
	icon_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	hbox.add_child(icon_label)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "実績解除！"
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
	vbox.add_child(title_label)

	_ach_name_label = Label.new()
	_ach_name_label.add_theme_font_size_override("font_size", 14)
	_ach_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(_ach_name_label)

	_ach_popup_panel = panel
	achievement_popup.add_child(panel)
	ui_layer.add_child(achievement_popup)

	global.achievement_unlocked.connect(_on_achievement_unlocked)
	# ロード直後に既存実績を再チェック（旧セーブデータ対応）
	global._check_all_achievements()

func _on_achievement_unlocked(id: String) -> void:
	_ach_popup_queue.append(id)
	if not _ach_popup_showing:
		_show_next_achievement_popup()

func _show_next_achievement_popup() -> void:
	if _ach_popup_queue.is_empty():
		_ach_popup_showing = false
		return
	_ach_popup_showing = true
	var id: String = _ach_popup_queue.pop_front()
	const AchDB = preload("res://scripts/AchievementDatabase.gd")
	if not AchDB.ACHIEVEMENTS.has(id):
		_show_next_achievement_popup()
		return
	var def: Dictionary = AchDB.ACHIEVEMENTS[id]
	if not _ach_name_label or not is_instance_valid(_ach_name_label):
		_ach_popup_showing = false
		return
	_ach_name_label.text = String(def.get("name", ""))

	if not _ach_popup_panel or not is_instance_valid(_ach_popup_panel):
		_ach_popup_showing = false
		return
	var tween = create_tween()
	tween.tween_property(_ach_popup_panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.3)
	tween.tween_property(_ach_popup_panel, "modulate:a", 0.0, 0.3)
	tween.finished.connect(_show_next_achievement_popup, CONNECT_ONE_SHOT)

func _open_achievement_viewer() -> void:
	if achievement_viewer and is_instance_valid(achievement_viewer):
		_refresh_achievement_viewer()
		achievement_viewer.show()
		get_tree().paused = true
		return
	_setup_achievement_viewer()
	achievement_viewer.show()
	get_tree().paused = true

func _setup_achievement_viewer() -> void:
	achievement_viewer = ColorRect.new()
	(achievement_viewer as ColorRect).color = Color(0, 0, 0, 0.75)
	achievement_viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievement_viewer.hide()
	achievement_viewer.process_mode = Node.PROCESS_MODE_ALWAYS

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievement_viewer.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 480)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.35, 0.2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "実績一覧"
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.82, 0.5))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 380)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var grid = VBoxContainer.new()
	grid.name = "AchGrid"
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("separation", 6)
	scroll.add_child(grid)

	var close_hint = Label.new()
	close_hint.text = "[ESC] 閉じる"
	close_hint.add_theme_font_size_override("font_size", 12)
	close_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(close_hint)

	ui_layer.add_child(achievement_viewer)
	_refresh_achievement_viewer()

func _refresh_achievement_viewer() -> void:
	if not achievement_viewer:
		return
	var grid = achievement_viewer.find_child("AchGrid", true, false)
	if not grid:
		return
	for child in grid.get_children():
		child.queue_free()

	var global = get_node_or_null("/root/Global")
	if not global:
		return
	const AchDB = preload("res://scripts/AchievementDatabase.gd")

	for id in AchDB.ACHIEVEMENTS:
		var def: Dictionary = AchDB.ACHIEVEMENTS[id]
		var unlocked: bool = id in global.achievements_unlocked

		var row = PanelContainer.new()
		var row_style = StyleBoxFlat.new()
		if unlocked:
			row_style.bg_color = Color(0.18, 0.22, 0.18, 0.9)
			row_style.border_color = Color(0.3, 0.5, 0.3)
		else:
			row_style.bg_color = Color(0.15, 0.15, 0.15, 0.6)
			row_style.border_color = Color(0.3, 0.3, 0.3)
		row_style.border_width_left = 2
		row_style.content_margin_left = 10
		row_style.content_margin_right = 10
		row_style.content_margin_top = 6
		row_style.content_margin_bottom = 6
		row_style.corner_radius_top_left = 4
		row_style.corner_radius_top_right = 4
		row_style.corner_radius_bottom_left = 4
		row_style.corner_radius_bottom_right = 4
		row.add_theme_stylebox_override("panel", row_style)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(row)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		row.add_child(hbox)

		var icon_lbl = Label.new()
		icon_lbl.text = "★" if unlocked else "…"
		icon_lbl.add_theme_font_size_override("font_size", 16)
		icon_lbl.add_theme_color_override("font_color",
			Color(0.9, 0.75, 0.2) if unlocked else Color(0.4, 0.4, 0.4))
		icon_lbl.custom_minimum_size = Vector2(22, 0)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(icon_lbl)

		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(text_vbox)

		var name_lbl = Label.new()
		name_lbl.text = String(def.get("name", ""))
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color",
			Color(1.0, 1.0, 1.0) if unlocked else Color(0.6, 0.6, 0.6))
		text_vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = String(def.get("desc", "")) if unlocked else "???"
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color",
			Color(0.7, 0.7, 0.7) if unlocked else Color(0.4, 0.4, 0.4))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_vbox.add_child(desc_lbl)

func _setup_history_panel() -> void:
	if history_panel:
		return

	history_panel = ColorRect.new()
	history_panel.color = Color(0, 0, 0, 0.72)
	history_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	history_panel.hide()
	history_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	history_panel.add_child(center)

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#16202c")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "成長記録"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	history_header_label = Label.new()
	history_header_label.add_theme_font_size_override("font_size", 15)
	history_header_label.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	history_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(history_header_label)

	# 折れ線グラフ
	var GrowthGraphScript = load("res://scripts/GrowthGraph.gd")
	growth_graph = GrowthGraphScript.new()
	growth_graph.custom_minimum_size = Vector2(560, 300)
	vbox.add_child(growth_graph)

	var close_hint = Label.new()
	close_hint.text = "[G] で閉じる"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.add_theme_font_size_override("font_size", 14)
	close_hint.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	vbox.add_child(close_hint)

	ui_layer.add_child(history_panel)

func _toggle_history_panel() -> void:
	if not history_panel:
		_setup_history_panel()

	if history_panel.visible:
		history_panel.hide()
		get_tree().paused = false
		return

	var global = get_node_or_null("/root/Global")
	if not global:
		return

	history_header_label.text = "現在 %.1fcm  /  %d歳  /  %s" % [
		float(global.current_params["height"]),
		int(global.age),
		Global.get_school_term_label(int(global.age), int(global.term))
	]
	growth_graph.set_data(global.growth_history)

	history_panel.show()
	get_tree().paused = true
