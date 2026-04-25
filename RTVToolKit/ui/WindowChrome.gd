extends PanelContainer

signal close_requested
signal geometry_changed(window_position: Vector2, window_size: Vector2)

const ToolkitConfig = preload("res://RTVToolKit/core/ToolkitConfig.gd")
const ToolkitTheme = preload("res://RTVToolKit/ui/ToolkitTheme.gd")

var _title_label: Label
var _subtitle_label: Label
var _content_root: VBoxContainer
var _resize_handle: Control
var _dragging := false
var _resizing := false
var _drag_offset := Vector2.ZERO
var _resize_origin_mouse := Vector2.ZERO
var _resize_origin_size := Vector2.ZERO
var _min_window_size := ToolkitConfig.MIN_WINDOW_SIZE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	custom_minimum_size = _min_window_size
	set_process_input(true)
	theme = ToolkitTheme.load_game_theme()
	add_theme_stylebox_override("panel", ToolkitTheme.make_window_style())
	_build_shell()
	_layout_resize_handle()


func set_window_text(title: String, subtitle: String) -> void:
	if _title_label != null:
		_title_label.text = title
	if _subtitle_label != null:
		_subtitle_label.text = subtitle


func get_content_root() -> VBoxContainer:
	return _content_root


func set_minimum_window_size(value: Vector2) -> void:
	_min_window_size = value
	custom_minimum_size = value


func restore_geometry(window_position: Vector2, window_size: Vector2) -> void:
	position = window_position
	size = Vector2(
		max(window_size.x, _min_window_size.x),
		max(window_size.y, _min_window_size.y)
	)
	_clamp_to_viewport()
	_layout_resize_handle()


func reset_geometry() -> void:
	restore_geometry(ToolkitConfig.DEFAULT_WINDOW_POSITION, ToolkitConfig.DEFAULT_WINDOW_SIZE)
	_emit_geometry_changed()


func center_in_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	position = (viewport_size - size) * 0.5
	_clamp_to_viewport()
	_emit_geometry_changed()


func clamp_to_viewport() -> void:
	_clamp_to_viewport()
	_layout_resize_handle()
	_emit_geometry_changed()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_pointer_interaction()


func _build_shell() -> void:
	if get_child_count() > 0:
		return

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root)

	var header := PanelContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.add_theme_stylebox_override("panel", ToolkitTheme.make_header_style())
	header.gui_input.connect(_on_header_gui_input)
	root.add_child(header)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 14)
	header_margin.add_theme_constant_override("margin_top", 12)
	header_margin.add_theme_constant_override("margin_right", 12)
	header_margin.add_theme_constant_override("margin_bottom", 12)
	header.add_child(header_margin)

	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 10)
	header_margin.add_child(header_row)

	var icon_texture := ToolkitTheme.load_header_icon()
	if icon_texture != null:
		var icon := TextureRect.new()
		icon.texture = icon_texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(18.0, 18.0)
		icon.modulate = Color(1.0, 1.0, 1.0, 0.90)
		header_row.add_child(icon)

	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_column.add_theme_constant_override("separation", 2)
	header_row.add_child(title_column)

	_title_label = Label.new()
	_title_label.text = "RTV Tool Kit"
	var title_font := ToolkitTheme.load_title_font()
	if title_font != null:
		_title_label.add_theme_font_override("font", title_font)
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.modulate = Color(1.0, 1.0, 1.0, 0.96)
	title_column.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.text = ""
	var body_font := ToolkitTheme.load_body_font()
	if body_font != null:
		_subtitle_label.add_theme_font_override("font", body_font)
	_subtitle_label.modulate = Color(1.0, 1.0, 1.0, 0.56)
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_column.add_child(_subtitle_label)

	var center_button := Button.new()
	center_button.text = "Center"
	center_button.pressed.connect(center_in_viewport)
	header_row.add_child(center_button)

	var reset_button := Button.new()
	reset_button.text = "Reset"
	reset_button.pressed.connect(reset_geometry)
	header_row.add_child(reset_button)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(func() -> void: close_requested.emit())
	header_row.add_child(close_button)

	var body := PanelContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_stylebox_override("panel", ToolkitTheme.make_body_style())
	root.add_child(body)

	var body_margin := MarginContainer.new()
	body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 12)
	body_margin.add_theme_constant_override("margin_top", 12)
	body_margin.add_theme_constant_override("margin_right", 12)
	body_margin.add_theme_constant_override("margin_bottom", 12)
	body.add_child(body_margin)

	_content_root = VBoxContainer.new()
	_content_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_root.add_theme_constant_override("separation", 10)
	body_margin.add_child(_content_root)

	_resize_handle = _create_resize_handle()
	add_child(_resize_handle)
	_layout_resize_handle()


func _create_resize_handle() -> Control:
	var grip_texture := ToolkitTheme.load_resize_grip()
	if grip_texture != null:
		var grip := TextureRect.new()
		grip.top_level = true
		grip.texture = grip_texture
		grip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		grip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		grip.size = Vector2(18.0, 18.0)
		grip.mouse_filter = Control.MOUSE_FILTER_STOP
		grip.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		grip.modulate = Color(1.0, 1.0, 1.0, 0.72)
		grip.gui_input.connect(_on_resize_handle_gui_input)
		return grip

	var fallback := ColorRect.new()
	fallback.top_level = true
	fallback.size = Vector2(12.0, 12.0)
	fallback.color = Color(1.0, 1.0, 1.0, 0.40)
	fallback.mouse_filter = Control.MOUSE_FILTER_STOP
	fallback.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	fallback.gui_input.connect(_on_resize_handle_gui_input)
	return fallback


func _on_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_resizing = false
			_dragging = true
			_drag_offset = get_global_mouse_position() - global_position
			accept_event()
		else:
			if _dragging:
				_finish_pointer_interaction()
				accept_event()
	elif event is InputEventMouseMotion and _dragging:
		position = get_global_mouse_position() - _drag_offset
		_clamp_to_viewport()
		_emit_geometry_changed()
		accept_event()


func _on_resize_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = false
			_resizing = true
			_resize_origin_mouse = get_global_mouse_position()
			_resize_origin_size = size
			accept_event()
		else:
			if _resizing:
				_finish_pointer_interaction()
				accept_event()
	elif event is InputEventMouseMotion and _resizing:
		var delta := get_global_mouse_position() - _resize_origin_mouse
		size = Vector2(
			max(_resize_origin_size.x + delta.x, _min_window_size.x),
			max(_resize_origin_size.y + delta.y, _min_window_size.y)
		)
		_clamp_to_viewport()
		_emit_geometry_changed()
		accept_event()


func _finish_pointer_interaction() -> void:
	if not _dragging and not _resizing:
		return
	_dragging = false
	_resizing = false
	_clamp_to_viewport()
	_layout_resize_handle()
	_emit_geometry_changed()


func _clamp_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	size = Vector2(
		clamp(size.x, _min_window_size.x, max(_min_window_size.x, viewport_size.x - 12.0)),
		clamp(size.y, _min_window_size.y, max(_min_window_size.y, viewport_size.y - 12.0))
	)
	position.x = clamp(position.x, 6.0, max(6.0, viewport_size.x - size.x - 6.0))
	position.y = clamp(position.y, 6.0, max(6.0, viewport_size.y - size.y - 6.0))


func _layout_resize_handle() -> void:
	if _resize_handle == null:
		return
	_resize_handle.position = global_position + size - _resize_handle.size - Vector2(8.0, 8.0)


func _emit_geometry_changed() -> void:
	_layout_resize_handle()
	geometry_changed.emit(position, size)
