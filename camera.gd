extends Camera2D

## Handles pan (middle mouse drag or right click drag) and zoom (scroll wheel).
## Emits zoom_changed so other nodes (like the grid) can react.

signal zoom_changed(new_zoom: float)

const ZOOM_MIN     := 0.05   # very zoomed out
const ZOOM_MAX     := 8.0    # very zoomed in
const ZOOM_STEP    := 0.1    # multiplier step per scroll tick

var _panning    := false
var _pan_origin := Vector2.ZERO   # mouse position when pan started
var _cam_origin := Vector2.ZERO   # camera position when pan started

func _ready() -> void:
	# Start roughly centered
	position = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	# ── Pan start ──────────────────────────────────────────────────────────────
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_panning    = true
				_pan_origin = mb.position
				_cam_origin = position
			else:
				_panning = false

		# ── Zoom ───────────────────────────────────────────────────────────────
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_toward(mb.position, 1.0 + ZOOM_STEP)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_toward(mb.position, 1.0 - ZOOM_STEP)

	# ── Pan drag ───────────────────────────────────────────────────────────────
	elif event is InputEventMouseMotion and _panning:
		var mm := event as InputEventMouseMotion
		var delta := (mm.position - _pan_origin) / zoom.x
		position = _cam_origin - delta

func _zoom_toward(mouse_screen_pos: Vector2, factor: float) -> void:
	var old_zoom := zoom.x
	var new_zoom : float = clamp(old_zoom * factor, ZOOM_MIN, ZOOM_MAX)
	if new_zoom == old_zoom:
		return

	# Zoom toward the mouse cursor position
	var mouse_world_before := position + (mouse_screen_pos - get_viewport_rect().size * 0.5) / old_zoom
	zoom = Vector2.ONE * new_zoom
	var mouse_world_after  : Vector2 = position + (mouse_screen_pos - get_viewport_rect().size * 0.5) / new_zoom
	position += mouse_world_before - mouse_world_after

	zoom_changed.emit(new_zoom)
