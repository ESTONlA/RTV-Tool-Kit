extends Control

signal status_changed(text: String)
signal transform_committed(node: Node3D, old_state: Dictionary, new_state: Dictionary)

const HANDLE_RADIUS := 12.0
const MIN_WORLD_LENGTH := 0.75
const MAX_WORLD_LENGTH := 2.8
const MOVE_SENSITIVITY := 1.0
const ROTATE_SENSITIVITY := 0.45
const SCALE_SENSITIVITY := 1.0

const AXIS_COLORS := {
	"x": Color(0.95, 0.32, 0.32, 0.95),
	"y": Color(0.35, 0.92, 0.40, 0.95),
	"z": Color(0.40, 0.68, 1.0, 0.95),
}

var _target: Node3D
var _mode := "move"
var _local_space := true
var _hover_axis := ""
var _active_axis := ""
var _drag_start_mouse := Vector2.ZERO
var _drag_start_state := {}
var _handle_cache := {}


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_process(true)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func set_active(enabled: bool) -> void:
	visible = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if not enabled:
		_hover_axis = ""
		_active_axis = ""
		_drag_start_state = {}
	queue_redraw()


func set_target(node: Node) -> void:
	_target = node as Node3D
	if _target == null:
		_hover_axis = ""
		_active_axis = ""
	queue_redraw()


func set_mode(mode: String) -> void:
	_mode = mode
	queue_redraw()


func set_local_space(enabled: bool) -> void:
	_local_space = enabled
	queue_redraw()


func release_drag() -> void:
	if _active_axis == "":
		return
	_active_axis = ""
	_drag_start_state = {}
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not visible or _target == null:
		return

	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _active_axis != "":
			_apply_drag(motion.position)
			get_viewport().set_input_as_handled()
			return
		_hover_axis = _hit_test_axis(motion.position)
		queue_redraw()
		return

	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			var axis := _hit_test_axis(mouse.position)
			if axis != "":
				_active_axis = axis
				_hover_axis = axis
				_drag_start_mouse = mouse.position
				_drag_start_state = _capture_target_state()
				emit_signal("status_changed", "Gizmo %s %s drag started." % [_mode, axis.to_upper()])
				get_viewport().set_input_as_handled()
				queue_redraw()
		elif mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
			if _active_axis != "":
				var old_state: Dictionary = _drag_start_state.duplicate(true)
				var new_state := _capture_target_state()
				var axis_name := _active_axis
				_active_axis = ""
				_drag_start_state = {}
				if old_state != new_state:
					emit_signal("transform_committed", _target, old_state, new_state)
					emit_signal("status_changed", "Gizmo %s %s committed." % [_mode, axis_name.to_upper()])
				else:
					emit_signal("status_changed", "Gizmo drag cancelled.")
				get_viewport().set_input_as_handled()
				queue_redraw()
		elif mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
			if _active_axis != "" and not _drag_start_state.is_empty():
				_apply_target_state(_drag_start_state)
				_active_axis = ""
				_drag_start_state = {}
				emit_signal("status_changed", "Gizmo drag reverted.")
				get_viewport().set_input_as_handled()
				queue_redraw()


func _draw() -> void:
	if not visible or _target == null:
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	_handle_cache = _build_handle_cache(camera)
	if _handle_cache.is_empty():
		return

	var origin_screen: Vector2 = _handle_cache.get("origin_screen", Vector2.ZERO)
	draw_circle(origin_screen, 6.0, Color(1.0, 1.0, 1.0, 0.9))

	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	for axis_name in ["x", "y", "z"]:
		var handle: Dictionary = _handle_cache.get(axis_name, {})
		if handle.is_empty():
			continue
		var color: Color = AXIS_COLORS.get(axis_name, Color.WHITE)
		if axis_name == _hover_axis or axis_name == _active_axis:
			color = color.lerp(Color.WHITE, 0.35)
		draw_line(origin_screen, handle.get("screen_point", origin_screen), color, 3.0, true)
		draw_circle(handle.get("screen_point", origin_screen), HANDLE_RADIUS, Color(color.r, color.g, color.b, 0.20))
		draw_arc(handle.get("screen_point", origin_screen), HANDLE_RADIUS, 0.0, TAU, 18, color, 2.0, true)
		draw_string(font, handle.get("screen_point", origin_screen) + Vector2(14.0, -8.0), "%s %s" % [axis_name.to_upper(), _mode.left(1).to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

	var overlay_text := "Gizmo  |  %s  |  %s space  |  drag axis handle  |  RMB revert drag  |  Esc close" % [
		_mode.capitalize(),
		"Local" if _local_space else "World",
	]
	draw_string(font, Vector2(24.0, 32.0), overlay_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1.0, 1.0, 1.0, 0.86))


func _build_handle_cache(camera: Camera3D) -> Dictionary:
	var cache := {}
	if _target == null:
		return cache

	var origin_world := _target.global_position
	if camera.is_position_behind(origin_world):
		return cache

	var origin_screen := camera.unproject_position(origin_world)
	cache["origin_world"] = origin_world
	cache["origin_screen"] = origin_screen

	var distance := camera.global_position.distance_to(origin_world)
	var world_length := clamp(distance * 0.08, MIN_WORLD_LENGTH, MAX_WORLD_LENGTH)
	cache["world_length"] = world_length

	var basis := _target.global_transform.basis.orthonormalized()
	var axis_vectors := {
		"x": basis.x if _local_space else Vector3.RIGHT,
		"y": basis.y if _local_space else Vector3.UP,
		"z": basis.z if _local_space else Vector3.FORWARD,
	}

	for axis_name in axis_vectors.keys():
		var world_axis: Vector3 = (axis_vectors[axis_name] as Vector3).normalized()
		var world_point := origin_world + (world_axis * world_length)
		if camera.is_position_behind(world_point):
			continue
		var screen_point := camera.unproject_position(world_point)
		cache[axis_name] = {
			"axis": axis_name,
			"world_axis": world_axis,
			"world_length": world_length,
			"screen_point": screen_point,
			"screen_vector": screen_point - origin_screen,
		}

	return cache


func _hit_test_axis(position: Vector2) -> String:
	for axis_name in ["x", "y", "z"]:
		var handle: Dictionary = _handle_cache.get(axis_name, {})
		if handle.is_empty():
			continue
		if position.distance_to(handle.get("screen_point", position)) <= HANDLE_RADIUS + 6.0:
			return axis_name
	return ""


func _apply_drag(mouse_position: Vector2) -> void:
	if _target == null or _active_axis == "":
		return

	var handle: Dictionary = _handle_cache.get(_active_axis, {})
	if handle.is_empty():
		return

	var screen_vector: Vector2 = handle.get("screen_vector", Vector2.RIGHT)
	var screen_length := max(screen_vector.length(), 1.0)
	var axis_dir := screen_vector.normalized()
	var mouse_delta := mouse_position - _drag_start_mouse
	var projected := mouse_delta.dot(axis_dir)
	var amount := (projected / screen_length) * float(handle.get("world_length", 1.0))
	var start_state: Dictionary = _drag_start_state

	match _mode:
		"move":
			_target.global_position = start_state.get("position", _target.global_position) + (handle.get("world_axis", Vector3.ZERO) * amount * MOVE_SENSITIVITY)
		"scale":
			var scale: Vector3 = start_state.get("scale", _target.scale)
			var axis_name := _active_axis
			match axis_name:
				"x":
					scale.x = max(0.01, scale.x + (amount * SCALE_SENSITIVITY))
				"y":
					scale.y = max(0.01, scale.y + (amount * SCALE_SENSITIVITY))
				"z":
					scale.z = max(0.01, scale.z + (amount * SCALE_SENSITIVITY))
			_target.scale = scale
		"rotate":
			var rotation: Vector3 = start_state.get("rotation", _target.rotation_degrees)
			var degrees_delta := projected * ROTATE_SENSITIVITY
			match _active_axis:
				"x":
					rotation.x += degrees_delta
				"y":
					rotation.y += degrees_delta
				"z":
					rotation.z += degrees_delta
			_target.rotation_degrees = rotation


func _capture_target_state() -> Dictionary:
	if _target == null:
		return {}
	return {
		"mode": "Node3D",
		"position": _target.global_position,
		"rotation": _target.rotation_degrees,
		"scale": _target.scale,
	}


func _apply_target_state(state: Dictionary) -> void:
	if _target == null or state.is_empty():
		return
	_target.global_position = state.get("position", _target.global_position)
	_target.rotation_degrees = state.get("rotation", _target.rotation_degrees)
	_target.scale = state.get("scale", _target.scale)
