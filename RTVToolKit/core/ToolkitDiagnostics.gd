extends RefCounted

const MAX_SECTION_ITEMS := 40
const LOG_FILE_SOURCES := [
	{"label": "Conflict Report", "path": "user://modloader_conflicts.txt"},
	{"label": "Filescope Log", "path": "user://modloader_filescope.log"},
]


static func collect(tree: SceneTree, selected_node: Node) -> Dictionary:
	var loader := tree.root.get_node_or_null("ModLoader")
	var data := {
		"generated": Time.get_datetime_string_from_system(),
		"loader_present": loader != null,
		"loaded_mods": [],
		"autoloads": [],
		"hooks": [],
		"registry_entries": [],
		"override_entries": [],
		"script_overrides": [],
		"issues": [],
		"missing_resources": [],
		"failed_loads": [],
		"ownership": {
			"summary": {"vanilla": 0, "modded": 0, "spawned": 0},
			"selected": _classify_node_ownership(selected_node, {}, {}, {})
		},
	}

	if loader == null:
		data["report"] = build_report(data)
		return data

	var ui_entries: Array = _as_array(_read_member(loader, "_ui_mod_entries", []))
	ui_entries.sort_custom(func(a, b): return int(a.get("priority", 0)) < int(b.get("priority", 0)))

	var loaded_mod_ids: Dictionary = _as_dict(_read_member(loader, "_loaded_mod_ids", {}))
	var pending_autoloads: Array = _as_array(_read_member(loader, "_pending_autoloads", []))
	var hooks: Dictionary = _as_dict(_read_member(loader, "_hooks", {}))
	var override_registry: Dictionary = _as_dict(_read_member(loader, "_override_registry", {}))
	var mod_analysis: Dictionary = _as_dict(_read_member(loader, "_mod_script_analysis", {}))
	var archive_file_sets: Dictionary = _as_dict(_read_member(loader, "_archive_file_sets", {}))
	var pending_script_overrides: Array = _as_array(_read_member(loader, "_pending_script_overrides", []))
	var applied_script_overrides: Dictionary = _as_dict(_read_member(loader, "_applied_script_overrides", {}))
	var report_lines: Array = _stringify_array(_as_array(_read_member(loader, "_report_lines", [])))

	var mod_name_by_archive := {}
	for raw_entry in ui_entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		mod_name_by_archive[String(entry.get("file_name", ""))] = String(entry.get("mod_name", ""))

	var autoloads := _build_autoload_entries(pending_autoloads)
	var hook_entries := _build_hook_entries(hooks)
	var override_entries := _build_override_entries(override_registry)
	var script_override_entries := _build_script_override_entries(pending_script_overrides)
	var registry_entries := _build_registry_entries()
	var mod_path_owners := _build_mod_path_owners(archive_file_sets, mod_name_by_archive)
	var validations := _validate_loader_paths(autoloads, script_override_entries)
	var log_alerts := _collect_log_alerts(report_lines)
	for source in LOG_FILE_SOURCES:
		log_alerts.append_array(_collect_log_alerts(_read_text_lines(String(source.get("path", ""))), String(source.get("label", ""))))

	var issues: Array = []
	var seen_issue_ids := {}
	_collect_mod_warnings(ui_entries, issues, seen_issue_ids)
	_collect_override_conflicts(override_entries, issues, seen_issue_ids)
	_collect_suspicious_analysis(mod_analysis, issues, seen_issue_ids)
	_collect_validation_issues(validations, issues, seen_issue_ids)
	_collect_log_issues(log_alerts, issues, seen_issue_ids)
	issues.sort_custom(func(a, b): return _issue_sort_rank(a) < _issue_sort_rank(b))

	var loaded_mods := _build_loaded_mods(
		ui_entries,
		loaded_mod_ids,
		autoloads,
		override_entries,
		script_override_entries,
		mod_analysis,
		issues
	)
	var ownership := _build_ownership_snapshot(tree.root, selected_node, mod_path_owners, override_registry, applied_script_overrides)

	data["loaded_mods"] = loaded_mods
	data["autoloads"] = autoloads
	data["hooks"] = hook_entries
	data["registry_entries"] = registry_entries
	data["override_entries"] = override_entries
	data["script_overrides"] = script_override_entries
	data["issues"] = issues
	data["missing_resources"] = validations.get("missing_resources", [])
	data["failed_loads"] = _merge_alert_lists(validations.get("failed_loads", []), log_alerts)
	data["ownership"] = ownership
	data["report"] = build_report(data)
	return data


static func build_report(data: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("RTV Tool Kit diagnostics")
	lines.append("Generated: %s" % String(data.get("generated", "")))
	lines.append("ModLoader present: %s" % _format_bool(bool(data.get("loader_present", false))))
	lines.append("")

	_append_loaded_mods_section(lines, _as_array(data.get("loaded_mods", [])))
	_append_autoload_section(lines, _as_array(data.get("autoloads", [])))
	_append_hook_section(lines, _as_array(data.get("hooks", [])))
	_append_registry_section(lines, _as_array(data.get("registry_entries", [])))
	_append_override_section(lines, _as_array(data.get("override_entries", [])))
	_append_script_override_section(lines, _as_array(data.get("script_overrides", [])))
	_append_ownership_section(lines, _as_dict(data.get("ownership", {})))
	_append_issue_section(lines, _as_array(data.get("issues", [])))
	_append_failed_load_section(lines, _as_array(data.get("missing_resources", [])), _as_array(data.get("failed_loads", [])))

	return "\n".join(lines)


static func build_mod_detail(mod_data: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Mod")
	lines.append("Name: %s" % _value_or_placeholder(String(mod_data.get("mod_name", ""))))
	lines.append("ID: %s" % _value_or_placeholder(String(mod_data.get("mod_id", ""))))
	lines.append("Version: %s" % _value_or_placeholder(String(mod_data.get("version", ""))))
	lines.append("Priority: %s" % str(mod_data.get("priority", 0)))
	lines.append("Enabled: %s" % _format_bool(bool(mod_data.get("enabled", false))))
	lines.append("Loaded: %s" % _format_bool(bool(mod_data.get("loaded", false))))
	lines.append("Source: %s" % _value_or_placeholder(String(mod_data.get("file_name", ""))))
	lines.append("Path: %s" % _value_or_placeholder(String(mod_data.get("full_path", ""))))
	lines.append("")

	var warnings := _stringify_array(_as_array(mod_data.get("warnings", [])))
	lines.append("Warnings: %d" % warnings.size())
	for warning in warnings:
		lines.append("- %s" % warning)

	lines.append("")
	var autoloads := _as_array(mod_data.get("autoloads", []))
	lines.append("Autoloads: %d" % autoloads.size())
	for autoload in autoloads:
		if autoload is Dictionary:
			var early_tag := " [EARLY]" if bool(autoload.get("is_early", false)) else ""
			lines.append("- %s -> %s%s" % [
				String(autoload.get("name", "")),
				String(autoload.get("path", "")),
				early_tag,
			])

	lines.append("")
	var override_paths := _stringify_array(_as_array(mod_data.get("override_paths", [])))
	lines.append("Claimed Paths: %d" % override_paths.size())
	for path in _slice_strings(override_paths, MAX_SECTION_ITEMS):
		lines.append("- %s" % path)
	if override_paths.size() > MAX_SECTION_ITEMS:
		lines.append("- ... (%d more)" % (override_paths.size() - MAX_SECTION_ITEMS))

	lines.append("")
	var script_overrides := _as_array(mod_data.get("script_overrides", []))
	lines.append("Script Overrides: %d" % script_overrides.size())
	for entry in script_overrides:
		if entry is Dictionary:
			lines.append("- %s <- %s" % [
				String(entry.get("vanilla_path", "")),
				String(entry.get("mod_script_path", "")),
			])

	lines.append("")
	var analysis := _as_dict(mod_data.get("analysis", {}))
	var hook_calls := _as_array(analysis.get("hook_calls", []))
	lines.append("Hook Intents: %d" % hook_calls.size())
	for hook_call in hook_calls:
		if hook_call is Dictionary:
			lines.append("- %s-%s" % [
				String(hook_call.get("prefix", "")),
				String(hook_call.get("method", "")),
			])

	lines.append("")
	lines.append("Analysis")
	lines.append("- dynamic override: %s" % _format_bool(bool(analysis.get("uses_dynamic_override", false))))
	lines.append("- calls base(): %s" % _format_bool(bool(analysis.get("calls_base", false))))
	lines.append("- gd files: %s" % str(analysis.get("total_gd_files", 0)))

	var lifecycle := _stringify_array(_as_array(analysis.get("lifecycle_no_super", [])))
	if not lifecycle.is_empty():
		lines.append("- lifecycle without super(): %s" % ", ".join(lifecycle))

	var extends_paths := _stringify_array(_as_array(analysis.get("extends_paths", [])))
	if not extends_paths.is_empty():
		lines.append("- extends paths: %s" % ", ".join(_slice_strings(extends_paths, 6)))

	var preload_paths := _stringify_array(_as_array(analysis.get("preload_paths", [])))
	if not preload_paths.is_empty():
		lines.append("- preload paths: %s" % ", ".join(_slice_strings(preload_paths, 6)))

	var issue_titles := _stringify_array(_as_array(mod_data.get("issue_titles", [])))
	if not issue_titles.is_empty():
		lines.append("")
		lines.append("Diagnostics Issues")
		for title in issue_titles:
			lines.append("- %s" % title)

	return "\n".join(lines)


static func build_issue_detail(issue: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Issue")
	lines.append("Severity: %s" % _value_or_placeholder(String(issue.get("severity", ""))))
	lines.append("Category: %s" % _value_or_placeholder(String(issue.get("category", ""))))
	lines.append("Title: %s" % _value_or_placeholder(String(issue.get("title", ""))))
	lines.append("Source: %s" % _value_or_placeholder(String(issue.get("source", ""))))
	if String(issue.get("mod_name", "")) != "":
		lines.append("Mod: %s" % String(issue.get("mod_name", "")))
	lines.append("")
	lines.append(_value_or_placeholder(String(issue.get("summary", ""))))

	var details := _stringify_array(_as_array(issue.get("details", [])))
	if not details.is_empty():
		lines.append("")
		lines.append("Details")
		for detail in details:
			lines.append("- %s" % detail)

	return "\n".join(lines)


static func build_default_detail(data: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Diagnostics overview")
	lines.append("Loaded mods: %d" % _as_array(data.get("loaded_mods", [])).size())
	lines.append("Autoloads: %d" % _as_array(data.get("autoloads", [])).size())
	lines.append("Active hooks: %d" % _as_array(data.get("hooks", [])).size())
	lines.append("Override claims: %d" % _as_array(data.get("override_entries", [])).size())
	lines.append("Issues: %d" % _as_array(data.get("issues", [])).size())

	var ownership := _as_dict(data.get("ownership", {}))
	var summary := _as_dict(ownership.get("summary", {}))
	lines.append("")
	lines.append("Ownership")
	lines.append("- vanilla: %d" % int(summary.get("vanilla", 0)))
	lines.append("- modded: %d" % int(summary.get("modded", 0)))
	lines.append("- spawned: %d" % int(summary.get("spawned", 0)))

	var selected := _as_dict(ownership.get("selected", {}))
	if not selected.is_empty():
		lines.append("")
		lines.append("Selected Node")
		lines.append("- kind: %s" % _value_or_placeholder(String(selected.get("kind", ""))))
		lines.append("- path: %s" % _value_or_placeholder(String(selected.get("path", ""))))
		lines.append("- script: %s" % _value_or_placeholder(String(selected.get("script_path", ""))))
		lines.append("- scene: %s" % _value_or_placeholder(String(selected.get("scene_path", ""))))
		var owners := _stringify_array(_as_array(selected.get("owners", [])))
		if not owners.is_empty():
			lines.append("- owners: %s" % ", ".join(owners))

	return "\n".join(lines)


static func _build_autoload_entries(raw_autoloads: Array) -> Array:
	var entries: Array = []
	for raw_entry in raw_autoloads:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		entries.append({
			"mod_name": String(entry.get("mod_name", "")),
			"name": String(entry.get("name", "")),
			"path": String(entry.get("path", "")),
			"is_early": bool(entry.get("is_early", false)),
		})
	entries.sort_custom(func(a, b):
		var a_name := String(a.get("mod_name", "")).to_lower()
		var b_name := String(b.get("mod_name", "")).to_lower()
		if a_name != b_name:
			return a_name < b_name
		return String(a.get("name", "")).to_lower() < String(b.get("name", "")).to_lower()
	)
	return entries


static func _build_hook_entries(raw_hooks: Dictionary) -> Array:
	var entries: Array = []
	var hook_names := raw_hooks.keys()
	hook_names.sort()
	for raw_name in hook_names:
		var hook_name := String(raw_name)
		var callbacks := _as_array(raw_hooks.get(hook_name, []))
		var owners: Array[String] = []
		for callback_entry in callbacks:
			if not (callback_entry is Dictionary):
				continue
			var callback_value = callback_entry.get("callback")
			if typeof(callback_value) != TYPE_CALLABLE:
				continue
			var callback: Callable = callback_value
			var owner_text := _callable_owner_text(callback)
			if owner_text != "" and not owners.has(owner_text):
				owners.append(owner_text)
		entries.append({
			"name": hook_name,
			"callback_count": callbacks.size(),
			"owners": owners,
		})
	return entries


static func _build_override_entries(raw_registry: Dictionary) -> Array:
	var entries: Array = []
	var paths := raw_registry.keys()
	paths.sort()
	for raw_path in paths:
		var path := String(raw_path)
		var raw_claims := _as_array(raw_registry.get(path, []))
		var claims: Array = []
		for claim_entry in raw_claims:
			if not (claim_entry is Dictionary):
				continue
			var claim: Dictionary = claim_entry
			claims.append({
				"mod_name": String(claim.get("mod_name", "")),
				"archive": String(claim.get("archive", "")),
				"load_index": int(claim.get("load_index", -1)),
			})
		claims.sort_custom(func(a, b): return int(a.get("load_index", 0)) < int(b.get("load_index", 0)))
		var winning_mod := ""
		if not claims.is_empty():
			winning_mod = String(claims[claims.size() - 1].get("mod_name", ""))
		entries.append({
			"path": path,
			"claims": claims,
			"conflict": claims.size() > 1,
			"winning_mod": winning_mod,
		})
	return entries


static func _build_script_override_entries(raw_overrides: Array) -> Array:
	var entries: Array = []
	for raw_entry in raw_overrides:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		entries.append({
			"mod_name": String(entry.get("mod_name", "")),
			"vanilla_path": String(entry.get("vanilla_path", "")),
			"mod_script_path": String(entry.get("mod_script_path", "")),
			"priority": int(entry.get("priority", 0)),
		})
	entries.sort_custom(func(a, b):
		if int(a.get("priority", 0)) != int(b.get("priority", 0)):
			return int(a.get("priority", 0)) < int(b.get("priority", 0))
		return String(a.get("mod_name", "")).to_lower() < String(b.get("mod_name", "")).to_lower()
	)
	return entries


static func _build_registry_entries() -> Array:
	var entries: Array = []
	var meta_names := Engine.get_meta_list()
	for raw_name in meta_names:
		var meta_name := String(raw_name)
		if not meta_name.begins_with("_rtv_"):
			continue
		var value = Engine.get_meta(meta_name)
		entries.append({
			"name": meta_name,
			"type": _type_name(typeof(value)),
			"summary": _describe_variant(value),
		})
	entries.sort_custom(func(a, b): return String(a.get("name", "")).to_lower() < String(b.get("name", "")).to_lower())
	return entries


static func _build_mod_path_owners(archive_file_sets: Dictionary, mod_name_by_archive: Dictionary) -> Dictionary:
	var owners := {}
	for raw_archive in archive_file_sets.keys():
		var archive_name := String(raw_archive)
		var mod_name := String(mod_name_by_archive.get(archive_name, archive_name))
		var path_set := _as_dict(archive_file_sets.get(raw_archive, {}))
		for raw_path in path_set.keys():
			var res_path := String(raw_path)
			if not owners.has(res_path):
				owners[res_path] = []
			var res_owners: Array = owners[res_path]
			if not res_owners.has(mod_name):
				res_owners.append(mod_name)
	return owners


static func _build_loaded_mods(
	ui_entries: Array,
	loaded_mod_ids: Dictionary,
	autoloads: Array,
	override_entries: Array,
	script_override_entries: Array,
	mod_analysis: Dictionary,
	issues: Array
) -> Array:
	var override_paths_by_mod := {}
	for entry in override_entries:
		if not (entry is Dictionary):
			continue
		var path := String(entry.get("path", ""))
		for claim in _as_array(entry.get("claims", [])):
			if not (claim is Dictionary):
				continue
			_append_unique_string(override_paths_by_mod, String(claim.get("mod_name", "")), path)

	var script_overrides_by_mod := {}
	for entry in script_override_entries:
		if not (entry is Dictionary):
			continue
		var mod_name := String(entry.get("mod_name", ""))
		if not script_overrides_by_mod.has(mod_name):
			script_overrides_by_mod[mod_name] = []
		(script_overrides_by_mod[mod_name] as Array).append(entry)

	var issue_titles_by_mod := {}
	for issue in issues:
		if not (issue is Dictionary):
			continue
		var mod_name := String(issue.get("mod_name", ""))
		if mod_name == "":
			continue
		_append_unique_string(issue_titles_by_mod, mod_name, String(issue.get("title", "")))

	var out: Array = []
	for raw_entry in ui_entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var mod_name := String(entry.get("mod_name", ""))
		var mod_id := String(entry.get("mod_id", ""))
		var mod_autoloads: Array = []
		for autoload in autoloads:
			if autoload is Dictionary and String(autoload.get("mod_name", "")) == mod_name:
				mod_autoloads.append(autoload)
		out.append({
			"mod_name": mod_name,
			"mod_id": mod_id,
			"version": String(entry.get("version", "")),
			"priority": int(entry.get("priority", 0)),
			"enabled": bool(entry.get("enabled", false)),
			"loaded": loaded_mod_ids.has(mod_id),
			"file_name": String(entry.get("file_name", "")),
			"full_path": String(entry.get("full_path", "")),
			"warnings": _as_array(entry.get("warnings", [])),
			"autoloads": mod_autoloads,
			"override_paths": _as_array(override_paths_by_mod.get(mod_name, [])),
			"script_overrides": _as_array(script_overrides_by_mod.get(mod_name, [])),
			"analysis": _as_dict(mod_analysis.get(mod_name, {})),
			"issue_titles": _as_array(issue_titles_by_mod.get(mod_name, [])),
		})
	return out


static func _build_ownership_snapshot(
	root: Node,
	selected_node: Node,
	mod_path_owners: Dictionary,
	override_registry: Dictionary,
	applied_script_overrides: Dictionary
) -> Dictionary:
	var summary := {"vanilla": 0, "modded": 0, "spawned": 0}
	var stack: Array = [root]
	while not stack.is_empty():
		var node = stack.pop_back()
		if node is Node:
			var ownership := _classify_node_ownership(node, mod_path_owners, override_registry, applied_script_overrides)
			var kind := String(ownership.get("kind", "vanilla"))
			if not summary.has(kind):
				summary[kind] = 0
			summary[kind] = int(summary.get(kind, 0)) + 1
			for child in node.get_children():
				if child is Node:
					stack.append(child)

	return {
		"summary": summary,
		"selected": _classify_node_ownership(selected_node, mod_path_owners, override_registry, applied_script_overrides),
	}


static func _classify_node_ownership(node: Node, mod_path_owners: Dictionary, override_registry: Dictionary, applied_script_overrides: Dictionary) -> Dictionary:
	if node == null:
		return {"kind": "none", "path": "", "owners": [], "reasons": [], "script_path": "", "scene_path": ""}

	var script_path := _resource_path(node.get_script())
	var scene_path := ""
	if _read_member(node, "scene_file_path", "") != null:
		scene_path = String(_read_member(node, "scene_file_path", ""))

	var reasons: Array[String] = []
	var owners: Array[String] = []
	for check_path in [script_path, scene_path]:
		var path := String(check_path)
		if path == "":
			continue
		for owner in _as_array(mod_path_owners.get(path, [])):
			var owner_name := String(owner)
			if owner_name != "" and not owners.has(owner_name):
				owners.append(owner_name)
		if override_registry.has(path):
			for claim in _as_array(override_registry.get(path, [])):
				if claim is Dictionary:
					var mod_name := String(claim.get("mod_name", ""))
					if mod_name != "" and not owners.has(mod_name):
						owners.append(mod_name)
			reasons.append("override claim on %s" % path)
		if applied_script_overrides.has(path):
			reasons.append("script override active on %s" % path)

	var has_origin := script_path != "" or scene_path != ""
	var kind := "vanilla"
	if not owners.is_empty() or not reasons.is_empty():
		kind = "modded"
	elif not has_origin:
		kind = "spawned"

	return {
		"kind": kind,
		"path": String(node.get_path()),
		"owners": owners,
		"reasons": reasons,
		"script_path": script_path,
		"scene_path": scene_path,
	}


static func _validate_loader_paths(autoloads: Array, script_overrides: Array) -> Dictionary:
	var missing_resources: Array = []
	var failed_loads: Array = []

	for autoload in autoloads:
		if not (autoload is Dictionary):
			continue
		var path := String(autoload.get("path", ""))
		if path == "" or _resource_exists(path):
			continue
		missing_resources.append({
			"source": "autoload",
			"mod_name": String(autoload.get("mod_name", "")),
			"path": path,
			"text": "%s -> %s" % [String(autoload.get("name", "")), path],
		})

	for entry in script_overrides:
		if not (entry is Dictionary):
			continue
		var vanilla_path := String(entry.get("vanilla_path", ""))
		var mod_script_path := String(entry.get("mod_script_path", ""))
		if vanilla_path != "" and not _resource_exists(vanilla_path):
			failed_loads.append({
				"source": "script_override",
				"mod_name": String(entry.get("mod_name", "")),
				"path": vanilla_path,
				"text": "Missing vanilla target: %s" % vanilla_path,
			})
		if mod_script_path != "" and not _resource_exists(mod_script_path):
			failed_loads.append({
				"source": "script_override",
				"mod_name": String(entry.get("mod_name", "")),
				"path": mod_script_path,
				"text": "Missing mod script: %s" % mod_script_path,
			})

	return {
		"missing_resources": missing_resources,
		"failed_loads": failed_loads,
	}


static func _collect_mod_warnings(ui_entries: Array, issues: Array, seen_issue_ids: Dictionary) -> void:
	for raw_entry in ui_entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		for warning_value in _as_array(entry.get("warnings", [])):
			var warning_text := String(warning_value)
			var issue := {
				"id": "modwarn:%s:%s" % [String(entry.get("mod_id", "")), warning_text],
				"severity": "Warning",
				"category": "Mod Warning",
				"title": "%s: %s" % [String(entry.get("mod_name", "")), warning_text],
				"summary": warning_text,
				"source": String(entry.get("file_name", "")),
				"mod_name": String(entry.get("mod_name", "")),
				"details": [
					"path=%s" % String(entry.get("full_path", "")),
					"enabled=%s" % _format_bool(bool(entry.get("enabled", false))),
				],
			}
			_push_issue(issues, seen_issue_ids, issue)


static func _collect_override_conflicts(override_entries: Array, issues: Array, seen_issue_ids: Dictionary) -> void:
	for entry in override_entries:
		if not (entry is Dictionary) or not bool(entry.get("conflict", false)):
			continue
		var details: Array[String] = []
		for claim in _as_array(entry.get("claims", [])):
			if not (claim is Dictionary):
				continue
			details.append("[%d] %s via %s" % [
				int(claim.get("load_index", 0)) + 1,
				String(claim.get("mod_name", "")),
				String(claim.get("archive", "")),
			])
		var issue := {
			"id": "conflict:%s" % String(entry.get("path", "")),
			"severity": "Critical",
			"category": "Override Conflict",
			"title": "Duplicate override claim: %s" % String(entry.get("path", "")),
			"summary": "Multiple mods claim the same resource path. Last loader wins.",
			"source": "ModLoader",
			"details": details,
		}
		_push_issue(issues, seen_issue_ids, issue)


static func _collect_suspicious_analysis(mod_analysis: Dictionary, issues: Array, seen_issue_ids: Dictionary) -> void:
	for raw_mod_name in mod_analysis.keys():
		var mod_name := String(raw_mod_name)
		var analysis := _as_dict(mod_analysis.get(raw_mod_name, {}))
		if bool(analysis.get("uses_dynamic_override", false)):
			_push_issue(issues, seen_issue_ids, {
				"id": "analysis:%s:dynamic_override" % mod_name,
				"severity": "Warning",
				"category": "Suspicious Script Pattern",
				"title": "%s uses dynamic take_over_path()" % mod_name,
				"summary": "Dynamic override patterns are harder to reason about and easier to break with other mods.",
				"source": "script analysis",
				"mod_name": mod_name,
				"details": _stringify_array(_as_array(analysis.get("extends_paths", []))),
			})
		var lifecycle := _stringify_array(_as_array(analysis.get("lifecycle_no_super", [])))
		if not lifecycle.is_empty():
			_push_issue(issues, seen_issue_ids, {
				"id": "analysis:%s:lifecycle_no_super" % mod_name,
				"severity": "Warning",
				"category": "Suspicious Script Pattern",
				"title": "%s lifecycle methods skip super()" % mod_name,
				"summary": "Lifecycle overrides without super() can break compatibility with other mods and base-game setup.",
				"source": "script analysis",
				"mod_name": mod_name,
				"details": lifecycle,
			})
		var class_names := _stringify_array(_as_array(analysis.get("class_names", [])))
		if not class_names.is_empty():
			_push_issue(issues, seen_issue_ids, {
				"id": "analysis:%s:class_names" % mod_name,
				"severity": "Warning",
				"category": "Class Name Override Risk",
				"title": "%s declares class_name scripts" % mod_name,
				"summary": "Class-name scripts are limited override targets and can collide with other mods.",
				"source": "script analysis",
				"mod_name": mod_name,
				"details": class_names,
			})


static func _collect_validation_issues(validations: Dictionary, issues: Array, seen_issue_ids: Dictionary) -> void:
	for item in _as_array(validations.get("missing_resources", [])):
		if not (item is Dictionary):
			continue
		_push_issue(issues, seen_issue_ids, {
			"id": "missing:%s" % String(item.get("path", "")),
			"severity": "Critical",
			"category": "Missing Resource",
			"title": "Missing autoload resource: %s" % String(item.get("path", "")),
			"summary": String(item.get("text", "")),
			"source": String(item.get("source", "")),
			"mod_name": String(item.get("mod_name", "")),
			"details": [],
		})
	for item in _as_array(validations.get("failed_loads", [])):
		if not (item is Dictionary):
			continue
		_push_issue(issues, seen_issue_ids, {
			"id": "loadfail:%s" % String(item.get("path", "")),
			"severity": "Critical",
			"category": "Failed Load",
			"title": String(item.get("text", "")),
			"summary": String(item.get("text", "")),
			"source": String(item.get("source", "")),
			"mod_name": String(item.get("mod_name", "")),
			"details": [],
		})


static func _collect_log_issues(log_alerts: Array, issues: Array, seen_issue_ids: Dictionary) -> void:
	for alert in log_alerts:
		if not (alert is Dictionary):
			continue
		_push_issue(issues, seen_issue_ids, {
			"id": "log:%s:%s" % [String(alert.get("source", "")), String(alert.get("text", ""))],
			"severity": String(alert.get("severity", "Warning")),
			"category": String(alert.get("category", "Loader Log")),
			"title": String(alert.get("text", "")),
			"summary": String(alert.get("text", "")),
			"source": String(alert.get("source", "")),
			"details": [],
		})


static func _collect_log_alerts(lines: Array, source: String = "Report Lines") -> Array:
	var alerts: Array = []
	for line_value in lines:
		var line := String(line_value).strip_edges()
		if line == "":
			continue
		var lower := line.to_lower()
		var category := ""
		if "invalid mod" in lower or "mount failed" in lower or "failed to load" in lower or "parse error" in lower:
			category = "Failed Load"
		elif "missing" in lower or "not found" in lower or "load() returned null" in lower or "empty source" in lower:
			category = "Missing Resource"
		elif "conflict:" in lower or "danger:" in lower or "bad zip:" in lower:
			category = "Conflict"
		elif "warning" in lower and ("hook" in lower or "override" in lower or "autoload" in lower):
			category = "Loader Warning"
		if category == "":
			continue
		alerts.append({
			"source": source,
			"category": category,
			"severity": "Critical" if category in ["Failed Load", "Missing Resource", "Conflict"] else "Warning",
			"text": line,
		})
	return alerts


static func _read_text_lines(path: String) -> Array:
	var lines: Array = []
	if path == "" or not FileAccess.file_exists(path):
		return lines
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return lines
	while not file.eof_reached():
		lines.append(file.get_line())
	file.close()
	return lines


static func _merge_alert_lists(primary: Array, secondary: Array) -> Array:
	var merged: Array = []
	for item in primary:
		merged.append(item)
	for item in secondary:
		if not (item is Dictionary):
			continue
		merged.append({
			"source": String(item.get("source", "")),
			"path": "",
			"mod_name": String(item.get("mod_name", "")),
			"text": String(item.get("text", "")),
		})
	return merged


static func _append_loaded_mods_section(lines: Array[String], mods: Array) -> void:
	lines.append("[Loaded Mods]")
	lines.append("Count: %d" % mods.size())
	for mod_entry in mods:
		if not (mod_entry is Dictionary):
			continue
		var loaded_tag := "loaded" if bool(mod_entry.get("loaded", false)) else "not loaded"
		var version := String(mod_entry.get("version", ""))
		var version_tag := " v%s" % version if version != "" else ""
		lines.append("- %s%s | %s | priority=%d" % [
			String(mod_entry.get("mod_name", "")),
			version_tag,
			loaded_tag,
			int(mod_entry.get("priority", 0)),
		])
	lines.append("")


static func _append_autoload_section(lines: Array[String], autoloads: Array) -> void:
	lines.append("[Autoloads]")
	lines.append("Count: %d" % autoloads.size())
	for entry in _slice_entries(autoloads, MAX_SECTION_ITEMS):
		if entry is Dictionary:
			var early_tag := " [EARLY]" if bool(entry.get("is_early", false)) else ""
			lines.append("- %s :: %s -> %s%s" % [
				String(entry.get("mod_name", "")),
				String(entry.get("name", "")),
				String(entry.get("path", "")),
				early_tag,
			])
	if autoloads.size() > MAX_SECTION_ITEMS:
		lines.append("- ... (%d more)" % (autoloads.size() - MAX_SECTION_ITEMS))
	lines.append("")


static func _append_hook_section(lines: Array[String], hooks: Array) -> void:
	lines.append("[Active Hooks]")
	lines.append("Count: %d" % hooks.size())
	for entry in _slice_entries(hooks, MAX_SECTION_ITEMS):
		if entry is Dictionary:
			var owner_text := ", ".join(_stringify_array(_as_array(entry.get("owners", []))))
			var suffix := ""
			if owner_text != "":
				suffix = " | " + owner_text
			lines.append("- %s | callbacks=%d%s" % [
				String(entry.get("name", "")),
				int(entry.get("callback_count", 0)),
				suffix,
			])
	if hooks.size() > MAX_SECTION_ITEMS:
		lines.append("- ... (%d more)" % (hooks.size() - MAX_SECTION_ITEMS))
	lines.append("")


static func _append_registry_section(lines: Array[String], entries: Array) -> void:
	lines.append("[Registry Patches]")
	lines.append("Count: %d" % entries.size())
	for entry in _slice_entries(entries, MAX_SECTION_ITEMS):
		if entry is Dictionary:
			lines.append("- %s | %s | %s" % [
				String(entry.get("name", "")),
				String(entry.get("type", "")),
				String(entry.get("summary", "")),
			])
	if entries.size() > MAX_SECTION_ITEMS:
		lines.append("- ... (%d more)" % (entries.size() - MAX_SECTION_ITEMS))
	lines.append("")


static func _append_override_section(lines: Array[String], entries: Array) -> void:
	lines.append("[Override Claims]")
	lines.append("Count: %d" % entries.size())
	for entry in _slice_entries(entries, MAX_SECTION_ITEMS):
		if entry is Dictionary:
			var claim_names: Array[String] = []
			for claim in _as_array(entry.get("claims", [])):
				if claim is Dictionary:
					claim_names.append(String(claim.get("mod_name", "")))
			var conflict_tag := " [CONFLICT]" if bool(entry.get("conflict", false)) else ""
			lines.append("- %s%s | %s" % [
				String(entry.get("path", "")),
				conflict_tag,
				", ".join(claim_names),
			])
	if entries.size() > MAX_SECTION_ITEMS:
		lines.append("- ... (%d more)" % (entries.size() - MAX_SECTION_ITEMS))
	lines.append("")


static func _append_script_override_section(lines: Array[String], entries: Array) -> void:
	lines.append("[Script Overrides]")
	lines.append("Count: %d" % entries.size())
	for entry in _slice_entries(entries, MAX_SECTION_ITEMS):
		if entry is Dictionary:
			lines.append("- %s :: %s <- %s" % [
				String(entry.get("mod_name", "")),
				String(entry.get("vanilla_path", "")),
				String(entry.get("mod_script_path", "")),
			])
	if entries.size() > MAX_SECTION_ITEMS:
		lines.append("- ... (%d more)" % (entries.size() - MAX_SECTION_ITEMS))
	lines.append("")


static func _append_ownership_section(lines: Array[String], ownership: Dictionary) -> void:
	lines.append("[Object Ownership]")
	var summary := _as_dict(ownership.get("summary", {}))
	lines.append("vanilla=%d modded=%d spawned=%d" % [
		int(summary.get("vanilla", 0)),
		int(summary.get("modded", 0)),
		int(summary.get("spawned", 0)),
	])
	var selected := _as_dict(ownership.get("selected", {}))
	if not selected.is_empty():
		lines.append("Selected: %s | script=%s | scene=%s" % [
			_value_or_placeholder(String(selected.get("kind", ""))),
			_value_or_placeholder(String(selected.get("script_path", ""))),
			_value_or_placeholder(String(selected.get("scene_path", ""))),
		])
		var owners := _stringify_array(_as_array(selected.get("owners", [])))
		if not owners.is_empty():
			lines.append("Owners: %s" % ", ".join(owners))
	lines.append("")


static func _append_issue_section(lines: Array[String], issues: Array) -> void:
	lines.append("[Conflicts And Diagnostics]")
	lines.append("Count: %d" % issues.size())
	for issue in _slice_entries(issues, MAX_SECTION_ITEMS):
		if issue is Dictionary:
			lines.append("- [%s] %s" % [
				String(issue.get("severity", "")),
				String(issue.get("title", "")),
			])
	if issues.size() > MAX_SECTION_ITEMS:
		lines.append("- ... (%d more)" % (issues.size() - MAX_SECTION_ITEMS))
	lines.append("")


static func _append_failed_load_section(lines: Array[String], missing_resources: Array, failed_loads: Array) -> void:
	lines.append("[Missing And Failed Loads]")
	lines.append("Missing resources: %d" % missing_resources.size())
	for entry in _slice_entries(missing_resources, 12):
		if entry is Dictionary:
			lines.append("- %s" % String(entry.get("text", "")))
	lines.append("Load failures and alerts: %d" % failed_loads.size())
	for entry in _slice_entries(failed_loads, 12):
		if entry is Dictionary:
			lines.append("- %s" % String(entry.get("text", "")))
	lines.append("")


static func _push_issue(issues: Array, seen_issue_ids: Dictionary, issue: Dictionary) -> void:
	var issue_id := String(issue.get("id", ""))
	if issue_id == "" or seen_issue_ids.has(issue_id):
		return
	seen_issue_ids[issue_id] = true
	issues.append(issue)


static func _issue_sort_rank(issue: Dictionary) -> int:
	var severity := String(issue.get("severity", "")).to_lower()
	var base := 20
	if severity == "critical":
		base = 0
	elif severity == "warning":
		base = 10
	return base * 10000 + String(issue.get("title", "")).length()


static func _callable_owner_text(callback: Callable) -> String:
	var owner = callback.get_object()
	if owner == null:
		return "<static>.%s" % callback.get_method()
	if owner is Node:
		return "%s %s.%s" % [String((owner as Node).get_path()), owner.get_class(), callback.get_method()]
	return "%s.%s" % [owner.get_class(), callback.get_method()]


static func _resource_exists(path: String) -> bool:
	if path == "":
		return false
	if ResourceLoader.exists(path):
		return true
	return FileAccess.file_exists(path)


static func _resource_path(resource) -> String:
	if resource == null:
		return ""
	if typeof(resource) != TYPE_OBJECT:
		return ""
	if resource is Resource:
		return String((resource as Resource).resource_path)
	return ""


static func _describe_variant(value) -> String:
	match typeof(value):
		TYPE_ARRAY:
			return "Array[%d]" % (value as Array).size()
		TYPE_DICTIONARY:
			return "Dictionary[%d]" % (value as Dictionary).size()
		TYPE_OBJECT:
			if value == null:
				return "null"
			if value is Resource:
				return "%s %s" % [value.get_class(), _value_or_placeholder(String((value as Resource).resource_path))]
			return value.get_class()
		TYPE_STRING, TYPE_STRING_NAME:
			return _value_or_placeholder(String(value))
		_:
			return str(value)


static func _read_member(obj: Object, property_name: String, fallback):
	if obj == null:
		return fallback
	for property_info in obj.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return obj.get(property_name)
	return fallback


static func _type_name(type_id: int) -> String:
	match type_id:
		TYPE_ARRAY:
			return "Array"
		TYPE_BOOL:
			return "bool"
		TYPE_DICTIONARY:
			return "Dictionary"
		TYPE_FLOAT:
			return "float"
		TYPE_INT:
			return "int"
		TYPE_NIL:
			return "Nil"
		TYPE_OBJECT:
			return "Object"
		TYPE_STRING:
			return "String"
		TYPE_STRING_NAME:
			return "StringName"
		_:
			return str(type_id)


static func _format_bool(value: bool) -> String:
	return "true" if value else "false"


static func _value_or_placeholder(text: String) -> String:
	return text if text != "" else "<empty>"


static func _append_unique_string(target: Dictionary, key: String, value: String) -> void:
	if key == "" or value == "":
		return
	if not target.has(key):
		target[key] = []
	var values: Array = target[key]
	if not values.has(value):
		values.append(value)


static func _slice_entries(entries: Array, limit: int) -> Array:
	if entries.size() <= limit:
		return entries
	return entries.slice(0, limit)


static func _slice_strings(entries: Array[String], limit: int) -> Array[String]:
	if entries.size() <= limit:
		return entries
	var out: Array[String] = []
	for index in range(limit):
		out.append(entries[index])
	return out


static func _stringify_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(String(value))
	return out


static func _as_array(value) -> Array:
	return value if value is Array else []


static func _as_dict(value) -> Dictionary:
	return value if value is Dictionary else {}
