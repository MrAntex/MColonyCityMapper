extends Node

## Main scene — wires everything together.
## Currently sets up the grid and camera, and shows a coordinates label.

@onready var grid   : Node2D  = $World/Grid
@onready var camera : Camera2D = $Camera2D
@onready var coords_label : Label = $UI/TopBar/HBoxContainer/CoordsLabel

func _ready() -> void:
	camera.zoom_changed.connect(_on_zoom_changed)

func _process(_delta: float) -> void:
	_update_coords_label()

func _on_zoom_changed(new_zoom: float) -> void:
	grid.current_zoom = new_zoom
	grid.queue_redraw()

func _update_coords_label() -> void:
	var mouse_screen := get_viewport().get_mouse_position()
	var vp_center    := get_viewport().get_visible_rect().size * 0.5
	var world_pixel  := camera.position + (mouse_screen - vp_center) / camera.zoom.x
	var block_x      := int(floor(world_pixel.x / grid.BLOCK_SIZE))
	var block_z      := int(floor(world_pixel.y / grid.BLOCK_SIZE))
	# Adjust for world origin offset so coords match Minecraft
	var mc_x : int = block_x + grid.origin_offset.x
	var mc_z : int = block_z + grid.origin_offset.y
	coords_label.text = "X: %d  Z: %d" % [mc_x, mc_z]
