extends RefCounted

const LOG_SOURCES := [
	{"label": "Godot Log", "path": "user://logs/godot.log"},
	{"label": "Filescope Log", "path": "user://modloader_filescope.log"},
	{"label": "Conflict Report", "path": "user://modloader_conflicts.txt"},
]

const MAX_TAIL_LINES := 240


static func collect() -> Dictionary:
	var entries: Array[Dictionary] = []
	var next_order := 1
	for source in LOG_SOURCES:
		next_order = _collect_source(entries, String(source.get("label", "")), String(source.get("path", "")), next_order)

	entries.sort_custom(func(a, b): return int(a.get("order", 0)) > int(b.get("order", 0)))
	return {
		"entries": entries,
		"report": build_report(entries),
	}


static func build_report(entries: Array) -> String:
	var critical_count := 0
	var error_count := 0
	var warning_count := 0
	for entry in entries:
		var severity := String(entry.get("severity", ""))
		match severity:
			"critical":
				critical_count += 1
			"error":
				error_count += 1
			"warning":
				warning_count += 1

	var lines: Array[String] = []
	lines.append("Runtime Errors")
	lines.append("Generated: %s" % Time.get_datetime_string_from_system())
	lines.append("Critical: %d | Errors: %d | Warnings: %d" % [critical_count, error_count, warning_count])
	lines.append("")

	if entries.is_empty():
		lines.append("No matching runtime alerts found in the tracked logs.")
		return "\n".join(lines)

	var limit := min(entries.size(), 60)
	for index in range(limit):
		var entry: Dictionary = entries[index]
		lines.append("[%s] %s | %s" % [
			String(entry.get("severity", "")).to_upper(),
			String(entry.get("source", "")),
			String(entry.get("message", "")),
		])
	if entries.size() > limit:
		lines.append("... (%d more)" % (entries.size() - limit))

	return "\n".join(lines)


static func build_detail(entry: Dictionary) -> String:
	if entry.is_empty():
		return "No runtime error selected."

	var lines: Array[String] = []
	lines.append("Source: %s" % String(entry.get("source", "")))
	lines.append("Severity: %s" % String(entry.get("severity", "")).capitalize())
	lines.append("Line: %s" % str(entry.get("line_number", 0)))
	lines.append("")
	lines.append(String(entry.get("message", "")))

	var detail_lines: Array = entry.get("detail_lines", [])
	if not detail_lines.is_empty():
		lines.append("")
		lines.append("Context")
		for detail in detail_lines:
			lines.append(String(detail))

	return "\n".join(lines)


static func _collect_source(entries: Array[Dictionary], source_label: String, user_path: String, order_start: int) -> int:
	if not FileAccess.file_exists(user_path):
		return order_start

	var file := FileAccess.open(user_path, FileAccess.READ)
	if file == null:
		return order_start

	var lines := file.get_as_text().split("\n")
	var start := max(lines.size() - MAX_TAIL_LINES, 0)
	var next_order := order_start
	var current_entry: Dictionary = {}

	for index in range(start, lines.size()):
		var line := String(lines[index]).strip_edges()
		if line == "":
			continue

		if _is_context_line(line):
			if not current_entry.is_empty():
				var details: Array = current_entry.get("detail_lines", [])
				details.append(line)
				current_entry["detail_lines"] = details
			continue

		var severity := _classify_line(line)
		if severity == "":
			continue

		current_entry = {
			"id": "%s:%d" % [source_label, index + 1],
			"source": source_label,
			"severity": severity,
			"message": line,
			"line_number": index + 1,
			"order": next_order,
			"detail_lines": [] as Array[String],
		}
		next_order += 1
		entries.append(current_entry)

	return next_order


static func _is_context_line(line: String) -> bool:
	var lower := line.to_lower()
	return line.begins_with("at:") or line.begins_with("   at:") or lower.begins_with("stack") or lower.begins_with("caused by")


static func _classify_line(line: String) -> String:
	var lower := line.to_lower()
	if "critical" in lower:
		return "critical"
	if lower.begins_with("script error:") or lower.begins_with("error:") or " parse error" in lower or "failed loading resource" in lower or "error loading resource" in lower:
		return "error"
	if lower.begins_with("warning:") or " warning" in lower:
		return "warning"
	if "mount failed" in lower or "failed to load" in lower or "invalid mod" in lower:
		return "error"
	return ""
