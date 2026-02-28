extends PanelContainer

## Inspector — shown at the bottom of the screen when a building is selected.
## Allows editing the instance label and managing assigned colonists.

signal move_requested()
signal delete_requested()

# ── Colors ────────────────────────────────────────────────────────────────────
const COLOR_BG          := Color(0.10, 0.11, 0.14, 0.97)
const COLOR_SECTION_BG  := Color(0.14, 0.16, 0.20, 1.00)
const COLOR_INPUT_BG    := Color(0.08, 0.09, 0.11, 1.00)
const COLOR_BTN_MOVE    := Color(0.20, 0.45, 0.25, 1.00)
const COLOR_BTN_DELETE  := Color(0.50, 0.15, 0.15, 1.00)
const COLOR_BTN_ADD     := Color(0.18, 0.30, 0.50, 1.00)
const COLOR_BTN_HOVER   := Color(0.30, 0.55, 0.35, 1.00)
const COLOR_TEXT        := Color(0.88, 0.90, 0.92, 1.00)
const COLOR_TEXT_DIM    := Color(0.50, 0.54, 0.60, 1.00)
const COLOR_TEXT_ACCENT := Color(0.50, 0.75, 1.00, 1.00)
const COLOR_COLONIST_BG := Color(0.16, 0.18, 0.23, 1.00)
const COLOR_REMOVE_BTN  := Color(0.45, 0.15, 0.15, 1.00)

# ── State ─────────────────────────────────────────────────────────────────────
var _current_building : Node2D = null

# UI refs populated in _build_ui
var _title_label      : Label
var _info_label       : Label
var _label_input      : LineEdit
var _colonists_list   : VBoxContainer
var _add_name_input   : LineEdit

func _ready() -> void:
	# Background style
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.set_corner_radius_all(0)
	style.set_content_margin_all(0)
	add_theme_stylebox_override("panel", style)

	_build_ui()
	hide()

# ── Public API ────────────────────────────────────────────────────────────────

func inspect(building_node: Node2D) -> void:
	_current_building = building_node
	_refresh()
	show()

func close() -> void:
	_current_building = null
	hide()

# ── UI Construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(root)

	# Section 1 — Building identity
	root.add_child(_make_identity_section())
	root.add_child(_make_vsep())

	# Section 2 — Custom label
	root.add_child(_make_label_section())
	root.add_child(_make_vsep())

	# Section 3 — Colonists
	root.add_child(_make_colonists_section())
	root.add_child(_make_vsep())

	# Section 4 — Actions
	root.add_child(_make_actions_section())

func _make_identity_section() -> Control:
	var panel := _section_panel(200)
	var vbox  := _section_vbox(panel)

	_title_label = Label.new()
	_title_label.add_theme_color_override("font_color", COLOR_TEXT_ACCENT)
	_title_label.add_theme_font_size_override("font_size", 13)
	_title_label.clip_contents = true
	vbox.add_child(_title_label)

	_info_label = Label.new()
	_info_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	_info_label.add_theme_font_size_override("font_size", 10)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_info_label)

	return panel

func _make_label_section() -> Control:
	var panel := _section_panel(200)
	var vbox  := _section_vbox(panel)

	var heading := _make_heading("CUSTOM LABEL")
	vbox.add_child(heading)

	_label_input = LineEdit.new()
	_label_input.placeholder_text = "e.g. Main Farm, North Tower…"
	_label_input.add_theme_color_override("font_color", COLOR_TEXT)
	_label_input.add_theme_font_size_override("font_size", 11)
	_style_input(_label_input)
	vbox.add_child(_label_input)

	_label_input.text_submitted.connect(func(_t: String) -> void: _apply_label())
	_label_input.focus_exited.connect(_apply_label)

	return panel

func _make_colonists_section() -> Control:
	var panel := _section_panel(0, true)   # expand to fill
	var vbox  := _section_vbox(panel)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(top_hbox)

	var heading := _make_heading("COLONISTS")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(heading)

	# Add colonist row: input + button
	_add_name_input = LineEdit.new()
	_add_name_input.placeholder_text = "Name…"
	_add_name_input.custom_minimum_size = Vector2(110, 0)
	_add_name_input.add_theme_color_override("font_color", COLOR_TEXT)
	_add_name_input.add_theme_font_size_override("font_size", 10)
	_style_input(_add_name_input)
	top_hbox.add_child(_add_name_input)

	var add_btn := _make_text_button("+ Add", COLOR_BTN_ADD, 10)
	add_btn.pressed.connect(_on_add_colonist_pressed)
	_add_name_input.text_submitted.connect(func(_t: String) -> void: _on_add_colonist_pressed())
	top_hbox.add_child(add_btn)

	# Scrollable colonist list
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(scroll)

	_colonists_list = VBoxContainer.new()
	_colonists_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_colonists_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_colonists_list)

	return panel

func _make_actions_section() -> Control:
	var panel := _section_panel(130)
	var vbox  := _section_vbox(panel)
	vbox.add_theme_constant_override("separation", 6)

	var move_btn := _make_text_button("✥  Move", COLOR_BTN_MOVE, 11)
	move_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	move_btn.pressed.connect(func() -> void: move_requested.emit())
	vbox.add_child(move_btn)

	var del_btn := _make_text_button("✕  Delete", COLOR_BTN_DELETE, 11)
	del_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	del_btn.pressed.connect(func() -> void: delete_requested.emit())
	vbox.add_child(del_btn)

	return panel

# ── Data refresh ──────────────────────────────────────────────────────────────

func _refresh() -> void:
	if _current_building == null:
		return

	var bid  : String     = _current_building.building_id
	var bdef : Dictionary = BuildingDB.get_building(bid)
	var sz   := BuildingDB.get_size(bid)
	var rot  : int = _current_building.rotation_index
	const ROT_LABELS := ["0°", "90°", "180°", "270°"]

	_title_label.text = bdef.get("name", bid)
	_info_label.text  = "%s\n%dx%d blocks · rot %s\nPos (%d, %d)" % [
		bdef.get("category", ""),
		sz.x, sz.y,
		ROT_LABELS[rot],
		_current_building.grid_pos.x,
		_current_building.grid_pos.y
	]

	_label_input.text = _current_building.instance_label
	_rebuild_colonists_list()

func _rebuild_colonists_list() -> void:
	for child in _colonists_list.get_children():
		child.queue_free()

	if _current_building == null:
		return

	# Ensure colonists array exists on the building node
	if not "colonists" in _current_building:
		_current_building.set_meta("colonists", [])

	var colonists : Array = _current_building.get_meta("colonists", [])
	for i in colonists.size():
		_colonists_list.add_child(_make_colonist_row(colonists[i], i))

	if colonists.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No colonists assigned"
		empty_lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		empty_lbl.add_theme_font_size_override("font_size", 10)
		_colonists_list.add_child(empty_lbl)

func _make_colonist_row(name: String, index: int) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)

	var bg := PanelContainer.new()
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_COLONIST_BG
	style.set_content_margin(SIDE_LEFT, 6)
	style.set_content_margin(SIDE_RIGHT, 4)
	style.set_content_margin(SIDE_TOP, 2)
	style.set_content_margin(SIDE_BOTTOM, 2)
	bg.add_theme_stylebox_override("panel", style)

	var row_hbox := HBoxContainer.new()
	row_hbox.add_theme_constant_override("separation", 4)
	bg.add_child(row_hbox)

	var lbl := Label.new()
	lbl.text = name
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", COLOR_TEXT)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_hbox.add_child(lbl)

	var remove_btn := _make_text_button("✕", COLOR_REMOVE_BTN, 9)
	remove_btn.custom_minimum_size = Vector2(20, 0)
	remove_btn.pressed.connect(func() -> void: _remove_colonist(index))
	row_hbox.add_child(remove_btn)

	return bg

# ── Event handlers ────────────────────────────────────────────────────────────

func _apply_label() -> void:
	if _current_building == null:
		return
	_current_building.instance_label = _label_input.text.strip_edges()
	_current_building.queue_redraw()

func _on_add_colonist_pressed() -> void:
	if _current_building == null:
		return
	var name := _add_name_input.text.strip_edges()
	if name == "":
		return
	var colonists : Array = _current_building.get_meta("colonists", [])
	colonists.append(name)
	_current_building.set_meta("colonists", colonists)
	_add_name_input.text = ""
	_rebuild_colonists_list()

func _remove_colonist(index: int) -> void:
	if _current_building == null:
		return
	var colonists : Array = _current_building.get_meta("colonists", [])
	colonists.remove_at(index)
	_current_building.set_meta("colonists", colonists)
	_rebuild_colonists_list()

# ── Style helpers ─────────────────────────────────────────────────────────────

func _section_panel(min_width: int, expand: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SECTION_BG
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	if min_width > 0:
		panel.custom_minimum_size = Vector2(min_width, 0)
	if expand:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return panel

func _section_vbox(parent: Control) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  10)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	parent.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	return vbox

func _make_vsep() -> Control:
	var sep := VSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.22, 0.28, 1.0)
	style.set_content_margin_all(0)
	sep.add_theme_stylebox_override("separator", style)
	return sep

func _make_heading(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	lbl.add_theme_font_size_override("font_size", 9)
	return lbl

func _make_text_button(text: String, bg_color: Color, font_size: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_font_size_override("font_size", font_size)
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(3)
	style.set_content_margin(SIDE_LEFT,  8)
	style.set_content_margin(SIDE_RIGHT, 8)
	style.set_content_margin(SIDE_TOP,   4)
	style.set_content_margin(SIDE_BOTTOM,4)
	btn.add_theme_stylebox_override("normal",  style)
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover",   hover_style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	return btn

func _style_input(input: LineEdit) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_INPUT_BG
	style.set_corner_radius_all(3)
	style.set_content_margin(SIDE_LEFT,   6)
	style.set_content_margin(SIDE_RIGHT,  6)
	style.set_content_margin(SIDE_TOP,    4)
	style.set_content_margin(SIDE_BOTTOM, 4)
	input.add_theme_stylebox_override("normal", style)
	input.add_theme_stylebox_override("focus",  style)
