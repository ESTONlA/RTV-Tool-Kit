extends RefCounted

const COMMON_FOOTPRINTS := [
	"1x1",
	"1x2",
	"2x1",
	"2x2",
	"1x3",
	"3x1",
	"2x3",
	"3x2",
	"3x3",
	"4x1",
	"1x4",
]


static func describe_source(source, path_hint: String = "", source_label: String = "") -> Dictionary:
	var info := {
		"ok": false,
		"error": "",
		"source_kind": "<none>",
		"source_label": source_label.strip_edges(),
		"resource_path": "",
		"scene_path": "",
		"display_name": "",
		"footprint": "<unknown>",
		"icon": null,
		"summary_lines": [],
		"scene_candidates": [],
	}

	if source == null:
		info["error"] = "No preview source."
		info["summary_lines"] = ["No preview source selected."]
		return info

	var source_path := _source_path(source, path_hint)
	var scene_candidates := _collect_scene_candidates(source, source_path)
	var scene_path := _pick_preview_scene_path(source, source_path, scene_candidates)
	var display_name := _detect_display_name(source, source_path)
	var icon_texture = _detect_icon(source)
	var footprint := _detect_footprint(source, source_path, scene_candidates)

	info["ok"] = true
	info["source_kind"] = _source_kind(source)
	info["resource_path"] = source_path
	info["scene_path"] = scene_path
	info["display_name"] = display_name
	info["footprint"] = footprint if footprint != "" else "<unknown>"
	info["icon"] = icon_texture
	info["scene_candidates"] = scene_candidates

	if String(info["source_label"]) == "":
		info["source_label"] = display_name if display_name != "" else _value_or_placeholder(source_path)

	var summary_lines: Array[String] = []
	summary_lines.append("Source: %s" % info["source_kind"])
	summary_lines.append("Name: %s" % _value_or_placeholder(display_name))
	if String(info["source_label"]) != "" and String(info["source_label"]) != display_name:
		summary_lines.append("Label: %s" % info["source_label"])
	if source_path != "":
		summary_lines.append("Resource: %s" % source_path)
	if scene_path != "":
		summary_lines.append("World Scene: %s" % scene_path)
	else:
		summary_lines.append("World Scene: <not resolved>")
	summary_lines.append("Inventory Footprint: %s" % info["footprint"])
	if icon_texture is Texture2D:
		var icon_size := (icon_texture as Texture2D).get_size()
		summary_lines.append("Icon: %dx%d" % [int(icon_size.x), int(icon_size.y)])
	else:
		summary_lines.append("Icon: <not resolved>")
	if not scene_candidates.is_empty():
		summary_lines.append("Linked Scenes: %d" % scene_candidates.size())
	info["summary_lines"] = summary_lines
	return info


static func create_preview_instance(source, descriptor: Dictionary) -> Dictionary:
	var result := {
		"ok": false,
		"error": "",
		"mode": "empty",
		"node": null,
		"texture": null,
	}

	if source == null:
		result["error"] = "No preview source."
		return result

	if source is Texture2D:
		result["ok"] = true
		result["mode"] = "texture"
		result["texture"] = source
		return result

	if source is PackedScene:
		var packed_scene := source as PackedScene
		var instance = packed_scene.instantiate()
		if instance is Node:
			_disable_runtime_processing(instance)
			result["ok"] = true
			result["node"] = instance
			result["mode"] = _resolve_node_mode(instance)
			return result
		result["error"] = "Failed to instantiate PackedScene."
		return result

	if source is Node:
		var source_node := source as Node
		if source_node.is_inside_tree():
			result["error"] = "Live scene nodes are not previewed directly. Load a resource or scene path instead."
			return result
		var duplicated = source_node.duplicate()
		if duplicated is Node:
			_disable_runtime_processing(duplicated)
			result["ok"] = true
			result["node"] = duplicated
			result["mode"] = _resolve_node_mode(duplicated)
			return result
		result["error"] = "Failed to duplicate node."
		return result

	if source is Mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = source
		result["ok"] = true
		result["node"] = mesh_instance
		result["mode"] = "3d"
		return result

	if source is Material:
		var material_preview := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.6
		sphere.height = 1.2
		material_preview.mesh = sphere
		material_preview.set_surface_override_material(0, source)
		result["ok"] = true
		result["node"] = material_preview
		result["mode"] = "3d"
		return result

	if source is Resource:
		var scene_path := String(descriptor.get("scene_path", ""))
		if scene_path != "" and ResourceLoader.exists(scene_path):
			var scene_resource = load(scene_path)
			if scene_resource is PackedScene:
				return create_preview_instance(scene_resource, descriptor)

		var icon_texture = descriptor.get("icon")
		if icon_texture is Texture2D:
			result["ok"] = true
			result["mode"] = "texture"
			result["texture"] = icon_texture
			return result

	result["error"] = "No renderable preview target was resolved."
	return result


static func inspect_scene(root: Node) -> Dictionary:
	var stats := {
		"total_nodes": 0,
		"node3d": 0,
		"node2d": 0,
		"controls": 0,
		"meshes": 0,
		"collisions": 0,
		"lights": 0,
		"audio_3d": 0,
		"audio_other": 0,
		"cameras": 0,
		"particles": 0,
		"special_labels": [],
		"special_entries": [],
		"marker_specs": [],
	}

	if root == null:
		return stats

	_collect_scene_stats(root, root, stats)
	return stats


static func build_scene_report_lines(stats: Dictionary, mode: String) -> Array[String]:
	var lines: Array[String] = []
	lines.append("Preview Mode: %s" % mode)
	lines.append("Nodes: %d total | 3D %d | 2D %d | UI %d" % [
		int(stats.get("total_nodes", 0)),
		int(stats.get("node3d", 0)),
		int(stats.get("node2d", 0)),
		int(stats.get("controls", 0)),
	])
	lines.append("Meshes: %d | Collisions: %d | Lights: %d" % [
		int(stats.get("meshes", 0)),
		int(stats.get("collisions", 0)),
		int(stats.get("lights", 0)),
	])
	lines.append("Audio: 3D %d | Other %d | Cameras: %d | Particles: %d" % [
		int(stats.get("audio_3d", 0)),
		int(stats.get("audio_other", 0)),
		int(stats.get("cameras", 0)),
		int(stats.get("particles", 0)),
	])

	var special_labels = _string_array(stats.get("special_labels", []))
	if not special_labels.is_empty():
		lines.append("")
		lines.append("[Special Nodes]")
		var shown := min(12, special_labels.size())
		for index in range(shown):
			lines.append(special_labels[index])
		if special_labels.size() > shown:
			lines.append("... %d more" % [special_labels.size() - shown])
	else:
		lines.append("")
		lines.append("[Special Nodes]")
		lines.append("<none>")

	return lines


static func _collect_scene_stats(root: Node, node: Node, stats: Dictionary) -> void:
	stats["total_nodes"] = int(stats.get("total_nodes", 0)) + 1

	if node is Node3D:
		stats["node3d"] = int(stats.get("node3d", 0)) + 1
	if node is Node2D:
		stats["node2d"] = int(stats.get("node2d", 0)) + 1
	if node is Control:
		stats["controls"] = int(stats.get("controls", 0)) + 1
	if node is MeshInstance3D or node is MultiMeshInstance3D or node is CSGShape3D:
		stats["meshes"] = int(stats.get("meshes", 0)) + 1
	if node is CollisionShape3D or node is CollisionPolygon3D or node is CollisionShape2D or node is CollisionPolygon2D:
		stats["collisions"] = int(stats.get("collisions", 0)) + 1
	if node is Light3D:
		stats["lights"] = int(stats.get("lights", 0)) + 1
		_add_marker_spec(root, node, stats, "LIGHT", Color(1.0, 0.88, 0.42, 1.0))
	if node is AudioStreamPlayer3D:
		stats["audio_3d"] = int(stats.get("audio_3d", 0)) + 1
		_add_marker_spec(root, node, stats, "SFX", Color(0.55, 0.92, 1.0, 1.0))
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
		stats["audio_other"] = int(stats.get("audio_other", 0)) + 1
		_append_special_label(stats, "Audio: %s" % _relative_node_path(root, node))
		_append_special_entry(stats, "AUDIO", _relative_node_path(root, node), node)
	if node is Camera3D or node is Camera2D:
		stats["cameras"] = int(stats.get("cameras", 0)) + 1
		_append_special_entry(stats, "CAMERA", _relative_node_path(root, node), node)
	if node is GPUParticles3D or node is GPUParticles2D or node is CPUParticles3D or node is CPUParticles2D:
		stats["particles"] = int(stats.get("particles", 0)) + 1
		_append_special_entry(stats, "FX", _relative_node_path(root, node), node)
	if node is Marker3D:
		_add_marker_spec(root, node, stats, "MARK", Color(0.68, 1.0, 0.70, 1.0))
	if node is CollisionShape3D:
		_add_marker_spec(root, node, stats, "COL", Color(1.0, 0.62, 0.62, 1.0))

	for child in node.get_children():
		if child is Node:
			_collect_scene_stats(root, child, stats)


static func _append_special_label(stats: Dictionary, text: String) -> void:
	var labels: Array = stats.get("special_labels", [])
	if labels.size() < 24:
		labels.append(text)
	stats["special_labels"] = labels


static func _append_special_entry(stats: Dictionary, kind: String, path: String, node: Node) -> void:
	var entries: Array = stats.get("special_entries", [])
	if entries.size() < 96:
		entries.append({
			"kind": kind,
			"path": path,
			"label": "%s: %s" % [kind, path],
			"is_3d": node is Node3D,
			"position": (node as Node3D).global_position if node is Node3D else Vector3.ZERO,
		})
	stats["special_entries"] = entries


static func _add_marker_spec(root: Node, node: Node, stats: Dictionary, label: String, color: Color) -> void:
	if not (node is Node3D):
		_append_special_label(stats, "%s: %s" % [label, _relative_node_path(root, node)])
		_append_special_entry(stats, label, _relative_node_path(root, node), node)
		return

	var labels: Array = stats.get("special_labels", [])
	if labels.size() < 24:
		labels.append("%s: %s" % [label, _relative_node_path(root, node)])
	stats["special_labels"] = labels
	_append_special_entry(stats, label, _relative_node_path(root, node), node)

	var marker_specs: Array = stats.get("marker_specs", [])
	marker_specs.append({
		"label": label,
		"path": _relative_node_path(root, node),
		"position": (node as Node3D).global_position,
		"color": color,
	})
	stats["marker_specs"] = marker_specs


static func _relative_node_path(root: Node, node: Node) -> String:
	if root == node:
		return node.name
	return String(root.get_path_to(node))


static func _disable_runtime_processing(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is AnimationPlayer:
		(node as AnimationPlayer).stop()
	if node is AudioStreamPlayer:
		(node as AudioStreamPlayer).stop()
	if node is AudioStreamPlayer2D:
		(node as AudioStreamPlayer2D).stop()
	if node is AudioStreamPlayer3D:
		(node as AudioStreamPlayer3D).stop()

	for child in node.get_children():
		if child is Node:
			_disable_runtime_processing(child)


static func _resolve_node_mode(node: Node) -> String:
	if node == null:
		return "empty"
	if _tree_contains_type(node, "Node3D"):
		return "3d"
	if _tree_contains_type(node, "Node2D"):
		return "2d"
	if _tree_contains_type(node, "Control"):
		return "control"
	return "node"


static func _tree_contains_type(node: Node, target_class: String) -> bool:
	if node.is_class(target_class):
		return true
	for child in node.get_children():
		if child is Node and _tree_contains_type(child, target_class):
			return true
	return false


static func _source_kind(source) -> String:
	if source == null:
		return "<none>"
	if source is PackedScene:
		return "PackedScene"
	if source is Texture2D:
		return "Texture2D"
	if source is Resource:
		return source.get_class()
	if source is Node:
		return "%s Node" % source.get_class()
	if source is Object:
		return source.get_class()
	return str(typeof(source))


static func _source_path(source, path_hint: String) -> String:
	var trimmed_hint := path_hint.strip_edges()
	if trimmed_hint != "":
		return trimmed_hint
	if source is Resource:
		return String((source as Resource).resource_path)
	if source is Node:
		return String(_safe_get_property(source, "scene_file_path", ""))
	return ""


static func _detect_display_name(source, source_path: String) -> String:
	if source is Node:
		return source.name
	if source is Resource:
		var exact_names := ["name", "display_name", "item_name", "title", "label", "display"]
		for key in exact_names:
			var value = _safe_get_property(source, key, "")
			if typeof(value) in [TYPE_STRING, TYPE_STRING_NAME]:
				var text := String(value).strip_edges()
				if text != "":
					return text
		for property_info in source.get_property_list():
			var property_name := String(property_info.get("name", ""))
			if property_name == "":
				continue
			var lower := property_name.to_lower()
			if not (lower.contains("name") or lower.contains("title") or lower.contains("label")):
				continue
			var property_value = source.get(property_name)
			if typeof(property_value) in [TYPE_STRING, TYPE_STRING_NAME]:
				var property_text := String(property_value).strip_edges()
				if property_text != "":
					return property_text
		var resource_name = String(_safe_get_property(source, "resource_name", "")).strip_edges()
		if resource_name != "":
			return resource_name
	if source_path != "":
		return source_path.get_file().get_basename()
	return _source_kind(source)


static func _detect_icon(source):
	if source is Texture2D:
		return source
	if not (source is Resource):
		return null

	var preferred_names := ["icon", "thumbnail", "preview", "inventory", "texture", "sprite", "image"]
	var fallback_textures: Array = []
	for property_info in source.get_property_list():
		var property_name := String(property_info.get("name", ""))
		if property_name == "":
			continue
		var value = source.get(property_name)
		if not (value is Texture2D):
			continue
		var lower := property_name.to_lower()
		for token in preferred_names:
			if lower.contains(token):
				return value
		fallback_textures.append(value)
	return fallback_textures[0] if not fallback_textures.is_empty() else null


static func _collect_scene_candidates(source, source_path: String) -> Array[String]:
	var candidates: Array[String] = []
	if source is PackedScene:
		_push_unique_string(candidates, String((source as PackedScene).resource_path))
		return candidates
	if source is Node:
		_push_unique_string(candidates, String(_safe_get_property(source, "scene_file_path", "")))
		return candidates
	if not (source is Resource):
		return candidates

	for property_info in source.get_property_list():
		var property_name := String(property_info.get("name", ""))
		if property_name == "":
			continue
		var value = source.get(property_name)
		if value is PackedScene:
			_push_unique_string(candidates, String((value as PackedScene).resource_path))
		elif typeof(value) in [TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH]:
			var text := String(value).strip_edges()
			if text.begins_with("res://") and text.ends_with(".tscn"):
				_push_unique_string(candidates, text)

	if source_path.ends_with(".tres"):
		var sibling_scene := "%s.tscn" % source_path.get_basename()
		if ResourceLoader.exists(sibling_scene):
			candidates.insert(0, sibling_scene)
		for footprint in COMMON_FOOTPRINTS:
			var inventory_scene := "%s_%s.tscn" % [source_path.get_basename(), footprint]
			if ResourceLoader.exists(inventory_scene):
				_push_unique_string(candidates, inventory_scene)

	return candidates


static func _pick_preview_scene_path(source, source_path: String, candidates: Array[String]) -> String:
	if source is PackedScene:
		return String((source as PackedScene).resource_path)
	if source is Node:
		return String(_safe_get_property(source, "scene_file_path", ""))

	if source_path.ends_with(".tres"):
		var sibling_scene := "%s.tscn" % source_path.get_basename()
		if ResourceLoader.exists(sibling_scene):
			return sibling_scene

	for candidate in candidates:
		if _footprint_from_text(candidate) == "":
			return candidate
	return candidates[0] if not candidates.is_empty() else ""


static func _detect_footprint(source, source_path: String, candidates: Array[String]) -> String:
	for candidate in candidates:
		var footprint := _footprint_from_text(candidate)
		if footprint != "":
			return footprint

	if source_path.ends_with(".tres"):
		for footprint in COMMON_FOOTPRINTS:
			var inventory_scene := "%s_%s.tscn" % [source_path.get_basename(), footprint]
			if ResourceLoader.exists(inventory_scene):
				return footprint

	if source is Resource:
		for property_info in source.get_property_list():
			var property_name := String(property_info.get("name", ""))
			if property_name == "":
				continue
			var value = source.get(property_name)
			if typeof(value) in [TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH]:
				var parsed := _footprint_from_text(String(value))
				if parsed != "":
					return parsed

	return ""


static func _footprint_from_text(text: String) -> String:
	var basename := text.get_file().get_basename()
	var marker_index := basename.rfind("_")
	if marker_index == -1:
		return ""
	var suffix := basename.substr(marker_index + 1)
	var parts := suffix.split("x", false)
	if parts.size() != 2:
		return ""
	if not String(parts[0]).is_valid_int() or not String(parts[1]).is_valid_int():
		return ""
	return "%sx%s" % [parts[0], parts[1]]


static func _safe_get_property(obj: Object, property_name: String, fallback):
	if obj == null:
		return fallback
	for property_info in obj.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return obj.get(property_name)
	return fallback


static func _push_unique_string(target: Array[String], value: String) -> void:
	var trimmed := value.strip_edges()
	if trimmed == "" or target.has(trimmed):
		return
	target.append(trimmed)


static func _string_array(value) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for entry in value:
			out.append(String(entry))
	return out


static func _value_or_placeholder(value: String) -> String:
	return value if value.strip_edges() != "" else "<empty>"
