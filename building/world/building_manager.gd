extends Node2D

## BuildingManager — owns all placed buildings.
## Handles placement ghost, selection, move, rotate, delete.

signal building_selected(instance: Node2D)
signal building_deselected()
signal placement_cancelled()

const BLOCK_SIZE := 16
const PlacedBuildingScript := preload("res://scenes/placed_building.gd")

# ── State ─────────────────────────────────────────────────────────────────────
var _placed        : Array[Node2D] = []
var _selected      : Node2D        = null
var _ghost_id      : String        = ""
var _ghost_node    : Node2D        = null
var _ghost_rot     : int           = 0      # rotation_index for the current ghost
var current_zoom   : float         = 1.0

# ── Public API ────────────────────────────────────────────────────────────────

func start_placement(bid: String) -> void:
	_cancel_placement()
	_ghost_id   = bid
	_ghost_rot  = 0
	_ghost_node = _make_building_node(bid, Vector2i.ZERO, 0, true)
	add_child(_ghost_node)

func cancel_placement() -> void:
	_cancel_placement()
	placement_cancelled.emit()

func delete_selected() -> void:
	if _selected == null:
		return
	_placed.erase(_selected)
	_selected.queue_free()
	_selected = null
	building_deselected.emit()

func serialize() -> Array:
	var out : Array = []
	for b in _placed:
		out.append({
			"id":       b.building_id,
			"pos":      { "x": b.grid_pos.x, "z": b.grid_pos.y },
			"label":    b.instance_label,
			"rotation": b.rotation_index
		})
	return out

func deserialize(data: Array) -> void:
	for b in _placed:
		b.queue_free()
	_placed.clear()
	_selected = null
	for entry in data:
		var bid  : String   = entry["id"]
		var gpos : Vector2i = Vector2i(entry["pos"]["x"], entry["pos"]["z"])
		var rot  : int      = entry.get("rotation", 0)
		var node := _place_building(bid, gpos, rot)
		node.instance_label = entry.get("label", "")

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _ghost_node != null:
			_ghost_node.position = _snapped_world_pos(event.position)
			_ghost_node.current_zoom = current_zoom
			_ghost_node.queue_redraw()

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed:
			return

		if mb.button_index == MOUSE_BUTTON_LEFT:
			if _ghost_node != null:
				var gpos := _world_to_grid(_snapped_world_pos(mb.position))
				_place_building(_ghost_id, gpos, _ghost_rot)
				if not Input.is_key_pressed(KEY_SHIFT):
					_cancel_placement()
			else:
				_try_select(mb.position)

		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if _ghost_node != null:
				cancel_placement()

	elif event is InputEventKey:
		var ke := event as InputEventKey
		if not ke.pressed:
			return

		match ke.keycode:
			KEY_ESCAPE:
				if _ghost_node != null:
					cancel_placement()
				elif _selected != null:
					_deselect()
			KEY_DELETE:
				delete_selected()
			KEY_R:
				# Rotate ghost OR selected building
				if _ghost_node != null:
					_ghost_rot = (_ghost_rot + 1) % 4
					_ghost_node.rotation_index = _ghost_rot
					_ghost_node.queue_redraw()
				elif _selected != null:
					_selected.rotation_index = (_selected.rotation_index + 1) % 4
					_selected.queue_redraw()
					building_selected.emit(_selected)   # refresh status bar

# ── Zoom update ───────────────────────────────────────────────────────────────

func on_zoom_changed(z: float) -> void:
	current_zoom = z
	for b in _placed:
		b.current_zoom = z
		b.queue_redraw()
	if _ghost_node != null:
		_ghost_node.current_zoom = z
		_ghost_node.queue_redraw()

# ── Internal helpers ──────────────────────────────────────────────────────────

func _place_building(bid: String, gpos: Vector2i, rot: int) -> Node2D:
	var node := _make_building_node(bid, gpos, rot, false)
	add_child(node)
	_placed.append(node)
	return node

func _make_building_node(bid: String, gpos: Vector2i, rot: int, is_ghost: bool) -> Node2D:
	var node := Node2D.new()
	node.set_script(PlacedBuildingScript)
	node.current_zoom    = current_zoom
	node.rotation_index  = rot
	node.setup(bid, gpos)
	if is_ghost:
		node.modulate = Color(1, 1, 1, 0.5)
	return node

func _cancel_placement() -> void:
	if _ghost_node != null:
		_ghost_node.queue_free()
		_ghost_node = null
	_ghost_id  = ""
	_ghost_rot = 0

func _try_select(screen_pos: Vector2) -> void:
	var block_pos := _world_to_grid(_screen_to_world(screen_pos))
	for i in range(_placed.size() - 1, -1, -1):
		var b := _placed[i]
		if b.get_rect_blocks().has_point(block_pos):
			_select(b)
			return
	_deselect()

func _select(node: Node2D) -> void:
	if _selected != null:
		_selected.is_selected = false
	_selected = node
	_selected.is_selected = true
	building_selected.emit(node)

func _deselect() -> void:
	if _selected != null:
		_selected.is_selected = false
		_selected = null
	building_deselected.emit()

func _snapped_world_pos(screen_pos: Vector2) -> Vector2:
	return Vector2(_world_to_grid(_screen_to_world(screen_pos))) * BLOCK_SIZE

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var cam       := get_viewport().get_camera_2d()
	var vp_center := get_viewport().get_visible_rect().size * 0.5
	return cam.position + (screen_pos - vp_center) / cam.zoom.x

func _world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_pos.x / BLOCK_SIZE)), int(floor(world_pos.y / BLOCK_SIZE)))
