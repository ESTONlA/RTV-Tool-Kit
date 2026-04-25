extends RefCounted

const CONFIG_PATH := "user://rtv_tool_kit_state.cfg"
const DEFAULT_WINDOW_POSITION := Vector2(36.0, 44.0)
const DEFAULT_WINDOW_SIZE := Vector2(1220.0, 760.0)
const MIN_WINDOW_SIZE := Vector2(840.0, 540.0)


static func load_state() -> Dictionary:
	var config := ConfigFile.new()
	var state := {
		"bookmarks": [] as Array[String],
		"watch_paths": [] as Array[String],
		"pinned_properties": [] as Array[String],
		"watched_properties": [] as Array[String],
		"window_position": DEFAULT_WINDOW_POSITION,
		"window_size": DEFAULT_WINDOW_SIZE,
	}

	if config.load(CONFIG_PATH) != OK:
		return state

	state["bookmarks"] = sanitize_string_array(config.get_value("watch", "bookmarks", []))
	state["watch_paths"] = sanitize_string_array(config.get_value("watch", "watch_paths", []))
	state["pinned_properties"] = sanitize_string_array(config.get_value("inspector", "pinned_properties", []))
	state["watched_properties"] = sanitize_string_array(config.get_value("inspector", "watched_properties", []))
	state["window_position"] = _read_vector2(config.get_value("window", "position", DEFAULT_WINDOW_POSITION), DEFAULT_WINDOW_POSITION)
	state["window_size"] = _read_vector2(config.get_value("window", "size", DEFAULT_WINDOW_SIZE), DEFAULT_WINDOW_SIZE)
	return state


static func save_state(bookmarks: Array[String], watch_paths: Array[String], pinned_properties: Array[String], watched_properties: Array[String], window_position: Vector2, window_size: Vector2) -> void:
	var config := ConfigFile.new()
	config.set_value("watch", "bookmarks", bookmarks.duplicate())
	config.set_value("watch", "watch_paths", watch_paths.duplicate())
	config.set_value("inspector", "pinned_properties", pinned_properties.duplicate())
	config.set_value("inspector", "watched_properties", watched_properties.duplicate())
	config.set_value("window", "position", window_position)
	config.set_value("window", "size", window_size)
	config.save(CONFIG_PATH)


static func sanitize_string_array(value) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for entry in value:
			var text := String(entry).strip_edges()
			if text != "" and not out.has(text):
				out.append(text)
	return out


static func _read_vector2(value, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	if value is PackedStringArray and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	if value is Dictionary and value.has("x") and value.has("y"):
		return Vector2(float(value["x"]), float(value["y"]))
	return fallback
