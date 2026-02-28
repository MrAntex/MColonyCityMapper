extends PanelContainer

## Sidebar — scrollable building list grouped by category/subcategory.
## Emits building_picked(id) when the user clicks a building row.

signal building_picked(building_id: String)

# ── Colors ────────────────────────────────────────────────────────────────────
const COLOR_BG           := Color(0.12, 0.13, 0.15, 1.0)
const COLOR_CAT_HEADER   := Color(0.16, 0.18, 0.22, 1.0)
const COLOR_SUBCAT_BG    := Color(0.14, 0.15, 0.18, 1.0)
const COLOR_ROW_NORMAL   := Color(0.12, 0.13, 0.15, 1.0)
const COLOR_ROW_HOVER    := Color(0.22, 0.26, 0.34, 1.0)
const COLOR_ROW_SELECTED := Color(0.18, 0.35, 0.55, 1.0)
const COLOR_TEXT         := Color(0.88, 0.90, 0.92, 1.0)
const COLOR_TEXT_DIM     := Color(0.50, 0.54, 0.60, 1.0)
const COLOR_TEXT_CAT     := Color(0.60, 0.75, 1.00, 1.0)
const COLOR_TEXT_SUBCAT  := Color(0.45, 0.52, 0.65, 1.0)

var _active_row : Control = null   # currently highlighted building row

func _ready() -> void:
	# Own background
	var bg := StyleBoxFlat.new()
	bg.bg_color = COLOR_BG
	bg.set_content_margin_all(0)
	add_theme_stylebox_override("panel", bg)

	_build_ui()

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 0)
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	add_child(root_vbox)

	# ── Header ────────────────────────────────────────────────────────────────
	root_vbox.add_child(_make_header())

	# ── Scroll area ───────────────────────────────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)
	scroll.add_child(list)

	# ── Categories ────────────────────────────────────────────────────────────
	var sorted_cats : Array = BuildingDB.categories.keys()
	sorted_cats.sort()

	for cat in sorted_cats:
		var subcats : Dictionary = BuildingDB.categories[cat]
		var sorted_subs : Array  = subcats.keys()
		sorted_subs.sort()

		list.add_child(_make_category_header(cat))

		for subcat in sorted_subs:
			var ids : Array = subcats[subcat]
			if subcat != "":
				list.add_child(_make_subcat_label(subcat))
			for bid in ids:
				list.add_child(_make_building_row(bid, subcat != ""))

	# ── Footer hint ───────────────────────────────────────────────────────────
	root_vbox.add_child(_make_footer())

# ── Widget factories ──────────────────────────────────────────────────────────

func _make_header() -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.12, 1.0)
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   12)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_right",  12)
	margin.add_theme_constant_override("margin_bottom",  8)
	panel.add_child(margin)

	var lbl := Label.new()
	lbl.text = "BUILDINGS"
	lbl.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
	lbl.add_theme_font_size_override("font_size", 13)
	margin.add_child(lbl)
	return panel

func _make_footer() -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.12, 1.0)
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_top",     6)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_bottom",  6)
	panel.add_child(margin)

	var lbl := Label.new()
	lbl.text = "LMB place · R rotate · RMB cancel · DEL delete"
	lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(lbl)
	return panel

func _make_category_header(cat: String) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_CAT_HEADER
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_top",     6)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_bottom",  6)
	panel.add_child(margin)

	var lbl := Label.new()
	lbl.text = cat.to_upper()
	lbl.add_theme_color_override("font_color", COLOR_TEXT_CAT)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(lbl)
	return panel

func _make_subcat_label(subcat: String) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SUBCAT_BG
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   16)
	margin.add_theme_constant_override("margin_top",     3)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_bottom",  3)
	panel.add_child(margin)

	var lbl := Label.new()
	lbl.text = "› " + subcat
	lbl.add_theme_color_override("font_color", COLOR_TEXT_SUBCAT)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(lbl)
	return panel

func _make_building_row(bid: String, indented: bool) -> Control:
	var bdef : Dictionary = BuildingDB.get_building(bid)

	# Clickable container
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_set_row_style(panel, COLOR_ROW_NORMAL)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   20 if indented else 12)
	margin.add_theme_constant_override("margin_top",     5)
	margin.add_theme_constant_override("margin_right",   8)
	margin.add_theme_constant_override("margin_bottom",  5)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 7)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	# Color swatch
	var swatch := ColorRect.new()
	swatch.color = BuildingDB.get_color(bid)
	swatch.custom_minimum_size = Vector2(10, 10)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(swatch)

	# Building name
	var name_lbl := Label.new()
	name_lbl.text = bdef.get("name", bid)
	name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_lbl)

	# Size
	var sz : Vector2i = BuildingDB.get_size(bid)
	var size_lbl := Label.new()
	size_lbl.text = "%dx%d" % [sz.x, sz.y]
	size_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	size_lbl.add_theme_font_size_override("font_size", 9)
	size_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	size_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(size_lbl)

	# Tooltip
	panel.tooltip_text = bdef.get("description", "")

	# Hover + click via gui_input
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				_select_row(panel, bid)
	)
	panel.mouse_entered.connect(func() -> void:
		if panel != _active_row:
			_set_row_style(panel, COLOR_ROW_HOVER)
	)
	panel.mouse_exited.connect(func() -> void:
		if panel != _active_row:
			_set_row_style(panel, COLOR_ROW_NORMAL)
	)

	return panel

# ── Selection ─────────────────────────────────────────────────────────────────

func _select_row(panel: Control, bid: String) -> void:
	if _active_row != null and is_instance_valid(_active_row):
		_set_row_style(_active_row, COLOR_ROW_NORMAL)
	_active_row = panel
	_set_row_style(panel, COLOR_ROW_SELECTED)
	building_picked.emit(bid)

func deselect_active() -> void:
	if _active_row != null and is_instance_valid(_active_row):
		_set_row_style(_active_row, COLOR_ROW_NORMAL)
		_active_row = null

# ── Helpers ───────────────────────────────────────────────────────────────────

func _set_row_style(panel: Control, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
