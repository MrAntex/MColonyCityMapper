extends Node

## Main scene — wires camera, grid, building manager and sidebar together.

@onready var grid             : Node2D         = $World/Grid
@onready var camera           : Camera2D       = $Camera2D
@onready var building_manager : Node2D         = $World/BuildingManager
@onready var sidebar          : PanelContainer = $UI/SideBar
@onready var coords_label     : Label          = $UI/TopBar/MarginContainer/HBoxContainer/CoordsLabel
@onready var status_label     : Label          = $UI/TopBar/MarginContainer/HBoxContainer/StatusLabel

func _ready() -> void:
	camera.zoom_changed.connect(_on_zoom_changed)
	sidebar.building_picked.connect(_on_building_picked)
	building_manager.placement_cancelled.connect(_on_placement_cancelled)
	building_manager.building_selected.connect(_on_building_selected)
	building_manager.building_deselected.connect(_on_building_deselected)

func _process(_delta: float) -> void:
	_update_coords_label()

func _on_zoom_changed(new_zoom: float) -> void:
	grid.current_zoom = new_zoom
	grid.queue_redraw()
	building_manager.on_zoom_changed(new_zoom)

func _on_building_picked(bid: String) -> void:
	building_manager.start_placement(bid)
	var bname : String = BuildingDB.get_building(bid).get("name", bid)
	status_label.text = "Placing: %s  |  R rotate · SHIFT+LMB keep placing · RMB cancel" % bname

func _on_placement_cancelled() -> void:
	sidebar.deselect_active()
	status_label.text = ""

func _on_building_selected(instance: Node2D) -> void:
	var bname  : String = BuildingDB.get_building(instance.building_id).get("name", instance.building_id)
	var pos            : Vector2 = instance.grid_pos
	const ROT_LABELS   := ["0°", "90°", "180°", "270°"]
	var rot_label      : String = ROT_LABELS[instance.rotation_index]
	status_label.text  = "%s at (%d, %d)  rot %s  |  R rotate · DEL delete" % [bname, pos.x, pos.y, rot_label]

func _on_building_deselected() -> void:
	status_label.text = ""

func _update_coords_label() -> void:
	var mouse_screen := get_viewport().get_mouse_position()
	var vp_center    := get_viewport().get_visible_rect().size * 0.5
	var world_pixel  := camera.position + (mouse_screen - vp_center) / camera.zoom.x
	var block_x      := int(floor(world_pixel.x / grid.BLOCK_SIZE))
	var block_z      := int(floor(world_pixel.y / grid.BLOCK_SIZE))
	var mc_x: int    = block_x + grid.origin_offset.x
	var mc_z: int    = block_z + grid.origin_offset.y
	coords_label.text = "X: %d  Z: %d" % [mc_x, mc_z]
