extends Node

# 実績定義
# trigger 種別:
#   "height"      - current_params["height"] >= value
#   "age"         - age >= value
#   "story_flag"  - story_flags[key] == true
#   "experienced" - key in experienced_events
#   "bool_var"    - Global.get(key) == true
#   "vball_phase" - vball_story_phase >= phase
#   "met_npc"     - key in met_npcs

const ACHIEVEMENTS: Dictionary = {

	# ===== 身長マイルストーン =====
	"height_180": {
		"name": "180cmの壁",
		"desc": "身長が180cmを超えた。",
		"icon": "ruler",
		"trigger": "height",
		"value": 180,
	},
	"height_200": {
		"name": "200cmの扉",
		"desc": "身長が200cmを超えた。",
		"icon": "ruler",
		"trigger": "height",
		"value": 200,
	},
	"height_230": {
		"name": "どこまで大きく...",
		"desc": "身長が230cmを超えた。",
		"icon": "ruler",
		"trigger": "height",
		"value": 230,
	},
	"height_250": {
		"name": "天井を見下ろして",
		"desc": "身長が250cmを超えた。",
		"icon": "ruler",
		"trigger": "height",
		"value": 250,
	},
	"height_270": {
		"name": "ギネス記録...?",
		"desc": "身長が270cmを超えた。",
		"icon": "ruler",
		"trigger": "height",
		"value": 270,
	},
	"height_300": {
		"name": "3メートル",
		"desc": "身長が300cmを超えた。",
		"icon": "ruler",
		"trigger": "height",
		"value": 300,
	},

	# ===== 学年マイルストーン =====
	"entrance_elem": {
		"name": "小学生になった",
		"desc": "小学校の入学式を迎えた。",
		"icon": "school",
		"trigger": "age",
		"value": 6,
	},
	"elem_grade4": {
		"name": "もう高学年",
		"desc": "小学4年生まで成長した。",
		"icon": "school",
		"trigger": "age",
		"value": 9,
	},
	"entrance_middle": {
		"name": "中学生になった",
		"desc": "中学校の入学式を迎えた。",
		"icon": "school",
		"trigger": "age",
		"value": 12,
	},
	"entrance_high": {
		"name": "高校生になった",
		"desc": "高校の入学式を迎えた。",
		"icon": "school",
		"trigger": "age",
		"value": 15,
	},

	# ===== 成長イベント =====
	"summer_growth_ach": {
		"name": "夏休みの成長",
		"desc": "夏休みの間に大きく伸びた。",
		"icon": "arrow_up",
		"trigger": "experienced",
		"key": "summer_growth",
	},
	"growth_spurt_ach": {
		"name": "成長期",
		"desc": "急に背が伸びた。",
		"icon": "arrow_up",
		"trigger": "experienced",
		"key": "growth_spurt",
	},

	# ===== ストーリーフラグ =====
	"randoseru_farewell": {
		"name": "ランドセルとの別れ",
		"desc": "もう入らないランドセルを見つめた。",
		"icon": "book",
		"trigger": "story_flag",
		"key": "randoseru_farewell_done",
	},
	"middle_boys_growth": {
		"name": "俺、5cm伸びた",
		"desc": "廊下で男子の成長自慢を聞いた。",
		"icon": "arrow_up",
		"trigger": "story_flag",
		"key": "middle_boys_growth_talk_done",
	},
	"high_scout_ach": {
		"name": "スカウト",
		"desc": "スポーツクラブから勧誘を受けた。",
		"icon": "star",
		"trigger": "story_flag",
		"key": "high_scout_done",
	},
	"bookshelf_found": {
		"name": "本の虫",
		"desc": "自室の本棚を調べた。",
		"icon": "book",
		"trigger": "story_flag",
		"key": "bookshelf_checked",
	},

	# ===== 出会い =====
	"meet_haruka": {
		"name": "親友",
		"desc": "クラスメートのはるかに声をかけてもらった。",
		"icon": "heart",
		"trigger": "met_npc",
		"key": "haruka",
	},
	"meet_senior": {
		"name": "先輩",
		"desc": "廊下でバレー部の先輩に声をかけられた。",
		"icon": "volleyball",
		"trigger": "vball_phase",
		"phase": 1,
	},

	# ===== バレー部 =====
	"join_volleyball": {
		"name": "ネットの向こうへ",
		"desc": "バレー部に参加した。",
		"icon": "volleyball",
		"trigger": "bool_var",
		"key": "vball_joined",
	},
	"vball_pain_ach": {
		"name": "膝がミシミシ",
		"desc": "バレー部の練習中、脚が痛み始めた。",
		"icon": "heart",
		"trigger": "vball_phase",
		"phase": 3,
	},
}
