extends Node2D

## Represents a single placed building on the map.
## Handles its own drawing (footprint, entrance marker, label, selection ring).
## rotation_index: 0=0° 1=90°CW 2=180° 3=270°CW

const BLOCK_SIZE := 16  # must match grid.gd

# ── Data ──────────────────────────────────────────────────────────────────────
var building_id    : String     = ""
var grid_pos       : Vector2i   = Vector2i.ZERO   # top-left corner in block coords
var building_def   : Dictionary = {}
var instance_label : String     = ""
var rotation_index : int        = 0               # 0..3
var is_selected    : bool       = false : set = _set_selected

# ── Colors ────────────────────────────────────────────────────────────────────
const COLOR_FILL_ALPHA   := 0.45
const COLOR_BORDER_ALPHA := 0.9
const COLOR_SELECTED     := Color(1.0, 1.0, 1.0, 0.9)
const COLOR_ENTRANCE     := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_LABEL_BG     := Color(0.0, 0.0, 0.0, 0.55)
const COLOR_LABEL_TEXT   := Color(1.0, 1.0, 1.0, 1.0)

var current_zoom : float = 1.0

func _set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()

## Call this after setting building_id and grid_pos.
func setup(bid: String, gpos: Vector2i) -> void:
	building_id  = bid
	grid_pos     = gpos
	building_def = BuildingDB.get_building(bid)
	position     = Vector2(gpos) * BLOCK_SIZE
	queue_redraw()

## Returns the bounding rect in block coords, accounting for rotation.
func get_rect_blocks() -> Rect2i:
	var sz := _rotated_size()
	return Rect2i(grid_pos, sz)

## Rotated size: x and z swap on 90/270.
func _rotated_size() -> Vector2i:
	var sz : Vector2i = BuildingDB.get_size(building_id)
	if rotation_index % 2 == 1:
		return Vector2i(sz.y, sz.x)
	return sz

## Rotates the entrance side by rotation_index steps clockwise.
## Order: north → east → south → west → north
func _rotated_entrance() -> Dictionary:
	var entrance : Dictionary = BuildingDB.get_entrance(building_id)
	if entrance.is_empty():
		return {}
	const SIDES := ["north", "east", "south", "west"]
	var base_side   : String = entrance.get("side", "south")
	var base_offset : int    = entrance.get("offset", 0)
	var base_sz     : Vector2i = BuildingDB.get_size(building_id)

	var idx := SIDES.find(base_side)
	var new_idx := (idx + rotation_index) % 4
	var new_side : String = SIDES[new_idx]

	# When rotating, the offset maps to a new axis.
	# For a building of size (W, H):
	#   north/south offset counts from west edge → range [0, W-1]
	#   east/west   offset counts from north edge → range [0, H-1]
	# After 90° CW rotation: what was the top (north) becomes the right (east),
	# and the offset along the top (x) becomes an offset down the right side (z).
	# The formula below tracks how the offset transforms through each 90° step.
	var off := base_offset
	var w   : int = base_sz.x
	var h   : int = base_sz.y
	for _i in range(rotation_index):
		# Current side dimension before this rotation step
		var cur_side : String = SIDES[(SIDES.find(base_side) + _i) % 4]
		var dim := w if (cur_side == "north" or cur_side == "south") else h
		off = (dim - 1) - off
		# Swap w and h for next step
		var tmp := w; w = h; h = tmp

	return { "side": new_side, "offset": off }

func _draw() -> void:
	if building_def.is_empty():
		return

	var sz   := _rotated_size()
	var px_w := sz.x * BLOCK_SIZE
	var px_h := sz.y * BLOCK_SIZE
	var lw   := 1.5 / current_zoom
	var base_color : Color = BuildingDB.get_color(building_id)

	# ── Fill ──────────────────────────────────────────────────────────────────
	var fill := base_color
	fill.a = COLOR_FILL_ALPHA
	draw_rect(Rect2(0, 0, px_w, px_h), fill)

	# ── Border ────────────────────────────────────────────────────────────────
	var border := base_color
	border.a = COLOR_BORDER_ALPHA
	draw_rect(Rect2(0, 0, px_w, px_h), border, false, lw)

	# ── Selection ring ────────────────────────────────────────────────────────
	if is_selected:
		var ring_offset := 2.0 / current_zoom
		draw_rect(
			Rect2(-ring_offset, -ring_offset,
				  px_w + ring_offset * 2, px_h + ring_offset * 2),
			COLOR_SELECTED, false, lw * 1.5
		)

	# ── Entrance marker ───────────────────────────────────────────────────────
	_draw_entrance(sz, lw)

	# ── Label ─────────────────────────────────────────────────────────────────
	_draw_label(sz)

func _draw_entrance(sz: Vector2i, lw: float) -> void:
	var entrance := _rotated_entrance()
	if entrance.is_empty():
		return

	var side   : String = entrance.get("side",   "south")
	var offset : int    = entrance.get("offset", 0)
	var ms     : float = max(4.0, BLOCK_SIZE * 0.6) / current_zoom
	var px_w   := sz.x * BLOCK_SIZE
	var px_h   := sz.y * BLOCK_SIZE

	var cx := 0.0
	var cy := 0.0
	match side:
		"south": cx = (offset + 0.5) * BLOCK_SIZE; cy = px_h
		"north": cx = (offset + 0.5) * BLOCK_SIZE; cy = 0.0
		"west":  cx = 0.0;  cy = (offset + 0.5) * BLOCK_SIZE
		"east":  cx = px_w; cy = (offset + 0.5) * BLOCK_SIZE

	var pts : PackedVector2Array
	match side:
		"south":
			pts = PackedVector2Array([
				Vector2(cx - ms, cy), Vector2(cx + ms, cy), Vector2(cx, cy + ms * 1.5)
			])
		"north":
			pts = PackedVector2Array([
				Vector2(cx - ms, cy), Vector2(cx + ms, cy), Vector2(cx, cy - ms * 1.5)
			])
		"west":
			pts = PackedVector2Array([
				Vector2(cx, cy - ms), Vector2(cx, cy + ms), Vector2(cx - ms * 1.5, cy)
			])
		"east":
			pts = PackedVector2Array([
				Vector2(cx, cy - ms), Vector2(cx, cy + ms), Vector2(cx + ms * 1.5, cy)
			])

	if pts.size() == 3:
		draw_colored_polygon(pts, COLOR_ENTRANCE)

func _draw_label(sz: Vector2i) -> void:
	if current_zoom < 0.3:
		return
	var display  : String = instance_label if instance_label != "" else building_def.get("name", building_id)
	var font     := ThemeDB.fallback_font
	var font_size := int(clamp(11.0 / current_zoom, 8, 20))
	var text_size := font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var px_w := sz.x * BLOCK_SIZE
	var px_h := sz.y * BLOCK_SIZE
	var tx   := (px_w - text_size.x) * 0.5
	var ty   := (px_h - text_size.y) * 0.5 + text_size.y * 0.8
	var pad  := 2.0 / current_zoom
	draw_rect(
		Rect2(tx - pad, ty - text_size.y - pad, text_size.x + pad * 2, text_size.y + pad * 2),
		COLOR_LABEL_BG
	)
	draw_string(font, Vector2(tx, ty), display,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_LABEL_TEXT)
