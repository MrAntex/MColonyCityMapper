extends Node2D

## OverlayManager — draws radius overlays and supply chain arrows.
## Sits above BuildingManager in the World node.

const BLOCK_SIZE := 16

# ── Colors ────────────────────────────────────────────────────────────────────
const COLOR_RADIUS_FILL    := Color(0.4,  0.7,  1.0,  0.06)
const COLOR_RADIUS_BORDER  := Color(0.4,  0.7,  1.0,  0.45)
const COLOR_COVERED_FILL   := Color(0.2,  0.9,  0.3,  0.18)
const COLOR_COVERED_BORDER := Color(0.2,  0.9,  0.3,  0.70)
const COLOR_UNCOVERED_FILL  := Color(0.95, 0.25, 0.2,  0.18)
const COLOR_UNCOVERED_BORDER:= Color(0.95, 0.25, 0.2,  0.70)
const COLOR_LINK_DEFAULT   := Color(0.85, 0.70, 0.20, 0.85)
const COLOR_LINK_SELECTED  := Color(1.00, 0.90, 0.30, 1.00)
const COLOR_LINK_HOVER     := Color(1.00, 1.00, 0.60, 1.00)
const COLOR_ARROWHEAD      := Color(0.85, 0.70, 0.20, 0.95)

# ── State ─────────────────────────────────────────────────────────────────────
var current_zoom    : float  = 1.0

# Radius display
var _radius_building : Node2D   = null   # building whose radius to show
var _radius_blocks   : int      = 0
var _all_buildings   : Array    = []     # injected from building_manager

# Supply chain links: Array of { "from": Node2D, "to": Node2D }
var _links           : Array    = []
var _selected_link   : Dictionary = {}  # currently selected link (or {})

signal link_removed(from_node, to_node)

func _ready() -> void:
	pass

# ── Public API ────────────────────────────────────────────────────────────────

## Show radius overlay for a building. Pass null to hide.
func show_radius(building_node, all_buildings: Array) -> void:
	_radius_building = building_node
	_all_buildings   = all_buildings
	if building_node != null:
		_radius_blocks = building_node.get_meta("action_radius", 0)
	queue_redraw()

func hide_radius() -> void:
	_radius_building = null
	queue_redraw()

## Add a supply chain link between two buildings (if not already present).
func add_link(from_node: Node2D, to_node: Node2D) -> bool:
	if from_node == to_node:
		return false
	for link in _links:
		if link["from"] == from_node and link["to"] == to_node:
			return false   # already exists
	_links.append({ "from": from_node, "to": to_node })
	queue_redraw()
	return true

## Remove all links involving a building (call when building is deleted).
func remove_links_for(building_node: Node2D) -> void:
	_links = _links.filter(func(l): return l["from"] != building_node and l["to"] != building_node)
	if not _selected_link.is_empty():
		if _selected_link.get("from") == building_node or _selected_link.get("to") == building_node:
			_selected_link = {}
	queue_redraw()

## Remove a specific link.
func remove_link(from_node: Node2D, to_node: Node2D) -> void:
	_links = _links.filter(func(l): return not (l["from"] == from_node and l["to"] == to_node))
	if _selected_link.get("from") == from_node and _selected_link.get("to") == to_node:
		_selected_link = {}
	queue_redraw()

## Returns links involving a specific building node.
func get_links_for(building_node: Node2D) -> Array:
	return _links.filter(func(l): return l["from"] == building_node or l["to"] == building_node)

func serialize_links() -> Array:
	# We serialize by index into the placed array — caller must provide the array
	return _links.map(func(l): return { "from_node": l["from"], "to_node": l["to"] })

func get_all_links() -> Array:
	return _links.duplicate()

func clear_links() -> void:
	_links.clear()
	_selected_link = {}
	queue_redraw()

func on_zoom_changed(z: float) -> void:
	current_zoom = z
	queue_redraw()

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw() -> void:
	_draw_radius()
	_draw_links()

func _draw_radius() -> void:
	if _radius_building == null or _radius_blocks <= 0:
		return

	var bsz    : Vector2 = _radius_building._rotated_size()
	var bcenter := Vector2(_radius_building.grid_pos) * BLOCK_SIZE \
		+ Vector2(bsz) * BLOCK_SIZE * 0.5
	var r_px   := _radius_blocks * BLOCK_SIZE
	var lw     := 1.5 / current_zoom

	# Radius square (Chebyshev distance = square in Minecraft)
	var half  := Vector2(r_px + bsz.x * BLOCK_SIZE * 0.5,
						 r_px + bsz.y * BLOCK_SIZE * 0.5)
	var tl    := bcenter - half
	var rect  := Rect2(tl, half * 2.0)

	draw_rect(rect, COLOR_RADIUS_FILL)
	draw_rect(rect, COLOR_RADIUS_BORDER, false, lw)

	# Tint other buildings based on coverage
	for b in _all_buildings:
		if b == _radius_building:
			continue
		if not is_instance_valid(b):
			continue
		var other_sz  : Vector2 = b._rotated_size()
		var other_rect := Rect2(
			Vector2(b.grid_pos) * BLOCK_SIZE,
			Vector2(other_sz)   * BLOCK_SIZE
		)
		var covered := rect.encloses(other_rect)
		var fill   := COLOR_COVERED_FILL   if covered else COLOR_UNCOVERED_FILL
		var border := COLOR_COVERED_BORDER if covered else COLOR_UNCOVERED_BORDER
		draw_rect(other_rect, fill)
		draw_rect(other_rect, border, false, lw)

func _draw_links() -> void:
	var lw := 2.0 / current_zoom
	for link in _links:
		var from_node : Node2D = link["from"]
		var to_node   : Node2D = link["to"]
		if not is_instance_valid(from_node) or not is_instance_valid(to_node):
			continue
		var is_sel : bool = (not _selected_link.is_empty()
			and _selected_link.get("from") == from_node
			and _selected_link.get("to")   == to_node)
		var color := COLOR_LINK_SELECTED if is_sel else COLOR_LINK_DEFAULT
		_draw_arrow(from_node, to_node, color, lw)

func _draw_arrow(from_node: Node2D, to_node: Node2D, color: Color, lw: float) -> void:
	var from_sz : Vector2 = from_node._rotated_size()
	var to_sz   : Vector2 = to_node._rotated_size()
	var from_center := Vector2(from_node.grid_pos) * BLOCK_SIZE + Vector2(from_sz) * BLOCK_SIZE * 0.5
	var to_center   := Vector2(to_node.grid_pos)   * BLOCK_SIZE + Vector2(to_sz)   * BLOCK_SIZE * 0.5

	# Offset start/end to building edges
	var dir      := (to_center - from_center).normalized()
	var from_half := Vector2(from_sz) * BLOCK_SIZE * 0.5
	var to_half   := Vector2(to_sz)   * BLOCK_SIZE * 0.5
	var start    := from_center + dir * _edge_offset(dir, from_half)
	var end      := to_center   - dir * _edge_offset(-dir, to_half)

	draw_line(start, end, color, lw)

	# Arrowhead
	var head_size := 8.0 / current_zoom
	var perp      := Vector2(-dir.y, dir.x)
	var tip       := end
	var base_l    := end - dir * head_size + perp * head_size * 0.5
	var base_r    := end - dir * head_size - perp * head_size * 0.5
	draw_colored_polygon(PackedVector2Array([tip, base_l, base_r]), color)

## Returns how far along `dir` to travel from center to reach the AABB edge.
func _edge_offset(dir: Vector2, half: Vector2) -> float:
	var tx : float = INF if abs(dir.x) < 0.0001 else abs(half.x / dir.x)
	var tz : float = INF if abs(dir.y) < 0.0001 else abs(half.y / dir.y)
	return min(tx, tz) + 2.0 / current_zoom   # +2px gap
