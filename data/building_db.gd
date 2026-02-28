extends Node

## BuildingDB — Autoload singleton.
## Loads buildings.json from res://data/buildings.json at startup
## and provides lookup helpers used throughout the project.

const DATA_PATH := "res://data/buildings.json"

# All building definitions keyed by id
var buildings : Dictionary = {}

# Sorted list of categories → subcategories → [building ids]
# Structure: { "Category": { "Subcategory": ["id", ...], ... }, ... }
var categories : Dictionary = {}

func _ready() -> void:
	_load()

func _load() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		push_error("BuildingDB: buildings.json not found at %s" % DATA_PATH)
		return

	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	var json  := JSON.new()
	var err   := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("BuildingDB: JSON parse error — %s" % json.get_error_message())
		return

	var data : Array = json.data.get("buildings", [])
	for entry in data:
		var id : String = entry["id"]
		buildings[id] = entry

		# Build category tree
		var cat    : String = entry.get("category",    "Uncategorized")
		var subcat : String = entry.get("subcategory", "") if entry.get("subcategory", "") != null else ""
		if subcat == null:
			subcat = ""

		if not categories.has(cat):
			categories[cat] = {}
		if not categories[cat].has(subcat):
			categories[cat][subcat] = []
		categories[cat][subcat].append(id)

	print("BuildingDB: loaded %d buildings across %d categories." % [buildings.size(), categories.size()])

## Returns the full definition Dictionary for a building id, or null.
func get_building(id: String) -> Dictionary:
	return buildings.get(id, {})

## Returns the size as a Vector2i (x, z).
func get_size(id: String) -> Vector2i:
	var b := get_building(id)
	if b.is_empty():
		return Vector2i(1, 1)
	return Vector2i(b["size"]["x"], b["size"]["z"])

## Returns the entrance as a Dictionary with keys "side" and "offset", or null.
func get_entrance(id: String) -> Dictionary:
	var b := get_building(id)
	return b.get("entrance", {})

## Returns the display color as a Color.
func get_color(id: String) -> Color:
	var b := get_building(id)
	return Color(b.get("color", "#888888"))
