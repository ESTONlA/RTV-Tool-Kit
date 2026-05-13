extends RefCounted

const LOADABLE_EXTENSIONS := {
	"tscn": "Scene",
	"scn": "Scene",
	"tres": "Resource",
	"res": "Resource",
	"material": "Material",
	"gd": "Script",
	"gdshader": "Shader",
	"shader": "Shader",
	"png": "Texture",
	"jpg": "Texture",
	"jpeg": "Texture",
	"webp": "Texture",
	"obj": "Mesh",
	"mesh": "Mesh",
}

const TYPE_FILTERS := {
	"All": [],
	"Scenes": ["tscn", "scn"],
	"Resources": ["tres", "res"],
	"Textures": ["png", "jpg", "jpeg", "webp"],
	"Meshes": ["obj", "mesh"],
	"Materials": ["material"],
	"Scripts": ["gd"],
	"Shaders": ["gdshader", "shader"],
}

const SKIP_DIRS := {
	".godot": true,
	".git": true,
	"dist": true,
}


static func build_index(root_path: String = "res://") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_scan_dir(root_path, out)
	out.sort_custom(func(a, b): return String(a.get("path", "")).to_lower() < String(b.get("path", "")).to_lower())
	return out


static func matches_filter(entry: Dictionary, filter_text: String, type_filter: String) -> bool:
	if entry.is_empty():
		return false

	var ext := String(entry.get("ext", ""))
	var allowed_exts: Array = TYPE_FILTERS.get(type_filter, [])
	if not allowed_exts.is_empty() and not allowed_exts.has(ext):
		return false

	if filter_text == "":
		return true

	var search := "%s %s %s %s" % [
		String(entry.get("path", "")),
		String(entry.get("name", "")),
		String(entry.get("kind", "")),
		ext,
	]
	return search.to_lower().contains(filter_text.to_lower())


static func describe_path(path: String) -> Dictionary:
	var description := {
		"path": path,
		"name": path.get_file(),
		"ext": path.get_extension().to_lower(),
		"kind": _kind_for_extension(path.get_extension().to_lower()),
		"exists": ResourceLoader.exists(path) or FileAccess.file_exists(path),
		"cached": false,
		"size": -1,
		"mtime": 0,
		"class_name": "",
		"script_path": "",
		"dependencies": [] as Array[String],
		"preview_text": "",
		"resource": null,
		"load_error": "",
	}

	if FileAccess.file_exists(path):
		description["size"] = FileAccess.get_size(path)
		description["mtime"] = FileAccess.get_modified_time(path)

	if ResourceLoader.has_cached(path):
		description["cached"] = true

	var ext := String(description.get("ext", ""))
	if LOADABLE_EXTENSIONS.has(ext):
		var resource = load(path)
		if resource != null:
			description["resource"] = resource
			description["class_name"] = resource.get_class()
			var script = resource.get_script()
			if script is Script:
				description["script_path"] = String(script.resource_path)
			var deps := ResourceLoader.get_dependencies(path)
			var dep_list: Array[String] = []
			for dep in deps:
				dep_list.append(String(dep))
			description["dependencies"] = dep_list
		else:
			description["load_error"] = "load(%s) returned null." % path

	if ext in ["gd", "gdshader", "shader", "tscn", "tres", "res"]:
		description["preview_text"] = _read_text_snippet(path)

	return description


static func _scan_dir(dir_path: String, out: Array[Dictionary]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var child_path := dir_path.path_join(entry)
			if dir.current_is_dir():
				if not SKIP_DIRS.has(entry):
					_scan_dir(child_path, out)
			else:
				var resource_entry := _make_entry(child_path)
				if not resource_entry.is_empty():
					out.append(resource_entry)
		entry = dir.get_next()
	dir.list_dir_end()


static func _make_entry(path: String) -> Dictionary:
	var ext := path.get_extension().to_lower()
	var kind := _kind_for_extension(ext)
	if kind == "":
		return {}

	return {
		"path": path,
		"name": path.get_file(),
		"dir": path.get_base_dir(),
		"ext": ext,
		"kind": kind,
	}


static func _kind_for_extension(ext: String) -> String:
	return String(LOADABLE_EXTENSIONS.get(ext, ""))


static func _read_text_snippet(path: String, max_chars: int = 5000) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	if text.length() > max_chars:
		text = text.substr(0, max_chars) + "\n\n... [truncated]"
	return text
