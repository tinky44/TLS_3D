extends Control
## 成長記録の折れ線グラフ描画
## set_data(growth_history) を呼んで queue_redraw() で更新する

var data: Array = []

const ML: float = 52.0  # margin left
const MT: float = 16.0  # margin top
const MR: float = 16.0  # margin right
const MB: float = 28.0  # margin bottom

func set_data(history: Array) -> void:
	data = history
	queue_redraw()

func _get_pt(i: int, key: String, min_h: float, h_range: float, gw: float, gh: float) -> Vector2:
	var n: int = data.size()
	var x: float = ML + gw * float(i) / float(maxi(n - 1, 1))
	var h: float = float(data[i].get(key, min_h))
	var yn: float = clampf((h - min_h) / maxf(h_range, 1.0), 0.0, 1.0)
	var y: float = MT + gh * (1.0 - yn)
	return Vector2(x, y)

func _draw() -> void:
	var gw: float = size.x - ML - MR
	var gh: float = size.y - MT - MB
	var font: Font = ThemeDB.fallback_font
	var font_size_sm: int = 11
	var font_size_md: int = 12

	if data.is_empty():
		draw_string(font, Vector2(ML + gw * 0.5, MT + gh * 0.5),
			"まだ記録がありません", HORIZONTAL_ALIGNMENT_CENTER, gw, 14, Color.WHITE)
		return

	# ─── データ範囲 ───
	var min_h: float = INF
	var max_h: float = -INF
	for entry in data:
		min_h = minf(min_h, float(entry.get("height",     100.0)))
		min_h = minf(min_h, float(entry.get("avg_height", 100.0)))
		max_h = maxf(max_h, float(entry.get("height",     200.0)))
		max_h = maxf(max_h, float(entry.get("avg_height", 200.0)))
	var h_range: float = maxf(max_h - min_h, 10.0)
	min_h = maxf(min_h - h_range * 0.12, 50.0)
	max_h = max_h + h_range * 0.12
	h_range = max_h - min_h

	var n: int = data.size()
	var grid_col  := Color(0.28, 0.33, 0.42, 0.55)
	var axis_col  := Color(0.50, 0.55, 0.65, 1.0)
	var player_col := Color(0.35, 0.78, 1.00)
	var avg_col   := Color(1.00, 0.65, 0.20, 0.80)
	var label_col := Color(0.65, 0.70, 0.82)

	# ─── グリッド & Y軸ラベル ───
	for i in range(5):
		var yn: float = float(i) / 4.0
		var y: float = MT + gh * (1.0 - yn)
		var h_val: float = min_h + h_range * yn
		draw_line(Vector2(ML, y), Vector2(ML + gw, y), grid_col, 1.0)
		draw_string(font, Vector2(2.0, y + 5.0), "%.0fcm" % h_val,
			HORIZONTAL_ALIGNMENT_LEFT, ML - 4.0, font_size_sm, label_col)

	# ─── 軸 ───
	draw_line(Vector2(ML, MT), Vector2(ML, MT + gh), axis_col, 1.5)
	draw_line(Vector2(ML, MT + gh), Vector2(ML + gw, MT + gh), axis_col, 1.5)

	# ─── 平均線（オレンジ破線）───
	if n > 1:
		for i in range(n - 1):
			var p1: Vector2 = _get_pt(i,     "avg_height", min_h, h_range, gw, gh)
			var p2: Vector2 = _get_pt(i + 1, "avg_height", min_h, h_range, gw, gh)
			draw_dashed_line(p1, p2, avg_col, 1.5, 8.0)

	# ─── プレイヤー線（青）───
	if n > 1:
		for i in range(n - 1):
			var p1: Vector2 = _get_pt(i,     "height", min_h, h_range, gw, gh)
			var p2: Vector2 = _get_pt(i + 1, "height", min_h, h_range, gw, gh)
			draw_line(p1, p2, player_col, 2.0)

	# ─── ドット & X軸ラベル ───
	for i in range(n):
		var pt: Vector2 = _get_pt(i, "height", min_h, h_range, gw, gh)
		draw_circle(pt, 3.5, player_col)
		if i == 0 or i == n - 1 or i % 3 == 0:
			var a: int = int(data[i].get("age", 0))
			draw_string(font, Vector2(pt.x - 12.0, MT + gh + 14.0),
				"%d歳" % a, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_sm, label_col)

	# ─── 凡例 ───
	var lx: float = ML + gw - 108.0
	var ly: float = MT + 8.0
	draw_line(Vector2(lx, ly), Vector2(lx + 18.0, ly), player_col, 2.0)
	draw_circle(Vector2(lx + 9.0, ly), 3.0, player_col)
	draw_string(font, Vector2(lx + 23.0, ly + 5.0), "身長",
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_md, player_col)
	draw_dashed_line(Vector2(lx, ly + 18.0), Vector2(lx + 18.0, ly + 18.0), avg_col, 1.5, 8.0)
	draw_string(font, Vector2(lx + 23.0, ly + 23.0), "同学年平均",
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_md, avg_col)
