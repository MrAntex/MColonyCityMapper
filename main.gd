extends Node

## Main scene — wires camera, grid, building manager, overlay, sidebar, inspector.

@onready var grid             : Node2D         = $World/Grid
@onready var camera           : Camera2D       = $Camera2D
@onready var building_manager : Node2D         = $World/BuildingManager
@onready var overlay_manager  : Node2D         = $World/OverlayManager
@onready var sidebar          : PanelContainer = $UI/Sidebar
@onready var inspector        : PanelContainer = $UI/Inspector
@onready var coords_label     : Label          = $UI/TopBar/MarginContainer/HBox/CoordsLabel
@onready var status_label     : Label          = $UI/TopBar/MarginContainer/HBox/StatusLabel

# Link creation mode — waiting for user to click a second building
var _linking_from : Node2D = null

func _ready() -> void:
	camera.zoom_changed.connect(_on_zoom_changed)
	sidebar.building_picked.connect(_on_building_picked)
	building_manager.placement_cancelled.connect(_on_placement_cancelled)
	building_manager.building_selected.connect(_on_building_selected)
	building_manager.building_deselected.connect(_on_building_deselected)
	inspector.move_requested.connect(_on_move_requested)
	inspector.delete_requested.connect(_on_delete_requested)
	inspector.link_add_requested.connect(_on_link_add_requested)
	inspector.setup(overlay_manager, building_manager)

func _process(_delta: float) -> void:
	_update_coords_label()

func _unhandled_input(event: InputEvent) -> void:
	# Handle link creation mode — intercept left click
	if _linking_from != null:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				# Find which building was clicked
				var block_pos := _screen_to_block(mb.position)
				var target : Node2D = null
				for i in range(building_manager._placed.size() - 1, -1, -1):
					var b : Node2D = building_manager._placed[i]
					if b.get_rect_blocks().has_point(block_pos):
						target = b
						break
				if target != null and target != _linking_from:
					overlay_manager.add_link(_linking_from, target)
					inspector.refresh_links()
				_linking_from = null
				status_label.text = ""
				get_viewport().set_input_as_handled()
		elif event is InputEventKey:
			var ke := event as InputEventKey
			if ke.pressed and ke.keycode == KEY_ESCAPE:
				_linking_from = null
				status_label.text = ""

func _on_zoom_changed(new_zoom: float) -> void:
	grid.current_zoom = new_zoom
	grid.queue_redraw()
	building_manager.on_zoom_changed(new_zoom)
	overlay_manager.on_zoom_changed(new_zoom)

func _on_building_picked(bid: String) -> void:
	_linking_from = null
	inspector.close()
	overlay_manager.hide_radius()
	building_manager.start_placement(bid)
	var bname : String = BuildingDB.get_building(bid).get("name", bid)
	status_label.text = "Placing: %s  |  R rotate · SHIFT+LMB keep placing · RMB cancel" % bname

func _on_placement_cancelled() -> void:
	sidebar.deselect_active()
	status_label.text = ""

func _on_building_selected(instance: Node2D) -> void:
	_linking_from = null
	inspector.inspect(instance)
	var bname : String = BuildingDB.get_building(instance.building_id).get("name", instance.building_id)
	const ROT_LABELS  := ["0°", "90°", "180°", "270°"]
	status_label.text  = "%s  rot %s  |  R rotate · DEL delete" % [
		bname, ROT_LABELS[instance.rotation_index]
	]

func _on_building_deselected() -> void:
	inspector.close()
	overlay_manager.hide_radius()
	status_label.text = ""

func _on_move_requested() -> void:
	if building_manager._selected != null:
		building_manager.start_move(building_manager._selected)
		inspector.close()
		status_label.text = "Moving — LMB confirm · RMB/ESC cancel · R rotate"

func _on_delete_requested() -> void:
	if building_manager._selected != null:
		overlay_manager.remove_links_for(building_manager._selected)
	inspector.close()
	overlay_manager.hide_radius()
	building_manager.delete_selected()

func _on_link_add_requested(from_node: Node2D) -> void:
	_linking_from = from_node
	var bname : String = BuildingDB.get_building(from_node.building_id).get("name", from_node.building_id)
	status_label.text = "Linking from %s — click another building · ESC cancel" % bname

func _update_coords_label() -> void:
	var mouse_screen := get_viewport().get_mouse_position()
	var vp_center    := get_viewport().get_visible_rect().size * 0.5
	var world_pixel  := camera.position + (mouse_screen - vp_center) / camera.zoom.x
	var block_x      := int(floor(world_pixel.x / grid.BLOCK_SIZE))
	var block_z      := int(floor(world_pixel.y / grid.BLOCK_SIZE))
	var mc_x: int    = block_x + grid.origin_offset.x
	var mc_z: int    = block_z + grid.origin_offset.y
	coords_label.text = "X: %d  Z: %d" % [mc_x, mc_z]

func _screen_to_block(screen_pos: Vector2) -> Vector2i:
	var vp_center  := get_viewport().get_visible_rect().size * 0.5
	var world_pixel := camera.position + (screen_pos - vp_center) / camera.zoom.x
	return Vector2i(int(floor(world_pixel.x / grid.BLOCK_SIZE)),
					int(floor(world_pixel.y / grid.BLOCK_SIZE)))
