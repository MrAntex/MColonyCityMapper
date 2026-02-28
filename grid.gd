extends Node2D

## Grid drawing node.
## Draws block-level grid cells and chunk borders (16x16 blocks).
## The world origin can be offset to match real Minecraft chunk alignment.

const BLOCK_SIZE := 16          # pixels per block at zoom 1.0
const CHUNK_SIZE := 16          # blocks per chunk (Minecraft standard)

# How many blocks to draw in each direction from the visible center.
# We draw a bit beyond the screen; culling is handled by checking camera bounds.
const DRAW_RADIUS_BLOCKS := 512

# Colors
const COLOR_BLOCK_GRID   := Color(0.25, 0.25, 0.25, 0.4)
const COLOR_CHUNK_GRID   := Color(0.6,  0.6,  0.6,  0.7)
const COLOR_ORIGIN_X     := Color(1.0,  0.3,  0.3,  0.8)   # red  - X axis
const COLOR_ORIGIN_Z     := Color(0.3,  0.6,  1.0,  0.8)   # blue - Z axis

# World origin offset in blocks (set this to match your Minecraft world)
var origin_offset := Vector2i(0, 0) : set = _set_origin_offset

# Zoom level reference (injected from camera so we can skip drawing tiny lines)
var current_zoom := 1.0

func _set_origin_offset(value: Vector2i) -> void:
	origin_offset = value
	queue_redraw()

func _draw() -> void:
	# Get the visible rect in world (pixel) space via the canvas transform
	var vp_size := get_viewport_rect().size
	var transform  := get_canvas_transform()
	# Top-left and bottom-right in local (world pixel) space
	var top_left     := -transform.origin / transform.get_scale().x
	var bottom_right := top_left + vp_size / transform.get_scale().x

	# Convert pixel bounds to block coordinates
	var block_left   := int(floor(top_left.x     / BLOCK_SIZE)) - 1
	var block_top    := int(floor(top_left.y     / BLOCK_SIZE)) - 1
	var block_right  := int(ceil(bottom_right.x  / BLOCK_SIZE)) + 1
	var block_bottom := int(ceil(bottom_right.y  / BLOCK_SIZE)) + 1

	# Clamp to a sane draw limit so we don't freeze on extreme zoom-out
	block_left   = max(block_left,   -DRAW_RADIUS_BLOCKS)
	block_top    = max(block_top,    -DRAW_RADIUS_BLOCKS)
	block_right  = min(block_right,   DRAW_RADIUS_BLOCKS)
	block_bottom = min(block_bottom,  DRAW_RADIUS_BLOCKS)

	# Only draw the fine block grid when zoomed in enough (avoid visual noise)
	if current_zoom >= 0.5:
		_draw_block_grid(block_left, block_top, block_right, block_bottom)

	_draw_chunk_grid(block_left, block_top, block_right, block_bottom)
	_draw_axes()

func _draw_block_grid(l: int, t: int, r: int, b: int) -> void:
	# Vertical lines
	for bx in range(l, r + 1):
		var x := bx * BLOCK_SIZE
		draw_line(Vector2(x, t * BLOCK_SIZE), Vector2(x, b * BLOCK_SIZE), COLOR_BLOCK_GRID, 0.5)
	# Horizontal lines
	for bz in range(t, b + 1):
		var z := bz * BLOCK_SIZE
		draw_line(Vector2(l * BLOCK_SIZE, z), Vector2(r * BLOCK_SIZE, z), COLOR_BLOCK_GRID, 0.5)

func _draw_chunk_grid(l: int, t: int, r: int, b: int) -> void:
	# Chunk lines snap to every 16 blocks, offset by origin
	var ox := origin_offset.x
	var oz := origin_offset.y

	# First chunk line left of view
	var cx_start := l - ((l - ox) % CHUNK_SIZE + CHUNK_SIZE) % CHUNK_SIZE
	var cz_start := t - ((t - oz) % CHUNK_SIZE + CHUNK_SIZE) % CHUNK_SIZE

	var bx := cx_start
	while bx <= r:
		var x := bx * BLOCK_SIZE
		draw_line(Vector2(x, t * BLOCK_SIZE), Vector2(x, b * BLOCK_SIZE), COLOR_CHUNK_GRID, 1.0)
		bx += CHUNK_SIZE

	var bz := cz_start
	while bz <= b:
		var z := bz * BLOCK_SIZE
		draw_line(Vector2(l * BLOCK_SIZE, z), Vector2(r * BLOCK_SIZE, z), COLOR_CHUNK_GRID, 1.0)
		bz += CHUNK_SIZE

func _draw_axes() -> void:
	# Draw world origin axes as colored lines
	var half := DRAW_RADIUS_BLOCKS * BLOCK_SIZE
	draw_line(Vector2(-half, 0), Vector2(half, 0), COLOR_ORIGIN_Z, 1.5)
	draw_line(Vector2(0, -half), Vector2(0,  half), COLOR_ORIGIN_X, 1.5)
