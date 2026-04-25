extends Control

signal status_changed(text: String)
signal report_changed(report: Dictionary)

const ToolkitPreview = preload("res://RTVToolKit/core/ToolkitPreview.gd")
const ToolkitTheme = preload("res://RTVToolKit/ui/ToolkitTheme.gd")

const DEFAULT_CAMERA_POSITION := Vector3(2.2, 1.6, 4.6)
const DEFAULT_FOCUS_POINT := Vector3.ZERO

var _viewport_container: SubViewportContainer
var _viewport: SubViewport
var _overlay_panel: PanelContainer
var _overlay_label: Label

var _scene_root: Node
var _world_root: Node3D
var _axis_root: Node3D
var _content_3d_root: Node3D
var _marker_3d_root: Node3D
var _content_2d_root: Node2D
var _ui_root: Control
var _texture_rect: TextureRect
var _floor_mesh: MeshInstance3D

var _camera_3d: Camera3D
var _camera_2d: Camera2D
var _environment: WorldEnvironment
var _sun_light: DirectionalLight3D
var _fill_light: OmniLight3D

var _current_content: Node
var _current_mode := "empty"
var _current_report := {}
var _focus_point := DEFAULT_FOCUS_POINT
var _content_radius := 1.8
var _orbit_distance := 4.6
var _fly_speed := 6.0
var _capturing_mouse := false
var _orbiting := false
var _panning := false
var _hovered := false
var _auto_spin := false
var _markers_visible := true
var _floor_visible := true
var _axes_visible := true
var _camera_yaw := -18.0
var _camera_pitch := -10.0
var _marker_labels: Array[Label3D] = []
var _special_entries: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	set_process(true)
	mouse_entered.connect(_on_mouse_entered_preview)
	mouse_exited.connect(_on_mouse_exited_preview)
	_build_ui()
	_sync_viewport_size()
	clear_preview()


func _exit_tree() -> void:
	release_pointer_capture()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_viewport_size()


func _process(delta: float) -> void:
	if _current_mode == "3d" and _camera_3d != null and _should_process_keyboard_navigation():
		var basis := _camera_3d.global_transform.basis
		var move := Vector3.ZERO
		if Input.is_key_pressed(KEY_W):
			move += -basis.z
		if Input.is_key_pressed(KEY_S):
			move += basis.z
		if Input.is_key_pressed(KEY_A):
			move += -basis.x
		if Input.is_key_pressed(KEY_D):
			move += basis.x
		if Input.is_key_pressed(KEY_Q):
			move += -basis.y
		if Input.is_key_pressed(KEY_E):
			move += basis.y

		if move != Vector3.ZERO:
			var speed := _fly_speed * delta * (2.5 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
			var delta_move := move.normalized() * speed
			_camera_3d.global_position += delta_move
			_focus_point += delta_move

	if _auto_spin and _current_mode == "3d" and not _orbiting and not _panning:
		_orbit_camera(Vector2(-18.0 * delta, 0.0))

	for marker in _marker_labels:
		if marker != null and is_instance_valid(marker) and _camera_3d != null:
			marker.look_at(_camera_3d.global_position, Vector3.UP, true)

	_update_overlay_text()


func load_source(source, path_hint: String = "", source_label: String = "") -> Dictionary:
	_build_ui()
	var descriptor := ToolkitPreview.describe_source(source, path_hint, source_label)
	if not bool(descriptor.get("ok", false)):
		return clear_preview(String(descriptor.get("error", "No preview source.")))

	var build := ToolkitPreview.create_preview_instance(source, descriptor)
	if not bool(build.get("ok", false)):
		var error_text := String(build.get("error", "Preview build failed."))
		return clear_preview(error_text, descriptor)

	_clear_preview_content()

	var texture = build.get("texture")
	if build.get("mode", "") == "texture" and texture is Texture2D:
		_current_mode = "texture"
		_texture_rect.texture = texture
		_texture_rect.visible = true
		_camera_2d.enabled = false
		_current_report = {
			"ok": true,
			"summary_lines": descriptor.get("summary_lines", []),
			"scene_lines": [
				"Preview Mode: Texture",
				"Size: %dx%d" % [int((texture as Texture2D).get_size().x), int((texture as Texture2D).get_size().y)],
				"Use the icon panel and summary to inspect the resource.",
			],
			"icon": descriptor.get("icon"),
			"mode": _current_mode,
			"resource_path": descriptor.get("resource_path", ""),
			"scene_path": descriptor.get("scene_path", ""),
			"special_entries": [],
		}
		_emit_report()
		_emit_status("Loaded texture preview.")
		return _current_report

	var preview_node = build.get("node")
	if not (preview_node is Node):
		var fallback_error := "Preview content could not be instantiated."
		return clear_preview(fallback_error, descriptor)

	_current_content = preview_node
	_current_mode = String(build.get("mode", "node"))
	match _current_mode:
		"3d":
			_content_3d_root.add_child(preview_node)
			_camera_2d.enabled = false
			var stats3d := ToolkitPreview.inspect_scene(preview_node)
			_current_report = {
				"ok": true,
				"summary_lines": descriptor.get("summary_lines", []),
				"scene_lines": ToolkitPreview.build_scene_report_lines(stats3d, "3D"),
				"icon": descriptor.get("icon"),
				"mode": _current_mode,
				"resource_path": descriptor.get("resource_path", ""),
				"scene_path": descriptor.get("scene_path", ""),
				"special_entries": stats3d.get("special_entries", []),
			}
			_special_entries = _as_special_entries(stats3d.get("special_entries", []))
			_apply_markers(stats3d.get("marker_specs", []))
			frame_content()
		"2d":
			_content_2d_root.add_child(preview_node)
			_camera_2d.enabled = true
			_frame_2d_content(preview_node)
			var stats2d := ToolkitPreview.inspect_scene(preview_node)
			_current_report = {
				"ok": true,
				"summary_lines": descriptor.get("summary_lines", []),
				"scene_lines": ToolkitPreview.build_scene_report_lines(stats2d, "2D"),
				"icon": descriptor.get("icon"),
				"mode": _current_mode,
				"resource_path": descriptor.get("resource_path", ""),
				"scene_path": descriptor.get("scene_path", ""),
				"special_entries": stats2d.get("special_entries", []),
			}
			_special_entries = _as_special_entries(stats2d.get("special_entries", []))
		"control":
			_ui_root.add_child(preview_node)
			_center_control_content(preview_node)
			var stats_control := ToolkitPreview.inspect_scene(preview_node)
			_current_report = {
				"ok": true,
				"summary_lines": descriptor.get("summary_lines", []),
				"scene_lines": ToolkitPreview.build_scene_report_lines(stats_control, "UI Control"),
				"icon": descriptor.get("icon"),
				"mode": _current_mode,
				"resource_path": descriptor.get("resource_path", ""),
				"scene_path": descriptor.get("scene_path", ""),
				"special_entries": stats_control.get("special_entries", []),
			}
			_special_entries = _as_special_entries(stats_control.get("special_entries", []))
		_:
			_ui_root.add_child(preview_node)
			var stats_generic := ToolkitPreview.inspect_scene(preview_node)
			_current_report = {
				"ok": true,
				"summary_lines": descriptor.get("summary_lines", []),
				"scene_lines": ToolkitPreview.build_scene_report_lines(stats_generic, "Node"),
				"icon": descriptor.get("icon"),
				"mode": _current_mode,
				"resource_path": descriptor.get("resource_path", ""),
				"scene_path": descriptor.get("scene_path", ""),
				"special_entries": stats_generic.get("special_entries", []),
			}
			_special_entries = _as_special_entries(stats_generic.get("special_entries", []))

	_emit_report()
	_emit_status("Loaded %s preview." % _current_mode)
	return _current_report


func clear_preview(message: String = "No preview loaded.", descriptor: Dictionary = {}) -> Dictionary:
	_build_ui()
	_clear_preview_content()
	_current_mode = "empty"
	_current_report = {
		"ok": false,
		"summary_lines": descriptor.get("summary_lines", ["No preview loaded."]),
		"scene_lines": [message],
		"icon": descriptor.get("icon"),
		"mode": _current_mode,
		"resource_path": descriptor.get("resource_path", ""),
		"scene_path": descriptor.get("scene_path", ""),
		"error": message,
		"special_entries": [],
	}
	_special_entries.clear()
	_emit_report()
	_update_overlay_text(message)
	_emit_status(message)
	return _current_report


func frame_content() -> void:
	_build_ui()
	if _camera_3d == null:
		return
	if _current_mode != "3d" or _current_content == null:
		_camera_3d.global_position = DEFAULT_CAMERA_POSITION
		_camera_3d.look_at(DEFAULT_FOCUS_POINT, Vector3.UP)
		return

	var focus_data := _compute_3d_focus(_current_content)
	_focus_point = focus_data.get("focus", Vector3.ZERO)
	_content_radius = max(1.4, float(focus_data.get("radius", 1.8)))
	_orbit_distance = max(2.4, _content_radius * 2.2)
	_camera_3d.global_position = _focus_point + Vector3(_content_radius * 0.9, _content_radius * 0.6, _orbit_distance)
	_camera_3d.look_at(_focus_point, Vector3.UP)
	_camera_yaw = _camera_3d.rotation_degrees.y
	_camera_pitch = _camera_3d.rotation_degrees.x
	_fly_speed = max(4.0, _content_radius * 2.0)
	_emit_status("Framed preview content.")


func reset_camera() -> void:
	_build_ui()
	release_pointer_capture()
	_orbiting = false
	_panning = false
	_camera_yaw = -18.0
	_camera_pitch = -10.0
	_orbit_distance = 4.6
	_camera_3d.global_position = DEFAULT_CAMERA_POSITION
	_camera_3d.look_at(DEFAULT_FOCUS_POINT, Vector3.UP)
	if _current_mode == "3d":
		frame_content()
	else:
		_emit_status("Preview camera reset.")


func release_pointer_capture() -> void:
	_orbiting = false
	_panning = false
	if not _capturing_mouse:
		return
	_capturing_mouse = false
	_emit_status("Released preview camera.")


func get_current_report() -> Dictionary:
	return _current_report.duplicate(true)


func set_marker_visibility(enabled: bool) -> void:
	_markers_visible = enabled
	if _marker_3d_root != null:
		_marker_3d_root.visible = enabled


func set_auto_spin(enabled: bool) -> void:
	_auto_spin = enabled


func set_floor_visibility(enabled: bool) -> void:
	_floor_visible = enabled
	if _floor_mesh != null:
		_floor_mesh.visible = enabled


func set_axes_visibility(enabled: bool) -> void:
	_axes_visible = enabled
	if _axis_root != null:
		_axis_root.visible = enabled


func focus_special_path(path: String) -> bool:
	var target := path.strip_edges()
	if target == "" or _current_mode != "3d":
		return false
	for entry in _special_entries:
		if String(entry.get("path", "")) != target:
			continue
		var position = entry.get("position", Vector3.ZERO)
		if position is Vector3:
			_focus_point = position
			var forward := (_camera_3d.global_position - _focus_point).normalized()
			if forward == Vector3.ZERO:
				forward = Vector3(0.45, 0.28, 1.0).normalized()
			_orbit_distance = max(1.8, min(32.0, _orbit_distance))
			_camera_3d.global_position = _focus_point + forward * _orbit_distance
			_camera_3d.look_at(_focus_point, Vector3.UP)
			_emit_status("Focused preview target %s." % target)
			return true
	return false


func _build_ui() -> void:
	if _viewport_container != null:
		return

	_viewport_container = SubViewportContainer.new()
	_viewport_container.anchor_right = 1.0
	_viewport_container.anchor_bottom = 1.0
	_viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_viewport_container.stretch = true
	_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_viewport_container)

	_viewport = SubViewport.new()
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.transparent_bg = false
	_viewport_container.add_child(_viewport)

	_scene_root = Node.new()
	_viewport.add_child(_scene_root)

	_world_root = Node3D.new()
	_scene_root.add_child(_world_root)

	_axis_root = Node3D.new()
	_world_root.add_child(_axis_root)

	_environment = WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.075, 0.082, 0.094, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.74, 0.80, 1.0)
	environment.ambient_light_energy = 0.65
	_environment.environment = environment
	_world_root.add_child(_environment)

	_sun_light = DirectionalLight3D.new()
	_sun_light.light_energy = 1.6
	_sun_light.rotation_degrees = Vector3(-42.0, 28.0, 0.0)
	_world_root.add_child(_sun_light)

	_fill_light = OmniLight3D.new()
	_fill_light.light_energy = 0.6
	_fill_light.position = Vector3(-2.0, 1.4, 2.0)
	_world_root.add_child(_fill_light)

	_content_3d_root = Node3D.new()
	_content_3d_root.name = "Preview3D"
	_world_root.add_child(_content_3d_root)

	_marker_3d_root = Node3D.new()
	_marker_3d_root.name = "Markers"
	_world_root.add_child(_marker_3d_root)

	_camera_3d = Camera3D.new()
	_camera_3d.current = true
	_camera_3d.fov = 58.0
	_camera_3d.near = 0.02
	_camera_3d.far = 300.0
	_camera_3d.global_position = DEFAULT_CAMERA_POSITION
	_world_root.add_child(_camera_3d)
	_camera_3d.look_at(DEFAULT_FOCUS_POINT, Vector3.UP)

	_add_reference_geometry()

	_content_2d_root = Node2D.new()
	_scene_root.add_child(_content_2d_root)

	_camera_2d = Camera2D.new()
	_camera_2d.enabled = false
	_content_2d_root.add_child(_camera_2d)

	_ui_root = Control.new()
	_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scene_root.add_child(_ui_root)

	_texture_rect = TextureRect.new()
	_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.visible = false
	_ui_root.add_child(_texture_rect)

	_overlay_panel = PanelContainer.new()
	_overlay_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_panel.anchor_left = 0.0
	_overlay_panel.anchor_right = 0.0
	_overlay_panel.anchor_top = 1.0
	_overlay_panel.anchor_bottom = 1.0
	_overlay_panel.offset_left = 10.0
	_overlay_panel.offset_right = 350.0
	_overlay_panel.offset_top = -68.0
	_overlay_panel.offset_bottom = -10.0
	_overlay_panel.theme = ToolkitTheme.load_game_theme()
	_overlay_panel.add_theme_stylebox_override("panel", ToolkitTheme.make_hint_style())
	add_child(_overlay_panel)

	var overlay_margin := MarginContainer.new()
	overlay_margin.add_theme_constant_override("margin_left", 12)
	overlay_margin.add_theme_constant_override("margin_top", 8)
	overlay_margin.add_theme_constant_override("margin_right", 12)
	overlay_margin.add_theme_constant_override("margin_bottom", 8)
	_overlay_panel.add_child(overlay_margin)

	_overlay_label = Label.new()
	_overlay_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overlay_label.modulate = Color(1.0, 1.0, 1.0, 0.82)
	overlay_margin.add_child(_overlay_label)


func _sync_viewport_size() -> void:
	if _viewport == null:
		return
	var target_size := Vector2i(max(64, int(size.x)), max(64, int(size.y)))
	_viewport.size = target_size


func _clear_preview_content() -> void:
	release_pointer_capture()
	if _camera_2d != null:
		_camera_2d.enabled = false
	_texture_rect.texture = null
	_texture_rect.visible = false
	_current_content = null
	_current_report = {}
	_current_mode = "empty"
	_special_entries.clear()

	for label in _marker_labels:
		if label != null and is_instance_valid(label):
			label.queue_free()
	_marker_labels.clear()
	_free_children(_marker_3d_root)
	_free_children(_content_3d_root)
	_free_children(_content_2d_root, [_camera_2d])
	_free_children(_ui_root, [_texture_rect])


func _free_children(parent: Node, keep: Array = []) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		if keep.has(child):
			continue
		parent.remove_child(child)
		child.queue_free()


func _apply_markers(marker_specs) -> void:
	_free_children(_marker_3d_root)
	_marker_labels.clear()
	if not (marker_specs is Array):
		return

	for entry in marker_specs:
		if not (entry is Dictionary):
			continue
		var marker := Label3D.new()
		marker.text = String(entry.get("label", "MARK"))
		var marker_color = entry.get("color", Color(1.0, 1.0, 1.0, 1.0))
		if marker_color is Color:
			marker.modulate = marker_color
		var marker_position = entry.get("position", Vector3.ZERO)
		if marker_position is Vector3:
			marker.position = marker_position + Vector3(0.0, 0.18, 0.0)
		else:
			marker.position = Vector3(0.0, 0.18, 0.0)
		marker.pixel_size = 0.0024
		_marker_3d_root.add_child(marker)
		_marker_labels.append(marker)


func _add_reference_geometry() -> void:
	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(12.0, 0.02, 12.0)
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -0.02, 0.0)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.16, 0.18, 0.20, 0.92)
	floor_material.roughness = 0.92
	floor.set_surface_override_material(0, floor_material)
	_world_root.add_child(floor)
	_floor_mesh = floor
	_floor_mesh.visible = _floor_visible

	_add_axis_bar(Vector3(1.1, 0.02, 0.02), Vector3(0.55, 0.0, 0.0), Color(0.92, 0.36, 0.36, 1.0))
	_add_axis_bar(Vector3(0.02, 1.1, 0.02), Vector3(0.0, 0.55, 0.0), Color(0.42, 0.92, 0.52, 1.0))
	_add_axis_bar(Vector3(0.02, 0.02, 1.1), Vector3(0.0, 0.0, 0.55), Color(0.36, 0.66, 0.96, 1.0))


func _add_axis_bar(size_3d: Vector3, position_3d: Vector3, color: Color) -> void:
	var bar := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_3d
	bar.mesh = mesh
	bar.position = position_3d
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.4
	bar.set_surface_override_material(0, material)
	_axis_root.add_child(bar)
	_axis_root.visible = _axes_visible


func _frame_2d_content(node: Node) -> void:
	if _camera_2d == null:
		return
	_camera_2d.enabled = true
	_camera_2d.zoom = Vector2.ONE
	var rect := _compute_2d_rect(node)
	var center := rect.get_center()
	_camera_2d.position = center
	var extent := max(rect.size.x, rect.size.y)
	if extent > 0.0:
		var base := max(1.0, extent / max(220.0, min(size.x, size.y)))
		_camera_2d.zoom = Vector2(base, base)


func _center_control_content(node: Node) -> void:
	if not (node is Control):
		return
	var control := node as Control
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	if control.size == Vector2.ZERO and control.get_combined_minimum_size() != Vector2.ZERO:
		control.size = control.get_combined_minimum_size()
	var target_size := control.size
	if target_size == Vector2.ZERO:
		target_size = control.get_combined_minimum_size()
	control.position = (size - target_size) * 0.5


func _compute_2d_rect(node: Node) -> Rect2:
	var points: Array[Vector2] = []
	_collect_2d_points(node, points)
	if points.is_empty():
		return Rect2(Vector2.ZERO, Vector2(256.0, 256.0))
	var min_point := points[0]
	var max_point := points[0]
	for point in points:
		min_point = Vector2(min(min_point.x, point.x), min(min_point.y, point.y))
		max_point = Vector2(max(max_point.x, point.x), max(max_point.y, point.y))
	var size_2d := max_point - min_point
	if size_2d == Vector2.ZERO:
		size_2d = Vector2(128.0, 128.0)
	return Rect2(min_point, size_2d)


func _collect_2d_points(node: Node, points: Array[Vector2]) -> void:
	if node is Node2D:
		var node2d := node as Node2D
		points.append(node2d.global_position)
		if node2d is Sprite2D and (node2d as Sprite2D).texture != null:
			var half := (node2d as Sprite2D).texture.get_size() * 0.5
			points.append(node2d.global_position - half)
			points.append(node2d.global_position + half)
	if node is Control:
		var control := node as Control
		points.append(control.position)
		points.append(control.position + control.size)
	for child in node.get_children():
		if child is Node:
			_collect_2d_points(child, points)


func _compute_3d_focus(node: Node) -> Dictionary:
	var points: Array[Vector3] = []
	_collect_3d_points(node, points)
	if points.is_empty():
		return {"focus": Vector3.ZERO, "radius": 1.8}

	var min_point := points[0]
	var max_point := points[0]
	for point in points:
		min_point = Vector3(min(min_point.x, point.x), min(min_point.y, point.y), min(min_point.z, point.z))
		max_point = Vector3(max(max_point.x, point.x), max(max_point.y, point.y), max(max_point.z, point.z))
	var focus := (min_point + max_point) * 0.5
	var radius := max(1.4, (max_point - min_point).length() * 0.5)
	return {"focus": focus, "radius": radius}


func _collect_3d_points(node: Node, points: Array[Vector3]) -> void:
	if node is Node3D:
		var node3d := node as Node3D
		points.append(node3d.global_position)
		if node3d.has_method("get_aabb"):
			var aabb = node3d.call("get_aabb")
			if aabb is AABB:
				for corner_index in range(8):
					points.append(node3d.global_transform * (aabb as AABB).get_endpoint(corner_index))
	for child in node.get_children():
		if child is Node:
			_collect_3d_points(child, points)


func _apply_mouse_look(relative: Vector2) -> void:
	_camera_yaw -= relative.x * 0.16
	_camera_pitch = clamp(_camera_pitch - relative.y * 0.16, -85.0, 85.0)
	_camera_3d.rotation_degrees = Vector3(_camera_pitch, _camera_yaw, 0.0)


func _orbit_camera(delta: Vector2) -> void:
	_camera_yaw -= delta.x * 0.18
	_camera_pitch = clamp(_camera_pitch - delta.y * 0.18, -85.0, 85.0)
	var yaw := deg_to_rad(_camera_yaw)
	var pitch := deg_to_rad(_camera_pitch)
	var direction := Vector3(
		cos(pitch) * sin(yaw),
		sin(pitch),
		cos(pitch) * cos(yaw)
	).normalized()
	_camera_3d.global_position = _focus_point + direction * _orbit_distance
	_camera_3d.look_at(_focus_point, Vector3.UP)


func _pan_camera(delta: Vector2) -> void:
	var basis := _camera_3d.global_transform.basis
	var scale := max(0.003, _orbit_distance * 0.0018)
	var pan: Vector3 = (-basis.x * delta.x + basis.y * delta.y) * scale
	_focus_point += pan
	_camera_3d.global_position += pan
	_camera_3d.look_at(_focus_point, Vector3.UP)


func _zoom_camera(step: float) -> void:
	if _current_mode != "3d":
		return
	_orbit_distance = clamp(_orbit_distance + step, 0.45, 180.0)
	var direction := (_camera_3d.global_position - _focus_point).normalized()
	if direction == Vector3.ZERO:
		direction = Vector3(0.45, 0.28, 1.0).normalized()
	_camera_3d.global_position = _focus_point + direction * _orbit_distance
	_camera_3d.look_at(_focus_point, Vector3.UP)


func _should_process_keyboard_navigation() -> bool:
	return _capturing_mouse or has_focus() or _hovered


func _emit_report() -> void:
	report_changed.emit(_current_report.duplicate(true))


func _as_special_entries(value) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if value is Array:
		for entry in value:
			if entry is Dictionary:
				out.append(entry.duplicate(true))
	return out


func _update_overlay_text(force_text: String = "") -> void:
	if _overlay_label == null:
		return
	if force_text != "":
		_overlay_label.text = force_text
		return

	match _current_mode:
		"3d":
			_overlay_label.text = "Preview 3D  |  LMB orbit  |  MMB or Shift+LMB pan  |  RMB freelook + WASD/QE  |  Wheel zoom  |  F frame  |  speed %.1f" % _fly_speed
		"2d":
			_overlay_label.text = "Preview 2D  |  Wheel zoom  |  F frame"
		"control":
			_overlay_label.text = "Preview UI  |  Control scene centered in viewport"
		"texture":
			_overlay_label.text = "Preview Texture  |  Icon / image shown at aspect-correct scale"
		_:
			_overlay_label.text = "Load a node, property, scene, or item resource to preview it here."


func _emit_status(text: String) -> void:
	status_changed.emit(text)
	_update_overlay_text()


func _gui_input(event: InputEvent) -> void:
	grab_focus()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		frame_content()
		accept_event()
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if _current_mode == "3d":
				if mouse_event.pressed and Input.is_key_pressed(KEY_SHIFT):
					_panning = true
				else:
					_orbiting = mouse_event.pressed
				if not mouse_event.pressed:
					_orbiting = false
					_panning = false if not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) else _panning
				accept_event()
				return
		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			if _current_mode == "3d":
				_panning = mouse_event.pressed
				if not mouse_event.pressed:
					_panning = false
				accept_event()
				return
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if _current_mode == "3d":
				_capturing_mouse = mouse_event.pressed
				if mouse_event.pressed:
					_emit_status("Preview freelook active.")
				else:
					release_pointer_capture()
				accept_event()
				return
			else:
				release_pointer_capture()
			accept_event()
			return

		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if _current_mode == "3d":
				if _capturing_mouse and Input.is_key_pressed(KEY_SHIFT):
					_fly_speed = min(320.0, _fly_speed * 1.15)
				else:
					_zoom_camera(-max(0.35, _content_radius * 0.12))
			elif _current_mode == "2d":
				_camera_2d.zoom *= 0.9
			accept_event()
			return

		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _current_mode == "3d":
				if _capturing_mouse and Input.is_key_pressed(KEY_SHIFT):
					_fly_speed = max(0.8, _fly_speed / 1.15)
				else:
					_zoom_camera(max(0.35, _content_radius * 0.12))
			elif _current_mode == "2d":
				_camera_2d.zoom *= 1.1
			accept_event()
			return

	if event is InputEventMouseMotion and _current_mode == "3d":
		var motion := event as InputEventMouseMotion
		if _capturing_mouse:
			_apply_mouse_look(motion.relative)
			accept_event()
			return
		if _orbiting:
			_orbit_camera(motion.relative)
			accept_event()
			return
		if _panning:
			_pan_camera(motion.relative)
			accept_event()
			return


func _on_mouse_entered_preview() -> void:
	_hovered = true


func _on_mouse_exited_preview() -> void:
	_hovered = false
	if not _capturing_mouse:
		_orbiting = false
		_panning = false
