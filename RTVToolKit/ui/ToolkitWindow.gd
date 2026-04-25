extends Control

const MOD_PREFIX := "[RTVToolKit]"
const VERSION := "1.0.0"
const MENU_SCENE_PATH := "res://Scenes/Menu.tscn"
const MENU_BUTTON_NAME := "RTVToolKitButton"
const REPORT_PATH := "user://rtv_tool_kit_report.txt"
const DIAGNOSTICS_REPORT_PATH := "user://rtv_tool_kit_diagnostics.txt"
const SNAPSHOT_ROOT := "user://rtv_tool_kit_snapshots"
const TOGGLE_KEY := KEY_F8
const REFRESH_KEY := KEY_F9
const TAB_OVERVIEW := 0
const TAB_HIERARCHY := 1
const TAB_SEARCH := 2
const TAB_INSPECTOR := 3
const TAB_PREVIEW := 4
const TAB_WORLD := 5
const TAB_FILES := 6
const TAB_RUNTIME := 7
const TAB_DIAGNOSTICS := 8
const TAB_GROUPS := 9
const TAB_WATCH := 10
const TAB_LOG := 11
const MAX_LOG_LINES := 240
const MAX_TRANSACTIONS := 160
const MAX_INSPECTOR_PROPERTIES := 260
const MAX_HISTORY_ITEMS := 60
const DANGER_CONFIRM_WINDOW_MS := 4000
const QUICK_GROUPS := ["Furniture", "Item", "Switch"]
const ToolkitConfig = preload("res://RTVToolKit/core/ToolkitConfig.gd")
const ToolkitDiagnostics = preload("res://RTVToolKit/core/ToolkitDiagnostics.gd")
const ToolkitPicker = preload("res://RTVToolKit/core/ToolkitPicker.gd")
const WindowChrome = preload("res://RTVToolKit/ui/WindowChrome.gd")
const ToolkitTabBuilder = preload("res://RTVToolKit/ui/ToolkitTabBuilder.gd")
const ToolkitTheme = preload("res://RTVToolKit/ui/ToolkitTheme.gd")

var game_data = preload("res://Resources/GameData.tres")

var _pick_capture_layer: ColorRect
var _pick_hint_panel: PanelContainer
var _pick_hint_label: Label
var _pick_ui_highlight: PanelContainer
var _pick_world_marker: PanelContainer
var _backdrop: ColorRect
var _panel: WindowChrome
var _tabs: TabContainer
var _status_label: Label

var _overview_label: RichTextLabel

var _hierarchy_tree: Tree
var _hierarchy_path_label: Label
var _hierarchy_filter_edit: LineEdit
var _pick_toggle_button: Button
var _pick_script_owner_button: Button
var _pick_freeze_check: CheckBox
var _pick_controls_check: CheckBox
var _pick_world_check: CheckBox
var _pick_target_label: Label

var _search_query_edit: LineEdit
var _search_mode: OptionButton
var _search_selected_scope_check: CheckBox
var _search_results: ItemList

var _inspector_path_edit: LineEdit
var _inspector_meta: RichTextLabel
var _inspector_watch_view: RichTextLabel
var _resource_meta: RichTextLabel
var _property_filter_edit: LineEdit
var _property_changed_only_check: CheckBox
var _property_tree: Tree
var _property_name_edit: LineEdit
var _property_type_option: OptionButton
var _property_value_edit: TextEdit
var _property_pin_button: Button
var _property_watch_button: Button
var _property_revert_button: Button
var _method_name_edit: LineEdit
var _method_use_arg_check: CheckBox
var _method_arg_type_option: OptionButton
var _method_arg_edit: LineEdit
var _preview_source_path_edit: LineEdit
var _preview_summary: RichTextLabel
var _preview_scene_report: RichTextLabel
var _preview_icon_rect: TextureRect
var _preview_special_list: ItemList
var _preview_markers_check: CheckBox
var _preview_floor_check: CheckBox
var _preview_axes_check: CheckBox
var _preview_spin_check: CheckBox
var _preview_viewport: Control
var _undo_button: Button
var _redo_button: Button
var _auto_snapshot_danger_check: CheckBox
var _lock_important_check: CheckBox

var _world_selected_path_edit: LineEdit
var _world_jump_path_edit: LineEdit
var _world_reparent_path_edit: LineEdit
var _world_mode_label: Label
var _world_name_edit: LineEdit
var _world_visible_check: CheckBox
var _world_step_spin: SpinBox
var _world_pos_x: SpinBox
var _world_pos_y: SpinBox
var _world_pos_z: SpinBox
var _world_rot_x: SpinBox
var _world_rot_y: SpinBox
var _world_rot_z: SpinBox
var _world_scale_x: SpinBox
var _world_scale_y: SpinBox
var _world_scale_z: SpinBox
var _spawn_path_edit: LineEdit

var _file_list: ItemList
var _file_meta_label: Label
var _file_preview: TextEdit
var _file_filter_edit: LineEdit

var _time_scale_spin: SpinBox
var _tree_paused_check: CheckBox
var _simulation_simulate_check: CheckBox
var _simulation_day_spin: SpinBox
var _simulation_time_spin: SpinBox
var _simulation_season_spin: SpinBox
var _simulation_weather_spin: SpinBox
var _simulation_weather_time_spin: SpinBox
var _game_menu_check: CheckBox
var _game_shelter_check: CheckBox
var _game_permadeath_check: CheckBox
var _game_tutorial_check: CheckBox
var _game_freeze_check: CheckBox
var _game_compatibility_check: CheckBox
var _runtime_message_edit: LineEdit

var _diagnostics_mod_list: ItemList
var _diagnostics_issue_list: ItemList
var _diagnostics_report: RichTextLabel
var _diagnostics_detail: RichTextLabel

var _group_filter_edit: LineEdit
var _group_list: ItemList
var _group_members: ItemList
var _group_name_edit: LineEdit
var _group_status_label: Label

var _bookmark_list: ItemList
var _watch_list: ItemList
var _history_list: ItemList

var _log_view: TextEdit
var _transaction_list: ItemList
var _transaction_detail: RichTextLabel

var _selected_node_path := ""
var _selected_user_file := ""
var _selected_group_name := ""
var _search_match_paths: Array[String] = []
var _file_entries: Array[Dictionary] = []
var _event_log: Array[String] = []
var _bookmarked_paths: Array[String] = []
var _watch_paths: Array[String] = []
var _selection_history: Array[String] = []
var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
var _transaction_history: Array[Dictionary] = []
var _pinned_properties: Array[String] = []
var _watched_properties: Array[String] = []
var _inspector_selected_property := ""
var _inspector_selected_property_type := TYPE_NIL
var _inspector_baseline_values := {}
var _inspector_baseline_signatures := {}
var _diagnostics_data := {}
var _diagnostics_focus_kind := ""
var _diagnostics_focus_key := ""
var _transaction_serial := 1
var _pending_confirmation := {}

var _refresh_accumulator := 0.0
var _last_scene_signature := ""
var _last_report_text := ""
var _last_diagnostics_report_text := ""
var _window_position := ToolkitConfig.DEFAULT_WINDOW_POSITION
var _window_size := ToolkitConfig.DEFAULT_WINDOW_SIZE
var _pick_enabled := false
var _pick_hover_path := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	set_process_input(true)
	resized.connect(_on_root_resized)
	_load_state()
	_build_ui()
	_apply_saved_window_geometry()
	_ensure_menu_button()
	_last_scene_signature = _current_scene_signature()
	_rebuild_hierarchy_tree()
	_refresh_file_list()
	_refresh_all_views(false)
	_refresh_transaction_views()
	_log_event("Tool Kit ready.")
	_set_status("Ready. F8 toggles the overlay. F9 refreshes.")


func _process(delta: float) -> void:
	var scene_signature := _current_scene_signature()
	if scene_signature != _last_scene_signature:
		_last_scene_signature = scene_signature
		_pending_confirmation.clear()
		_log_event("Scene changed: %s" % _value_or_placeholder(scene_signature))
		_ensure_menu_button()
		_validate_selection()
		_rebuild_hierarchy_tree()
		_refresh_all_views(false)

	if _pick_enabled:
		_process_pick_mode()

	if not _panel.visible:
		return

	_refresh_accumulator += delta
	if _refresh_accumulator >= 1.0:
		_refresh_accumulator = 0.0
		_validate_selection()
		_refresh_dynamic_views()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		if _pick_enabled:
			return
		return
	if not event.pressed or event.echo:
		return

	if _pick_enabled:
		if event.keycode == KEY_ESCAPE:
			_set_pick_mode(false, true)
			_set_status("Pick mode cancelled.")
			return
		if event.keycode == KEY_SPACE and _pick_freeze_check != null:
			_pick_freeze_check.button_pressed = not _pick_freeze_check.button_pressed
			_refresh_pick_controls()
			_set_status("Pick freeze = %s." % _bool_string(_pick_freeze_check.button_pressed))
			return
		if event.keycode == TOGGLE_KEY:
			_set_pick_mode(false, true)
			return

	if event.keycode == TOGGLE_KEY:
		_toggle_overlay()
	elif event.keycode == REFRESH_KEY:
		_refresh_all_views(true)
		_set_status("Refreshed all toolkit views.")


func _build_ui() -> void:
	_pick_capture_layer = ColorRect.new()
	_pick_capture_layer.anchor_right = 1.0
	_pick_capture_layer.anchor_bottom = 1.0
	_pick_capture_layer.color = Color(0.0, 0.0, 0.0, 0.001)
	_pick_capture_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_pick_capture_layer.visible = false
	_pick_capture_layer.gui_input.connect(_on_pick_capture_gui_input)
	add_child(_pick_capture_layer)

	_pick_ui_highlight = PanelContainer.new()
	_pick_ui_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pick_ui_highlight.visible = false
	_pick_ui_highlight.add_theme_stylebox_override("panel", ToolkitTheme.make_pick_outline_style())
	add_child(_pick_ui_highlight)

	_pick_world_marker = PanelContainer.new()
	_pick_world_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pick_world_marker.custom_minimum_size = Vector2(20.0, 20.0)
	_pick_world_marker.size = Vector2(20.0, 20.0)
	_pick_world_marker.visible = false
	_pick_world_marker.add_theme_stylebox_override("panel", ToolkitTheme.make_pick_marker_style())
	add_child(_pick_world_marker)

	_pick_hint_panel = PanelContainer.new()
	_pick_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pick_hint_panel.anchor_left = 0.5
	_pick_hint_panel.anchor_right = 0.5
	_pick_hint_panel.offset_left = -260.0
	_pick_hint_panel.offset_right = 260.0
	_pick_hint_panel.offset_top = 14.0
	_pick_hint_panel.offset_bottom = 62.0
	_pick_hint_panel.visible = false
	_pick_hint_panel.theme = ToolkitTheme.load_game_theme()
	_pick_hint_panel.add_theme_stylebox_override("panel", ToolkitTheme.make_pick_hint_style())
	add_child(_pick_hint_panel)

	var pick_hint_margin := MarginContainer.new()
	pick_hint_margin.add_theme_constant_override("margin_left", 12)
	pick_hint_margin.add_theme_constant_override("margin_top", 8)
	pick_hint_margin.add_theme_constant_override("margin_right", 12)
	pick_hint_margin.add_theme_constant_override("margin_bottom", 8)
	_pick_hint_panel.add_child(pick_hint_margin)

	_pick_hint_label = Label.new()
	_pick_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pick_hint_label.text = "Pick mode active. Left click selects. Right click or Esc cancels. Space toggles freeze."
	pick_hint_margin.add_child(_pick_hint_label)

	_backdrop = ColorRect.new()
	_backdrop.anchor_right = 1.0
	_backdrop.anchor_bottom = 1.0
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.42)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.visible = false
	add_child(_backdrop)

	_panel = WindowChrome.new()
	_panel.visible = false
	_panel.theme = ToolkitTheme.load_game_theme()
	_panel.set_minimum_window_size(ToolkitConfig.MIN_WINDOW_SIZE)
	_panel.set_window_text(
		"RTV Tool Kit",
		"Live scene hierarchy, search, inspector, preview, world edit, runtime controls, files, groups, and watch lists."
	)
	_panel.geometry_changed.connect(_on_window_geometry_changed)
	_panel.close_requested.connect(_toggle_overlay)
	add_child(_panel)

	var root_vbox := _panel.get_content_root()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 10)

	_tabs = TabContainer.new()
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_tabs)

	ToolkitTabBuilder.build_tabs(self, _tabs)
	if _preview_viewport != null and _preview_viewport.has_signal("status_changed"):
		_preview_viewport.status_changed.connect(_on_preview_status_changed)
	if _preview_viewport != null:
		if _preview_viewport.has_method("set_marker_visibility") and _preview_markers_check != null:
			_preview_viewport.call("set_marker_visibility", _preview_markers_check.button_pressed)
		if _preview_viewport.has_method("set_floor_visibility") and _preview_floor_check != null:
			_preview_viewport.call("set_floor_visibility", _preview_floor_check.button_pressed)
		if _preview_viewport.has_method("set_axes_visibility") and _preview_axes_check != null:
			_preview_viewport.call("set_axes_visibility", _preview_axes_check.button_pressed)
		if _preview_viewport.has_method("set_auto_spin") and _preview_spin_check != null:
			_preview_viewport.call("set_auto_spin", _preview_spin_check.button_pressed)
	_set_preview_output(_preview_viewport.call("clear_preview") if _preview_viewport != null else {})

	var status_shell := PanelContainer.new()
	status_shell.add_theme_stylebox_override("panel", ToolkitTheme.make_footer_style())
	root_vbox.add_child(status_shell)

	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 12)
	status_margin.add_theme_constant_override("margin_top", 8)
	status_margin.add_theme_constant_override("margin_right", 12)
	status_margin.add_theme_constant_override("margin_bottom", 8)
	status_shell.add_child(status_margin)

	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
	status_margin.add_child(status_row)

	_status_label = Label.new()
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.modulate = Color(1.0, 1.0, 1.0, 0.68)
	status_row.add_child(_status_label)

	var drag_hint := Label.new()
	drag_hint.text = "Drag title bar. Resize from bottom-right."
	drag_hint.modulate = Color(1.0, 1.0, 1.0, 0.42)
	status_row.add_child(drag_hint)

	_refresh_pick_controls()


func _process_pick_mode() -> void:
	var hovered: Node = null
	if _pick_freeze_check != null and _pick_freeze_check.button_pressed and _pick_hover_path != "":
		hovered = get_node_or_null(_pick_hover_path)
	else:
		hovered = _find_pick_target(get_viewport().get_mouse_position())
	_update_pick_hover(hovered)


func _set_pick_mode(enabled: bool, reopen_panel: bool = true) -> void:
	_pick_enabled = enabled
	if enabled and _preview_viewport != null and _preview_viewport.has_method("release_pointer_capture"):
		_preview_viewport.call("release_pointer_capture")

	if _pick_capture_layer != null:
		_pick_capture_layer.visible = enabled
	if _pick_hint_panel != null:
		_pick_hint_panel.visible = enabled

	if enabled:
		_pick_hover_path = ""
		_clear_pick_visuals()
		if _backdrop != null:
			_backdrop.visible = false
		_panel.visible = false
		_show_cursor_for_overlay(true)
		_log_event("Pick mode enabled.")
		_set_status("Pick mode enabled.")
	else:
		_pick_hover_path = ""
		_clear_pick_visuals()
		if reopen_panel:
			_panel.visible = true
			if _backdrop != null:
				_backdrop.visible = true
			_apply_saved_window_geometry()
			_panel.grab_focus()
			_refresh_all_views(false)
		elif not _is_menu_scene():
			_show_cursor_for_overlay(false)
		_log_event("Pick mode disabled.")

	_refresh_pick_controls()


func _find_pick_target(mouse_position: Vector2) -> Node:
	var skip := Callable(self, "_is_toolkit_node")

	if _pick_controls_check == null or _pick_controls_check.button_pressed:
		var control_target: Control = ToolkitPicker.find_control_target(get_tree().root, mouse_position, skip)
		if control_target != null:
			return control_target

	if _pick_world_check == null or _pick_world_check.button_pressed:
		var world_target: Node = ToolkitPicker.find_world_target(get_viewport(), mouse_position, skip)
		if world_target != null:
			return world_target

	return null


func _update_pick_hover(node: Node) -> void:
	var new_path := _absolute_node_path(node) if node != null else ""
	if new_path != _pick_hover_path:
		_pick_hover_path = new_path
		_refresh_pick_controls()
	_update_pick_visuals(node)


func _update_pick_visuals(node: Node) -> void:
	_clear_pick_visuals()
	if node == null:
		return

	if node is Control:
		var rect := (node as Control).get_global_rect()
		_pick_ui_highlight.position = rect.position - Vector2(2.0, 2.0)
		_pick_ui_highlight.size = rect.size + Vector2(4.0, 4.0)
		_pick_ui_highlight.visible = true
		return

	var marker_position := _project_pick_marker(node)
	if marker_position == Vector2.INF:
		return

	_pick_world_marker.position = marker_position - (_pick_world_marker.size * 0.5)
	_pick_world_marker.visible = true


func _project_pick_marker(node: Node) -> Vector2:
	if node is Node3D:
		var camera := get_viewport().get_camera_3d()
		if camera == null:
			return Vector2.INF
		var point := (node as Node3D).global_position
		if camera.is_position_behind(point):
			return Vector2.INF
		return camera.unproject_position(point)

	if node is Node2D:
		return (node as Node2D).global_position

	return Vector2.INF


func _clear_pick_visuals() -> void:
	if _pick_ui_highlight != null:
		_pick_ui_highlight.visible = false
	if _pick_world_marker != null:
		_pick_world_marker.visible = false


func _refresh_pick_controls() -> void:
	if _pick_toggle_button != null:
		_pick_toggle_button.text = "Stop Pick" if _pick_enabled else "Start Pick"

	if _pick_script_owner_button != null:
		_pick_script_owner_button.disabled = _get_selected_node() == null

	if _pick_target_label != null:
		if _pick_enabled:
			var hovered := get_node_or_null(_pick_hover_path)
			if hovered != null:
				_pick_target_label.text = "Pick: %s" % _pick_node_label(hovered)
			else:
				_pick_target_label.text = "Pick: active, no target under cursor."
		else:
			var selected := _get_selected_node()
			if selected != null:
				_pick_target_label.text = "Pick: inactive | selected %s" % _pick_node_label(selected)
			else:
				_pick_target_label.text = "Pick: inactive"

	if _pick_hint_label != null and _pick_enabled:
		var hovered := get_node_or_null(_pick_hover_path)
		var target_text := _pick_node_label(hovered) if hovered != null else "no target"
		var freeze_text := "ON" if (_pick_freeze_check != null and _pick_freeze_check.button_pressed) else "OFF"
		_pick_hint_label.text = "Pick Mode  |  Left click selects  |  Right click or Esc cancels  |  Space freeze %s  |  %s" % [freeze_text, target_text]


func _pick_node_label(node: Node) -> String:
	if node == null:
		return "<none>"
	return "%s  %s" % [_node_display_name(node), _absolute_node_path(node)]


func _commit_pick_selection() -> void:
	var node := get_node_or_null(_pick_hover_path)
	if node == null:
		_set_status("No valid pick target.")
		return

	_set_selected_node(node)
	_rebuild_hierarchy_tree()
	_tabs.current_tab = TAB_INSPECTOR
	_set_pick_mode(false, true)
	_log_event("Picked node %s." % _absolute_node_path(node))
	_set_status("Picked %s." % _absolute_node_path(node))


func _select_script_owner() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return

	var target: Node = ToolkitPicker.find_nearest_script_owner(node, Callable(self, "_is_toolkit_node"))
	if target == null:
		_set_status("No script owner found for current selection.")
		return

	_set_selected_node(target)
	_rebuild_hierarchy_tree()
	_tabs.current_tab = TAB_INSPECTOR
	_log_event("Selected script owner %s." % _absolute_node_path(target))
	_set_status("Selected script owner.")


func _is_toolkit_node(node: Node) -> bool:
	return node == self or _node_is_descendant(self, node)


func _on_pick_capture_gui_input(event: InputEvent) -> void:
	if not _pick_enabled:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_commit_pick_selection()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_set_pick_mode(false, true)
			_set_status("Pick mode cancelled.")
			get_viewport().set_input_as_handled()


func _apply_saved_window_geometry() -> void:
	if _panel == null:
		return
	_panel.restore_geometry(_window_position, _window_size)


func _on_root_resized() -> void:
	if _panel != null:
		_panel.clamp_to_viewport()


func _on_window_geometry_changed(window_position: Vector2, window_size: Vector2) -> void:
	_window_position = window_position
	_window_size = window_size
	_save_state()


func _toggle_overlay() -> void:
	_panel.visible = not _panel.visible
	if _backdrop != null:
		_backdrop.visible = _panel.visible
	_refresh_accumulator = 0.0
	if not _panel.visible and _preview_viewport != null and _preview_viewport.has_method("release_pointer_capture"):
		_preview_viewport.call("release_pointer_capture")

	if _panel.visible:
		_apply_saved_window_geometry()
		_panel.grab_focus()
		_refresh_all_views(false)
		_show_cursor_for_overlay(true)
		_log_event("Overlay opened.")
		_set_status("Overlay open.")
	else:
		_save_state()
		_show_cursor_for_overlay(false)
		_log_event("Overlay hidden.")
		_set_status("Overlay hidden.")


func _show_cursor_for_overlay(show_cursor: bool) -> void:
	var loader := get_node_or_null("/root/Loader")
	if loader == null:
		return

	if show_cursor:
		if loader.has_method("ShowCursor"):
			loader.ShowCursor()
	else:
		if not _is_menu_scene() and loader.has_method("HideCursor"):
			loader.HideCursor()


func _ensure_menu_button() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if String(scene.scene_file_path) != MENU_SCENE_PATH:
		return

	var buttons := scene.get_node_or_null("Main/Buttons")
	if buttons == null:
		return
	if buttons.get_node_or_null(MENU_BUTTON_NAME) != null:
		return

	var button := Button.new()
	button.name = MENU_BUTTON_NAME
	button.text = "Tool Kit"
	button.tooltip_text = "Open RTV Tool Kit (F8)"
	button.pressed.connect(_toggle_overlay)
	buttons.add_child(button)

	var quit_button := buttons.get_node_or_null("Quit")
	if quit_button != null:
		buttons.move_child(button, max(0, quit_button.get_index()))

	_log_event("Injected Tool Kit button into menu.")


func _refresh_all_views(log_it: bool) -> void:
	_refresh_overview_report()
	_rebuild_hierarchy_tree()
	_refresh_inspector()
	_refresh_world_controls()
	_refresh_file_list()
	_refresh_runtime_controls()
	_refresh_diagnostics_view()
	_refresh_groups_view()
	_refresh_watch_view()
	_refresh_log_view()
	_refresh_transaction_views()
	_refresh_pick_controls()

	if log_it:
		_log_event("Manual refresh completed.")


func _refresh_dynamic_views() -> void:
	_refresh_overview_report()
	if _tabs == null or _tabs.current_tab == TAB_INSPECTOR:
		_refresh_inspector_dynamic()
	if _tabs == null or _tabs.current_tab != TAB_WORLD:
		_refresh_world_controls()
	if _tabs == null or _tabs.current_tab != TAB_FILES:
		_refresh_file_preview()
	if _tabs == null or _tabs.current_tab != TAB_RUNTIME:
		_refresh_runtime_controls()
	if _tabs != null and _tabs.current_tab == TAB_DIAGNOSTICS:
		_refresh_diagnostics_view()
	_refresh_groups_view()
	_refresh_watch_view()


func _refresh_overview_report() -> void:
	var report := _build_overview_report()
	if report == _last_report_text:
		return

	_last_report_text = report
	_overview_label.clear()
	_overview_label.append_text(report)


func _build_overview_report() -> String:
	var lines: Array[String] = []

	lines.append("RTV Tool Kit v%s" % VERSION)
	lines.append("Generated: %s" % Time.get_datetime_string_from_system())
	lines.append("")

	_append_scene_section(lines)
	_append_toolkit_section(lines)
	_append_selection_section(lines)
	_append_game_data_section(lines)
	_append_simulation_section(lines)
	_append_loader_section(lines)
	_append_group_counts_section(lines)
	_append_notes_section(lines)
	_append_root_section(lines)
	_append_user_file_summary_section(lines)

	return "\n".join(lines)


func _refresh_diagnostics_view() -> void:
	_diagnostics_data = ToolkitDiagnostics.collect(get_tree(), _get_selected_node())
	_refresh_diagnostics_report()
	_refresh_diagnostics_lists()
	_refresh_diagnostics_detail()


func _refresh_diagnostics_report() -> void:
	if _diagnostics_report == null:
		return

	_last_diagnostics_report_text = String(_diagnostics_data.get("report", ""))
	_diagnostics_report.clear()
	_diagnostics_report.append_text(_last_diagnostics_report_text)


func _refresh_diagnostics_lists() -> void:
	var previous_focus_kind := _diagnostics_focus_kind
	var previous_focus_key := _diagnostics_focus_key

	if _diagnostics_mod_list != null:
		_diagnostics_mod_list.clear()
		for mod_data in _as_array(_diagnostics_data.get("loaded_mods", [])):
			if not (mod_data is Dictionary):
				continue
			var mod_entry: Dictionary = mod_data
			var issue_titles := _as_array(mod_entry.get("issue_titles", []))
			var label := "%s%s" % [
				"[Loaded] " if bool(mod_entry.get("loaded", false)) else "",
				String(mod_entry.get("mod_name", "")),
			]
			if not issue_titles.is_empty():
				label += "  !%d" % issue_titles.size()
			var index := _diagnostics_mod_list.get_item_count()
			_diagnostics_mod_list.add_item(label)
			_diagnostics_mod_list.set_item_metadata(index, String(mod_entry.get("mod_id", "")))

	if _diagnostics_issue_list != null:
		_diagnostics_issue_list.clear()
		for issue_data in _as_array(_diagnostics_data.get("issues", [])):
			if not (issue_data is Dictionary):
				continue
			var issue: Dictionary = issue_data
			var label := "[%s] %s" % [String(issue.get("severity", "")), String(issue.get("title", ""))]
			var index := _diagnostics_issue_list.get_item_count()
			_diagnostics_issue_list.add_item(label)
			_diagnostics_issue_list.set_item_metadata(index, String(issue.get("id", "")))

	_restore_diagnostics_focus(previous_focus_kind, previous_focus_key)


func _restore_diagnostics_focus(kind: String, key: String) -> void:
	if kind == "" or key == "":
		return

	var target_list: ItemList = _diagnostics_mod_list if kind == "mod" else _diagnostics_issue_list
	if target_list == null:
		return

	for index in range(target_list.get_item_count()):
		if String(target_list.get_item_metadata(index)) == key:
			target_list.select(index)
			_diagnostics_focus_kind = kind
			_diagnostics_focus_key = key
			return


func _refresh_diagnostics_detail() -> void:
	if _diagnostics_detail == null:
		return

	var detail_text := ToolkitDiagnostics.build_default_detail(_diagnostics_data)
	if _diagnostics_focus_kind == "mod":
		var mod_data := _find_diagnostics_mod(_diagnostics_focus_key)
		if not mod_data.is_empty():
			detail_text = ToolkitDiagnostics.build_mod_detail(mod_data)
	elif _diagnostics_focus_kind == "issue":
		var issue := _find_diagnostics_issue(_diagnostics_focus_key)
		if not issue.is_empty():
			detail_text = ToolkitDiagnostics.build_issue_detail(issue)

	_diagnostics_detail.clear()
	_diagnostics_detail.append_text(detail_text)


func _find_diagnostics_mod(mod_id: String) -> Dictionary:
	for mod_data in _as_array(_diagnostics_data.get("loaded_mods", [])):
		if mod_data is Dictionary and String(mod_data.get("mod_id", "")) == mod_id:
			return mod_data
	return {}


func _find_diagnostics_issue(issue_id: String) -> Dictionary:
	for issue_data in _as_array(_diagnostics_data.get("issues", [])):
		if issue_data is Dictionary and String(issue_data.get("id", "")) == issue_id:
			return issue_data
	return {}


func _rebuild_hierarchy_tree() -> void:
	if _hierarchy_tree == null:
		return

	_hierarchy_tree.clear()
	var filter := ""
	if _hierarchy_filter_edit != null:
		filter = _hierarchy_filter_edit.text.strip_edges().to_lower()
	var root_item := _hierarchy_tree.create_item()
	root_item.set_text(0, "/root")
	root_item.set_metadata(0, "/root")
	root_item.set_collapsed(false)

	for child in get_tree().root.get_children():
		if child is Node and _hierarchy_branch_matches_filter(child, filter):
			_add_hierarchy_branch(root_item, child, 0)

	_select_hierarchy_item_by_path(root_item, _selected_node_path)


func _add_hierarchy_branch(parent_item: TreeItem, node: Node, depth: int) -> void:
	var item := _hierarchy_tree.create_item(parent_item)
	item.set_text(0, _node_display_name(node))
	item.set_metadata(0, _absolute_node_path(node))
	item.set_collapsed(depth >= 2)

	var filter := ""
	if _hierarchy_filter_edit != null:
		filter = _hierarchy_filter_edit.text.strip_edges().to_lower()

	for child in node.get_children():
		if child is Node and _hierarchy_branch_matches_filter(child, filter):
			_add_hierarchy_branch(item, child, depth + 1)


func _select_hierarchy_item_by_path(item: TreeItem, target_path: String) -> bool:
	if item == null or target_path == "":
		return false
	if String(item.get_metadata(0)) == target_path:
		item.select(0)
		return true

	var child := item.get_first_child()
	while child != null:
		if _select_hierarchy_item_by_path(child, target_path):
			item.set_collapsed(false)
			return true
		child = child.get_next()

	return false


func _run_search(open_tab: bool) -> void:
	var query := _search_query_edit.text.strip_edges().to_lower()
	var mode := _search_mode.get_selected_id()
	_search_results.clear()
	_search_match_paths.clear()

	var nodes: Array[Node] = []
	if _search_selected_scope_check != null and _search_selected_scope_check.button_pressed and _get_selected_node() != null:
		_collect_node_recursive(_get_selected_node(), nodes)
	else:
		nodes = _collect_all_nodes()

	var count := 0
	for node in nodes:
		if not _matches_search(node, query, mode):
			continue

		var index := _search_results.get_item_count()
		var path := _absolute_node_path(node)
		_search_results.add_item("%s [%s] %s" % [node.name, node.get_class(), path])
		_search_results.set_item_metadata(index, path)
		_search_match_paths.append(path)
		count += 1

	if open_tab:
		_tabs.current_tab = TAB_SEARCH

	_log_event("Search returned %d node(s) for '%s'." % [count, query])
	_set_status("Search returned %d node(s)." % count)


func _matches_search(node: Node, query: String, mode: int) -> bool:
	if query == "":
		return true

	var name_text := node.name.to_lower()
	var class_text := node.get_class().to_lower()
	var path_text := _absolute_node_path(node).to_lower()
	var script_text := ""
	var script_value = _read_property(node, "script", null)
	if script_value != null:
		script_text = String(_read_property(script_value, "resource_path", "")).to_lower()

	match mode:
		1:
			return name_text.contains(query)
		2:
			return class_text.contains(query)
		3:
			return path_text.contains(query)
		4:
			for group_name in node.get_groups():
				if String(group_name).to_lower().contains(query):
					return true
			return false
		5:
			return script_text.contains(query)
		6:
			for method_info in node.get_method_list():
				if String(method_info.get("name", "")).to_lower().contains(query):
					return true
			return false
		7:
			for property_info in node.get_property_list():
				if String(property_info.get("name", "")).to_lower().contains(query):
					return true
			return false
		_:
			if name_text.contains(query) or class_text.contains(query) or path_text.contains(query) or script_text.contains(query):
				return true
			for group_name in node.get_groups():
				if String(group_name).to_lower().contains(query):
					return true
			for method_info in node.get_method_list():
				if String(method_info.get("name", "")).to_lower().contains(query):
					return true
			for property_info in node.get_property_list():
				if String(property_info.get("name", "")).to_lower().contains(query):
					return true
			return false


func _hierarchy_branch_matches_filter(node: Node, filter: String) -> bool:
	if filter == "":
		return true
	if _node_display_name(node).to_lower().contains(filter):
		return true
	if _absolute_node_path(node).to_lower().contains(filter):
		return true
	for child in node.get_children():
		if child is Node and _hierarchy_branch_matches_filter(child, filter):
			return true
	return false


func _refresh_inspector() -> void:
	var node := _get_selected_node()
	if _inspector_path_edit != null:
		_inspector_path_edit.text = _selected_node_path
	_refresh_property_tree(node)
	_refresh_inspector_dynamic()


func _refresh_inspector_dynamic() -> void:
	var node := _get_selected_node()
	if node == null:
		_inspector_selected_property = ""
		if _inspector_meta != null:
			_inspector_meta.clear()
			_inspector_meta.append_text("No node selected.")
		if _inspector_watch_view != null:
			_inspector_watch_view.clear()
			_inspector_watch_view.append_text("No live property watches.")
		if _resource_meta != null:
			_resource_meta.clear()
			_resource_meta.append_text("No property/resource selection.")
		_refresh_property_action_buttons(null)
		return

	var lines: Array[String] = []
	lines.append("Path: %s" % _absolute_node_path(node))
	lines.append("Name: %s" % node.name)
	lines.append("Class: %s" % node.get_class())
	lines.append("Child Count: %d" % node.get_child_count())
	lines.append("Owner: %s" % _owner_label(node))
	lines.append("Owner Chain: %s" % _owner_chain_label(node))
	lines.append("Scene File: %s" % _value_or_placeholder(String(_read_property(node, "scene_file_path", ""))))
	lines.append("Script: %s" % _resource_ref_label(node.get_script()))

	var groups: Array[String] = []
	for group_name in node.get_groups():
		groups.append(String(group_name))
	groups.sort()
	lines.append("Groups: %s" % ("none" if groups.is_empty() else ", ".join(groups)))

	lines.append("Transform: %s" % _transform_summary(node))
	lines.append("Methods: %s" % _method_summary(node))
	lines.append("Signals: %s" % _signal_summary(node))
	lines.append("Connections: %s" % _connection_summary(node))
	lines.append("Changed Since Selection: %d" % _count_changed_properties(node))

	if _inspector_meta != null:
		_inspector_meta.clear()
		_inspector_meta.append_text("\n".join(lines))

	_refresh_property_watch_panel(node)
	_refresh_resource_meta(node)
	_refresh_property_action_buttons(node)


func _refresh_property_tree(node: Node) -> void:
	_property_tree.clear()
	var root := _property_tree.create_item()
	if node == null:
		return

	root.set_text(0, "Property")
	root.set_text(1, "Type")
	root.set_text(2, "Value")

	var filter := _property_filter_edit.text.strip_edges().to_lower()
	var show_changed_only := _property_changed_only_check != null and _property_changed_only_check.button_pressed
	var shown := 0
	var categories := {
		"Pinned": [] as Array[Dictionary],
		"Watched": [] as Array[Dictionary],
		"Changed": [] as Array[Dictionary],
		"Identity": [] as Array[Dictionary],
		"Transform": [] as Array[Dictionary],
		"Resources": [] as Array[Dictionary],
		"State": [] as Array[Dictionary],
	}

	for property_info in node.get_property_list():
		var name := String(property_info.get("name", ""))
		if name == "":
			continue
		if filter != "" and not name.to_lower().contains(filter):
			continue

		var type_id := int(property_info.get("type", TYPE_NIL))
		var value = node.get(name)
		var changed := _is_property_changed(name, value)
		if show_changed_only and not changed:
			continue

		var pinned := _pinned_properties.has(name)
		var watched := _watched_properties.has(name)
		var category := _property_category(name, type_id, value, pinned, watched, changed)
		categories[category].append({
			"name": name,
			"type_id": type_id,
			"value": value,
			"value_text": _format_variant(value),
			"changed": changed,
			"pinned": pinned,
			"watched": watched,
		})

		shown += 1
		if shown >= MAX_INSPECTOR_PROPERTIES:
			break

	var ordered_categories := ["Pinned", "Watched", "Changed", "Identity", "Transform", "Resources", "State"]
	for category_name in ordered_categories:
		var items: Array = categories.get(category_name, [])
		if items.is_empty():
			continue
		var category_item := _property_tree.create_item(root)
		category_item.set_text(0, "%s (%d)" % [category_name, items.size()])
		category_item.set_metadata(0, {"kind": "category"})
		category_item.set_selectable(0, false)
		category_item.set_selectable(1, false)
		category_item.set_selectable(2, false)
		category_item.set_collapsed(false)

		for item_data in items:
			var item := _property_tree.create_item(category_item)
			var label := String(item_data["name"])
			if bool(item_data["pinned"]):
				label = "[Pin] " + label
			elif bool(item_data["watched"]):
				label = "[Watch] " + label
			elif bool(item_data["changed"]):
				label = "[Changed] " + label
			item.set_text(0, label)
			item.set_text(1, _type_name(int(item_data["type_id"])))
			item.set_text(2, String(item_data["value_text"]))
			item.set_metadata(0, {"kind": "property", "name": item_data["name"], "type_id": item_data["type_id"]})
			if bool(item_data["changed"]):
				item.set_custom_color(0, Color(0.72, 0.95, 1.0, 1.0))
			elif bool(item_data["pinned"]):
				item.set_custom_color(0, Color(1.0, 0.90, 0.55, 1.0))
			elif bool(item_data["watched"]):
				item.set_custom_color(0, Color(0.80, 1.0, 0.72, 1.0))

	if shown >= MAX_INSPECTOR_PROPERTIES:
		var limit_item := _property_tree.create_item(root)
		limit_item.set_text(0, "...")
		limit_item.set_text(2, "Inspector limit reached.")
		limit_item.set_metadata(0, {"kind": "meta"})
	elif shown == 0:
		var empty_item := _property_tree.create_item(root)
		empty_item.set_text(0, "No matching properties.")
		empty_item.set_metadata(0, {"kind": "meta"})

	if _inspector_selected_property != "":
		_select_property_tree_item(root, _inspector_selected_property)


func _select_property_tree_item(item: TreeItem, target_name: String) -> bool:
	if item == null or target_name == "":
		return false

	var metadata = item.get_metadata(0)
	if metadata is Dictionary and String(metadata.get("kind", "")) == "property" and String(metadata.get("name", "")) == target_name:
		item.select(0)
		return true

	var child := item.get_first_child()
	while child != null:
		if _select_property_tree_item(child, target_name):
			item.set_collapsed(false)
			return true
		child = child.get_next()
	return false


func _select_option_button_id(option_button: OptionButton, target_id: int) -> void:
	if option_button == null:
		return

	for index in range(option_button.get_item_count()):
		if option_button.get_item_id(index) == target_id:
			option_button.select(index)
			return

	if option_button.get_item_count() > 0:
		option_button.select(0)


func _inspector_parse_mode_for_type(type_id: int) -> int:
	match type_id:
		TYPE_BOOL:
			return 1
		TYPE_INT:
			return 2
		TYPE_FLOAT:
			return 3
		TYPE_STRING, TYPE_STRING_NAME:
			return 4
		TYPE_VECTOR2:
			return 5
		TYPE_VECTOR3:
			return 6
		TYPE_COLOR:
			return 7
		TYPE_NODE_PATH:
			return 8
		TYPE_ARRAY:
			return 9
		TYPE_DICTIONARY:
			return 10
		_:
			return 0


func _sync_inspector_property_selection(node: Node, property_name: String, type_id: int = TYPE_NIL, pull_value: bool = true) -> bool:
	if node == null or property_name == "" or not _has_property(node, property_name):
		return false

	var value = node.get(property_name)
	var effective_type := type_id
	if typeof(value) != TYPE_NIL:
		effective_type = typeof(value)

	_inspector_selected_property = property_name
	_inspector_selected_property_type = effective_type

	if _property_name_edit != null and _property_name_edit.text != property_name:
		_property_name_edit.text = property_name
	_select_option_button_id(_property_type_option, _inspector_parse_mode_for_type(effective_type))
	if pull_value and _property_value_edit != null:
		_property_value_edit.text = _format_variant_edit(value)

	_refresh_resource_meta(node)
	_refresh_property_action_buttons(node)
	return true


func _property_full_path(node: Node, property_name: String) -> String:
	if node == null or property_name == "":
		return property_name
	return "%s.%s" % [_absolute_node_path(node), property_name]


func _refresh_property_watch_panel(node: Node) -> void:
	if _inspector_watch_view == null:
		return

	_inspector_watch_view.clear()
	if node == null:
		_inspector_watch_view.append_text("No live property watches.")
		return

	var lines: Array[String] = []
	lines.append("[Live Watch]")
	var watch_count := 0
	for property_name in _watched_properties:
		if not _has_property(node, property_name):
			continue
		lines.append("%s = %s" % [property_name, _format_variant(node.get(property_name))])
		watch_count += 1
	if watch_count == 0:
		lines.append("No watched properties on this node.")

	lines.append("")
	lines.append("[Pinned]")
	var pinned_count := 0
	for property_name in _pinned_properties:
		if not _has_property(node, property_name):
			continue
		var changed_marker := " [changed]" if _is_property_changed(property_name, node.get(property_name)) else ""
		lines.append("%s = %s%s" % [property_name, _format_variant(node.get(property_name)), changed_marker])
		pinned_count += 1
	if pinned_count == 0:
		lines.append("No pinned properties on this node.")

	_inspector_watch_view.append_text("\n".join(lines))


func _refresh_resource_meta(node: Node) -> void:
	if _resource_meta == null:
		return

	_resource_meta.clear()
	if node == null:
		_resource_meta.append_text("No property/resource selection.")
		return

	var lines: Array[String] = []
	lines.append("[Selected Property]")
	var property_name := _resolve_target_property_name()
	if property_name == "" or not _has_property(node, property_name):
		lines.append("No property selected.")
		lines.append("")
		lines.append("[Node Script]")
		lines.append(_resource_ref_label(node.get_script()))
		lines.append("")
		lines.append("[Owner / Runtime]")
		lines.append("Owner Chain: %s" % _owner_chain_label(node))
		for detail in _signal_detail_lines(node):
			lines.append(detail)
		for detail in _connection_detail_lines(node):
			lines.append(detail)
		_resource_meta.append_text("\n".join(lines))
		return

	var value = node.get(property_name)
	lines.append("Path: %s.%s" % [_absolute_node_path(node), property_name])
	lines.append("Type: %s" % _type_name(typeof(value) if typeof(value) != TYPE_NIL else _inspector_selected_property_type))
	lines.append("Changed: %s" % _bool_string(_is_property_changed(property_name, value)))
	lines.append("Current: %s" % _format_variant(value))
	if _inspector_baseline_values.has(property_name):
		lines.append("Baseline: %s" % _format_variant_edit(_inspector_baseline_values[property_name]))
		if _is_property_changed(property_name, value):
			lines.append("Diff: live value differs from the selection baseline.")
	lines.append("")
	lines.append("[Resource / Object]")
	for detail in _resource_detail_lines(value):
		lines.append(detail)
	lines.append("")
	lines.append("[Owner / Runtime]")
	lines.append("Owner Chain: %s" % _owner_chain_label(node))
	for detail in _signal_detail_lines(node):
		lines.append(detail)
	for detail in _connection_detail_lines(node):
		lines.append(detail)

	_resource_meta.append_text("\n".join(lines))


func _refresh_property_action_buttons(node: Node) -> void:
	var property_name := _resolve_target_property_name()
	var has_property := node != null and property_name != "" and _has_property(node, property_name)

	if _property_pin_button != null:
		_property_pin_button.text = "Unpin" if _pinned_properties.has(property_name) else "Pin"
		_property_pin_button.disabled = not has_property
	if _property_watch_button != null:
		_property_watch_button.text = "Unwatch" if _watched_properties.has(property_name) else "Watch"
		_property_watch_button.disabled = not has_property
	if _property_revert_button != null:
		_property_revert_button.disabled = not has_property or not _inspector_baseline_values.has(property_name) or not _is_property_changed(property_name, node.get(property_name))


func _set_preview_output(result: Dictionary) -> void:
	var summary_lines := _stringify_array(_as_array(result.get("summary_lines", [])))
	var scene_lines := _stringify_array(_as_array(result.get("scene_lines", [])))

	if _preview_summary != null:
		_preview_summary.clear()
		_preview_summary.append_text("\n".join(summary_lines if not summary_lines.is_empty() else ["No preview loaded."]))

	if _preview_scene_report != null:
		_preview_scene_report.clear()
		_preview_scene_report.append_text("\n".join(scene_lines if not scene_lines.is_empty() else ["No preview report available."]))

	if _preview_icon_rect != null:
		var icon_texture = result.get("icon")
		_preview_icon_rect.texture = icon_texture if icon_texture is Texture2D else null

	if _preview_source_path_edit != null:
		var resource_path := String(result.get("resource_path", ""))
		var scene_path := String(result.get("scene_path", ""))
		if resource_path != "":
			_preview_source_path_edit.text = resource_path
		elif scene_path != "":
			_preview_source_path_edit.text = scene_path

	if _preview_special_list != null:
		_preview_special_list.clear()
		for entry in _as_array(result.get("special_entries", [])):
			if not (entry is Dictionary):
				continue
			var label := String(entry.get("label", ""))
			if label == "":
				label = String(entry.get("path", ""))
			var index := _preview_special_list.get_item_count()
			_preview_special_list.add_item(label)
			_preview_special_list.set_item_metadata(index, String(entry.get("path", "")))


func _build_preview_report_text() -> String:
	var lines: Array[String] = []
	if _preview_summary != null:
		lines.append(_preview_summary.get_parsed_text())
	if _preview_scene_report != null:
		if not lines.is_empty():
			lines.append("")
		lines.append(_preview_scene_report.get_parsed_text())
	if _preview_special_list != null and _preview_special_list.get_item_count() > 0:
		lines.append("")
		lines.append("[Special Nodes]")
		for index in range(_preview_special_list.get_item_count()):
			lines.append(_preview_special_list.get_item_text(index))
	return "\n".join(lines)


func _load_preview_source(source, path_hint: String = "", source_label: String = "") -> void:
	if _preview_viewport == null or not _preview_viewport.has_method("load_source"):
		_set_status("Preview viewport is unavailable.")
		return

	var result = _preview_viewport.call("load_source", source, path_hint, source_label)
	if result is Dictionary:
		_set_preview_output(result)
	else:
		_set_preview_output({
			"summary_lines": ["Preview returned no data."],
			"scene_lines": ["Preview load failed."],
		})

	if _tabs != null:
		_tabs.current_tab = TAB_PREVIEW


func _set_preview_error(message: String, summary_lines: Array[String] = [], resource_path: String = "") -> void:
	var resolved_summary := summary_lines
	if resolved_summary.is_empty():
		resolved_summary = ["Preview failed."]
	_set_preview_output({
		"summary_lines": resolved_summary,
		"scene_lines": [message],
		"resource_path": resource_path,
		"scene_path": "",
		"special_entries": [],
	})
	if _tabs != null:
		_tabs.current_tab = TAB_PREVIEW
	_set_status(message)


func _extract_preview_scene_path(node: Node) -> String:
	if node == null:
		return ""
	var scene_path := String(_read_property(node, "scene_file_path", "")).strip_edges()
	if scene_path.begins_with("res://") and ResourceLoader.exists(scene_path):
		return scene_path
	return ""


func _extract_preview_mesh(node: Node):
	if node == null:
		return null
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return (node as MeshInstance3D).mesh
	if _has_property(node, "mesh"):
		var mesh_value = node.get("mesh")
		if mesh_value is Mesh:
			return mesh_value
	return null


func _extract_preview_texture(node: Node):
	if node == null:
		return null
	if node is Sprite2D and (node as Sprite2D).texture != null:
		return (node as Sprite2D).texture
	if node is Sprite3D and (node as Sprite3D).texture != null:
		return (node as Sprite3D).texture
	if node is TextureRect and (node as TextureRect).texture != null:
		return (node as TextureRect).texture
	for property_name in ["texture", "icon"]:
		if _has_property(node, property_name):
			var texture_value = node.get(property_name)
			if texture_value is Texture2D:
				return texture_value
	return null


func _resolve_safe_preview_from_node(node: Node) -> Dictionary:
	var node_path := _absolute_node_path(node)
	var direct_scene_path := _extract_preview_scene_path(node)
	if direct_scene_path != "":
		var scene_resource = load(direct_scene_path)
		if scene_resource != null:
			return {
				"ok": true,
				"source": scene_resource,
				"path_hint": direct_scene_path,
				"source_label": node_path,
				"message": "Loaded selected scene node into preview.",
			}

	var mesh = _extract_preview_mesh(node)
	if mesh is Mesh:
		return {
			"ok": true,
			"source": mesh,
			"path_hint": "",
			"source_label": node_path,
			"message": "Previewing mesh from selected node.",
		}

	var texture = _extract_preview_texture(node)
	if texture is Texture2D:
		return {
			"ok": true,
			"source": texture,
			"path_hint": "",
			"source_label": node_path,
			"message": "Previewing texture from selected node.",
		}

	return {
		"ok": false,
		"error": "Selected live node has no safe standalone preview target. Try a resource property or a res:// scene path.",
		"summary_lines": [
			"Node: %s" % node_path,
			"Safe preview avoids duplicating live runtime nodes.",
		],
		"resource_path": direct_scene_path,
	}


func _load_preview_from_selected_node() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node to preview.")
		return

	var resolved := _resolve_safe_preview_from_node(node)
	if not bool(resolved.get("ok", false)):
		_set_preview_error(
			String(resolved.get("error", "Selected node could not be previewed safely.")),
			_stringify_array(_as_array(resolved.get("summary_lines", []))),
			String(resolved.get("resource_path", ""))
		)
		return

	_load_preview_source(
		resolved.get("source"),
		String(resolved.get("path_hint", "")),
		String(resolved.get("source_label", _absolute_node_path(node)))
	)
	_set_status(String(resolved.get("message", "Loaded selected node into preview.")))


func _load_preview_from_selected_property() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return

	var property_name := _resolve_target_property_name()
	if property_name == "" or not _has_property(node, property_name):
		_set_status("Select a property first.")
		return

	var value = node.get(property_name)
	var preview_source = value
	var path_hint := ""
	var source_label := "%s.%s" % [_absolute_node_path(node), property_name]

	match typeof(value):
		TYPE_OBJECT:
			if value == null:
				_set_status("Selected property is null.")
				return
			if value is Node:
				var resolved := _resolve_safe_preview_from_node(value)
				if not bool(resolved.get("ok", false)):
					_set_preview_error(
						String(resolved.get("error", "Selected node property could not be previewed safely.")),
						_stringify_array(_as_array(resolved.get("summary_lines", []))),
						String(resolved.get("resource_path", ""))
					)
					return
				preview_source = resolved.get("source")
				path_hint = String(resolved.get("path_hint", ""))
				source_label = String(resolved.get("source_label", source_label))
			elif value is Resource:
				path_hint = String((value as Resource).resource_path)
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			var text := String(value).strip_edges()
			if text.begins_with("/root/"):
				var target_node := get_node_or_null(text)
				if target_node == null:
					_set_status("Node path not found: %s" % text)
					return
				var target_resolved := _resolve_safe_preview_from_node(target_node)
				if not bool(target_resolved.get("ok", false)):
					_set_preview_error(
						String(target_resolved.get("error", "Target node could not be previewed safely.")),
						_stringify_array(_as_array(target_resolved.get("summary_lines", []))),
						String(target_resolved.get("resource_path", ""))
					)
					return
				preview_source = target_resolved.get("source")
				path_hint = String(target_resolved.get("path_hint", ""))
				source_label = String(target_resolved.get("source_label", source_label))
			elif text.begins_with("res://"):
				if not ResourceLoader.exists(text):
					_set_status("Resource path not found: %s" % text)
					return
				preview_source = load(text)
				path_hint = text
			else:
				_set_status("Selected property is not previewable.")
				return
		_:
			_set_status("Selected property is not previewable.")
			return

	_load_preview_source(preview_source, path_hint, source_label)
	_set_status("Loaded selected property into preview.")


func _load_preview_from_manual_path() -> void:
	if _preview_source_path_edit == null:
		_set_status("Preview path field is unavailable.")
		return

	var path := _preview_source_path_edit.text.strip_edges()
	if path == "":
		_set_status("Preview path is empty.")
		return

	if path.begins_with("/root/"):
		var node := get_node_or_null(path)
		if node == null:
			_set_status("Node path not found: %s" % path)
			return
		var resolved := _resolve_safe_preview_from_node(node)
		if not bool(resolved.get("ok", false)):
			_set_preview_error(
				String(resolved.get("error", "Node path could not be previewed safely.")),
				_stringify_array(_as_array(resolved.get("summary_lines", []))),
				String(resolved.get("resource_path", ""))
			)
			return
		_load_preview_source(
			resolved.get("source"),
			String(resolved.get("path_hint", "")),
			String(resolved.get("source_label", path))
		)
		_set_status(String(resolved.get("message", "Loaded node path into preview.")))
		return

	if not ResourceLoader.exists(path):
		_set_status("Resource path not found: %s" % path)
		return

	var resource = load(path)
	if resource == null:
		_set_status("Failed to load %s." % path)
		return

	_load_preview_source(resource, path, path)
	_set_status("Loaded preview path.")


func _capture_inspector_baseline(node: Node) -> void:
	_inspector_baseline_values.clear()
	_inspector_baseline_signatures.clear()
	_inspector_selected_property = ""
	_inspector_selected_property_type = TYPE_NIL
	if _property_name_edit != null:
		_property_name_edit.text = ""
	if _property_value_edit != null:
		_property_value_edit.text = ""
	_select_option_button_id(_property_type_option, 0)

	if node == null:
		return

	for property_info in node.get_property_list():
		var name := String(property_info.get("name", ""))
		if name == "":
			continue
		var value = node.get(name)
		_inspector_baseline_values[name] = _duplicate_variant_for_baseline(value)
		_inspector_baseline_signatures[name] = _variant_signature(value)


func _duplicate_variant_for_baseline(value):
	match typeof(value):
		TYPE_ARRAY:
			return value.duplicate(true)
		TYPE_DICTIONARY:
			return value.duplicate(true)
		TYPE_OBJECT:
			if value == null:
				return null
			if value is Resource:
				return value.duplicate(true)
			return value
		_:
			return value


func _variant_signature(value) -> String:
	match typeof(value):
		TYPE_ARRAY, TYPE_DICTIONARY:
			return JSON.stringify(value)
		TYPE_OBJECT:
			if value == null:
				return "object:null"
			if value is Resource:
				return "resource:%s|%s" % [value.get_class(), String(value.resource_path)]
			if value is Node:
				return "node:%s" % _absolute_node_path(value)
			return "object:%s" % value.get_class()
		_:
			return "%s|%s" % [typeof(value), _format_variant_edit(value)]


func _is_property_changed(property_name: String, current_value) -> bool:
	if not _inspector_baseline_signatures.has(property_name):
		return false
	return String(_inspector_baseline_signatures[property_name]) != _variant_signature(current_value)


func _count_changed_properties(node: Node) -> int:
	if node == null:
		return 0
	var count := 0
	for property_info in node.get_property_list():
		var property_name := String(property_info.get("name", ""))
		if property_name != "" and _is_property_changed(property_name, node.get(property_name)):
			count += 1
	return count


func _property_category(property_name: String, type_id: int, value, pinned: bool, watched: bool, changed: bool) -> String:
	if pinned:
		return "Pinned"
	if watched:
		return "Watched"
	if changed:
		return "Changed"

	var lower := property_name.to_lower()
	if lower in ["name", "process_mode", "owner", "script", "scene_file_path", "visible"]:
		return "Identity"
	if lower.contains("position") or lower.contains("rotation") or lower.contains("scale") or lower.contains("transform") or lower.contains("size") or lower.contains("offset"):
		return "Transform"
	if type_id == TYPE_OBJECT or value is Resource or lower.contains("resource") or lower.contains("material") or lower.contains("texture") or lower.contains("mesh") or lower.contains("script"):
		return "Resources"
	return "State"


func _owner_chain_label(node: Node) -> String:
	var chain: Array[String] = []
	var cursor := node.owner
	while cursor != null:
		chain.append(cursor.name)
		cursor = cursor.owner
	return " > ".join(chain) if not chain.is_empty() else "<none>"


func _signal_detail_lines(node: Object) -> Array[String]:
	var signal_lines: Array[String] = []
	signal_lines.append("[Signals]")

	var named_signals: Array[String] = []
	for signal_info in node.get_signal_list():
		var signal_name := String(signal_info.get("name", ""))
		if signal_name == "":
			continue
		var arg_count := 0
		var args_value = signal_info.get("args", [])
		if args_value is Array:
			arg_count = args_value.size()
		named_signals.append("%s(%d)" % [signal_name, arg_count])

	named_signals.sort()
	if named_signals.is_empty():
		signal_lines.append("<none>")
		return signal_lines

	var shown := min(named_signals.size(), 10)
	for index in range(shown):
		signal_lines.append(named_signals[index])
	if named_signals.size() > shown:
		signal_lines.append("... %d more" % [named_signals.size() - shown])

	return signal_lines


func _callable_target_label(callable_value) -> String:
	if not (callable_value is Callable):
		return "<unknown>"

	var callable_ref: Callable = callable_value
	var target = callable_ref.get_object()
	var target_label := "<null>"
	if target is Node:
		target_label = _absolute_node_path(target)
	elif target is Object and target != null:
		target_label = target.get_class()
	return "%s.%s" % [target_label, String(callable_ref.get_method())]


func _connection_detail_lines(node: Object) -> Array[String]:
	var lines: Array[String] = []
	lines.append("[Connections]")

	var incoming_labels: Array[String] = []
	if node.has_method("get_incoming_connections"):
		var incoming = node.call("get_incoming_connections")
		if incoming is Array:
			for connection in incoming:
				if connection is Dictionary:
					incoming_labels.append(_callable_target_label(connection.get("callable", Callable())))

	lines.append("Incoming: %d" % incoming_labels.size())
	if incoming_labels.is_empty():
		lines.append("<none>")
	else:
		var incoming_shown := min(incoming_labels.size(), 6)
		for index in range(incoming_shown):
			lines.append(incoming_labels[index])
		if incoming_labels.size() > incoming_shown:
			lines.append("... %d more" % [incoming_labels.size() - incoming_shown])

	var outgoing_labels: Array[String] = []
	if node.has_method("get_signal_connection_list"):
		for signal_info in node.get_signal_list():
			var signal_name := String(signal_info.get("name", ""))
			if signal_name == "":
				continue
			var connection_list = node.call("get_signal_connection_list", StringName(signal_name))
			if connection_list is Array and not connection_list.is_empty():
				outgoing_labels.append("%s -> %d target(s)" % [signal_name, connection_list.size()])

	lines.append("Outgoing: %d" % outgoing_labels.size())
	if outgoing_labels.is_empty():
		lines.append("<none>")
	else:
		var outgoing_shown := min(outgoing_labels.size(), 8)
		for index in range(outgoing_shown):
			lines.append(outgoing_labels[index])
		if outgoing_labels.size() > outgoing_shown:
			lines.append("... %d more" % [outgoing_labels.size() - outgoing_shown])

	return lines


func _signal_summary(node: Object) -> String:
	var signal_names: Array[String] = []
	for signal_info in node.get_signal_list():
		signal_names.append(String(signal_info.get("name", "")))
	signal_names.sort()
	if signal_names.size() > 8:
		signal_names.resize(8)
		signal_names.append("...")
	return "%d total | %s" % [node.get_signal_list().size(), ", ".join(signal_names)]


func _connection_summary(node: Object) -> String:
	var incoming_count := 0
	if node.has_method("get_incoming_connections"):
		var incoming = node.call("get_incoming_connections")
		if incoming is Array:
			incoming_count = incoming.size()

	var outgoing_count := 0
	if node.has_method("get_signal_connection_list"):
		for signal_info in node.get_signal_list():
			var signal_name := StringName(signal_info.get("name", ""))
			var connection_list = node.call("get_signal_connection_list", signal_name)
			if connection_list is Array:
				outgoing_count += connection_list.size()

	return "incoming=%d outgoing=%d" % [incoming_count, outgoing_count]


func _resource_ref_label(value) -> String:
	if value == null:
		return "<none>"
	if value is Resource:
		return "%s | %s" % [value.get_class(), _value_or_placeholder(String(value.resource_path))]
	if value is Script:
		return "%s | %s" % [value.get_class(), _value_or_placeholder(String(value.resource_path))]
	return _format_variant(value)


func _resource_detail_lines(value) -> Array[String]:
	var lines: Array[String] = []
	if value == null:
		lines.append("<none>")
		return lines

	if value is Resource:
		lines.append("Class: %s" % value.get_class())
		lines.append("Path: %s" % _value_or_placeholder(String(value.resource_path)))
		if value is Texture2D:
			lines.append("Size: %s" % _format_variant(value.get_size()))
		var script = value.get_script()
		if script != null:
			lines.append("Script: %s" % _resource_ref_label(script))
		return lines

	if value is Node:
		lines.append("Class: %s" % value.get_class())
		lines.append("Path: %s" % _absolute_node_path(value))
		lines.append("Children: %d" % value.get_child_count())
		lines.append("Owner: %s" % _owner_label(value))
		return lines

	if value is Object:
		lines.append("Class: %s" % value.get_class())
		var script = value.get_script()
		if script != null:
			lines.append("Script: %s" % _resource_ref_label(script))
		return lines

	lines.append(_format_variant_edit(value))
	return lines


func _resolve_target_property_name() -> String:
	var name := _property_name_edit.text.strip_edges()
	if name != "":
		return name
	return _inspector_selected_property


func _pull_selected_property_to_editor() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return

	var property_name := _resolve_target_property_name()
	if property_name == "":
		_set_status("Property name is empty.")
		return
	if not _has_property(node, property_name):
		_set_status("Property not found on selected node.")
		return

	_sync_inspector_property_selection(node, property_name, typeof(node.get(property_name)), true)
	_set_status("Pulled property %s." % property_name)


func _apply_property_to_selected() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return
	if _is_node_edit_locked(node, "edit"):
		return

	var property_name := _resolve_target_property_name()
	if property_name == "":
		_set_status("Property name is empty.")
		return
	if not _has_property(node, property_name):
		_set_status("Property not found on selected node.")
		return

	var parsed := _parse_input_value(_property_type_option.get_selected_id(), _property_value_edit.text)
	if not bool(parsed.get("ok", false)):
		_set_status(String(parsed.get("error", "Failed to parse property value.")))
		return

	var old_value = node.get(property_name)
	node.set(property_name, parsed.get("value"))
	_record_property_transaction(node, property_name, old_value, node.get(property_name))
	_sync_inspector_property_selection(node, property_name, typeof(node.get(property_name)), true)
	_refresh_inspector()
	_refresh_world_controls()
	_log_event("Set %s.%s = %s." % [_absolute_node_path(node), property_name, _property_value_edit.text])
	_set_status("Applied property %s." % property_name)


func _call_selected_method() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return

	var method_name := _method_name_edit.text.strip_edges()
	if method_name == "":
		_set_status("Method name is empty.")
		return
	if not node.has_method(method_name):
		_set_status("Selected node has no method %s." % method_name)
		return

	var args: Array = []
	if _method_use_arg_check.button_pressed:
		var parsed := _parse_input_value(_method_arg_type_option.get_selected_id(), _method_arg_edit.text)
		if not bool(parsed.get("ok", false)):
			_set_status(String(parsed.get("error", "Failed to parse method argument.")))
			return
		args.append(parsed.get("value"))

	var result = node.callv(method_name, args)
	_property_value_edit.text = _format_variant_edit(result)
	_log_event("Called %s.%s(%s)." % [_absolute_node_path(node), method_name, ", ".join(_stringify_array(args))])
	_set_status("Called method %s." % method_name)
	_refresh_inspector()
	_refresh_world_controls()


func _refresh_world_controls() -> void:
	var node := _get_selected_node()
	_world_selected_path_edit.text = _selected_node_path

	if node == null:
		_world_mode_label.text = "Mode: no node selected."
		_world_name_edit.text = ""
		_world_visible_check.button_pressed = false
		_world_jump_path_edit.text = ""
		_world_reparent_path_edit.text = ""
		return

	_world_name_edit.text = node.name
	_world_visible_check.button_pressed = bool(_read_property(node, "visible", true))
	_world_jump_path_edit.text = _absolute_node_path(node)
	_world_reparent_path_edit.text = _absolute_node_path(node.get_parent()) if node.get_parent() != null else ""
	_pull_transform_from_node(node)


func _pull_transform_from_node(node: Node) -> void:
	if node is Node3D:
		var node3d := node as Node3D
		_world_mode_label.text = "Mode: Node3D (global position, rotation degrees, scale)"
		_world_pos_x.value = node3d.global_position.x
		_world_pos_y.value = node3d.global_position.y
		_world_pos_z.value = node3d.global_position.z
		_world_rot_x.value = node3d.rotation_degrees.x
		_world_rot_y.value = node3d.rotation_degrees.y
		_world_rot_z.value = node3d.rotation_degrees.z
		_world_scale_x.value = node3d.scale.x
		_world_scale_y.value = node3d.scale.y
		_world_scale_z.value = node3d.scale.z
		return

	if node is Node2D:
		var node2d := node as Node2D
		_world_mode_label.text = "Mode: Node2D (global position XY, rotation Z, scale XY)"
		_world_pos_x.value = node2d.global_position.x
		_world_pos_y.value = node2d.global_position.y
		_world_pos_z.value = 0.0
		_world_rot_x.value = 0.0
		_world_rot_y.value = 0.0
		_world_rot_z.value = node2d.rotation_degrees
		_world_scale_x.value = node2d.scale.x
		_world_scale_y.value = node2d.scale.y
		_world_scale_z.value = 1.0
		return

	if node is Control:
		var control := node as Control
		_world_mode_label.text = "Mode: Control (position XY, rotation Z, scale XY)"
		_world_pos_x.value = control.position.x
		_world_pos_y.value = control.position.y
		_world_pos_z.value = 0.0
		_world_rot_x.value = 0.0
		_world_rot_y.value = 0.0
		_world_rot_z.value = control.rotation_degrees
		_world_scale_x.value = control.scale.x
		_world_scale_y.value = control.scale.y
		_world_scale_z.value = 1.0
		return

	_world_mode_label.text = "Mode: non-transform node selected."


func _apply_selected_name() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node to rename.")
		return
	if _is_node_edit_locked(node, "rename"):
		return

	var new_name := _world_name_edit.text.strip_edges()
	if new_name == "":
		_set_status("Name cannot be empty.")
		return

	var old_name := node.name
	var old_path := _absolute_node_path(node)
	node.name = new_name
	_selected_node_path = _absolute_node_path(node)
	_record_name_transaction(node, old_name, new_name, old_path, _selected_node_path)
	_refresh_all_views(false)
	_log_event("Renamed node to %s." % new_name)
	_set_status("Renamed node to %s." % new_name)


func _apply_selected_visibility() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return
	if _is_node_edit_locked(node, "change visibility"):
		return
	if not _has_property(node, "visible"):
		_set_status("Selected node has no visible property.")
		return

	var old_value := bool(node.get("visible"))
	node.set("visible", _world_visible_check.button_pressed)
	_record_visibility_transaction(node, old_value, bool(node.get("visible")))
	_log_event("Set visibility on %s to %s." % [_absolute_node_path(node), _bool_string(_world_visible_check.button_pressed)])
	_set_status("Applied visibility.")


func _pull_transform_from_selected() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return

	_pull_transform_from_node(node)
	_set_status("Pulled transform from selected node.")


func _apply_transform_to_selected() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return
	if _is_node_edit_locked(node, "transform"):
		return

	var old_state := _capture_transform_state(node)

	if node is Node3D:
		var node3d := node as Node3D
		node3d.global_position = Vector3(_world_pos_x.value, _world_pos_y.value, _world_pos_z.value)
		node3d.rotation_degrees = Vector3(_world_rot_x.value, _world_rot_y.value, _world_rot_z.value)
		node3d.scale = Vector3(_world_scale_x.value, _world_scale_y.value, _world_scale_z.value)
	elif node is Node2D:
		var node2d := node as Node2D
		node2d.global_position = Vector2(_world_pos_x.value, _world_pos_y.value)
		node2d.rotation_degrees = _world_rot_z.value
		node2d.scale = Vector2(_world_scale_x.value, _world_scale_y.value)
	elif node is Control:
		var control := node as Control
		control.position = Vector2(_world_pos_x.value, _world_pos_y.value)
		control.rotation_degrees = _world_rot_z.value
		control.scale = Vector2(_world_scale_x.value, _world_scale_y.value)
	else:
		_set_status("Selected node is not transformable.")
		return

	_record_transform_transaction(node, old_state, _capture_transform_state(node))
	_refresh_inspector()
	_log_event("Applied transform to %s." % _absolute_node_path(node))
	_set_status("Applied transform.")


func _nudge_selected(axis: String, direction: float) -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return
	if _is_node_edit_locked(node, "nudge"):
		return

	var delta := _world_step_spin.value * direction
	var old_state := _capture_transform_state(node)

	if node is Node3D:
		var node3d := node as Node3D
		var p := node3d.global_position
		match axis:
			"x": p.x += delta
			"y": p.y += delta
			"z": p.z += delta
		node3d.global_position = p
	elif node is Node2D:
		var node2d := node as Node2D
		var p2 := node2d.global_position
		match axis:
			"x": p2.x += delta
			"y": p2.y += delta
			_: pass
		node2d.global_position = p2
	elif node is Control:
		var control := node as Control
		var p3 := control.position
		match axis:
			"x": p3.x += delta
			"y": p3.y += delta
			_: pass
		control.position = p3
	else:
		_set_status("Selected node cannot be nudged.")
		return

	_record_transform_transaction(node, old_state, _capture_transform_state(node))
	_pull_transform_from_node(node)
	_refresh_inspector()
	_log_event("Nudged %s %s by %s." % [_absolute_node_path(node), axis, str(delta)])
	_set_status("Nudged selected node.")


func _duplicate_selected() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return
	if _is_node_edit_locked(node, "duplicate"):
		return
	if node.get_parent() == null:
		_set_status("Selected node has no parent.")
		return

	var clone = node.duplicate()
	node.get_parent().add_child(clone)

	if clone is Node3D:
		(clone as Node3D).global_position += Vector3(_world_step_spin.value, 0.0, 0.0)
	elif clone is Node2D:
		(clone as Node2D).global_position += Vector2(_world_step_spin.value, 0.0)
	elif clone is Control:
		(clone as Control).position += Vector2(_world_step_spin.value, 0.0)

	_set_selected_node(clone)
	_rebuild_hierarchy_tree()
	_refresh_all_views(false)
	_record_create_node_transaction(clone, "Duplicate node")
	_log_event("Duplicated node %s." % _absolute_node_path(node))
	_set_status("Duplicated selected node.")


func _delete_selected() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return
	if _is_node_edit_locked(node, "delete"):
		return
	if not _confirm_destructive_action("delete", node):
		return

	_maybe_snapshot_before_danger("delete")
	var transaction := _make_delete_node_transaction(node, "Delete node")
	if transaction.is_empty():
		_set_status("Failed to snapshot node for deletion undo.")
		return

	var path := _absolute_node_path(node)
	_destroy_node_immediate(node)
	_selected_node_path = ""
	_capture_inspector_baseline(null)
	_record_transaction(transaction)
	_refresh_all_views(false)
	_log_event("Deleted %s." % path)
	_set_status("Deleted selected node.")


func _reparent_selected() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return
	if _is_node_edit_locked(node, "reparent"):
		return

	var target_path := _world_reparent_path_edit.text.strip_edges()
	if target_path == "":
		_set_status("Reparent target path is empty.")
		return

	var new_parent := get_node_or_null(target_path)
	if new_parent == null:
		_set_status("Target parent not found.")
		return
	if new_parent == node:
		_set_status("Cannot reparent node under itself.")
		return
	if _node_is_descendant(node, new_parent):
		_set_status("Cannot reparent node under its own descendant.")
		return
	if not _confirm_destructive_action("reparent:%s" % target_path, node, "Target: %s" % _value_or_placeholder(target_path)):
		return

	_maybe_snapshot_before_danger("reparent")
	var old_parent := node.get_parent()
	var old_index := node.get_index()
	var old_path := _absolute_node_path(node)
	node.reparent(new_parent, true)
	var new_path := _absolute_node_path(node)
	_record_reparent_transaction(node, old_parent, old_index, new_parent, node.get_index(), old_path, new_path)
	_set_selected_node(node)
	_rebuild_hierarchy_tree()
	_refresh_all_views(false)
	_log_event("Reparented %s under %s." % [_absolute_node_path(node), _absolute_node_path(new_parent)])
	_set_status("Reparented selected node.")


func _create_helper_node(kind: String, under_selected: bool) -> void:
	var parent: Node = get_tree().current_scene
	if under_selected and _get_selected_node() != null:
		parent = _get_selected_node()
	if parent == null:
		_set_status("No valid parent for helper node.")
		return
	if _is_parent_add_locked(parent, "create helper under"):
		return

	var node: Node = null
	match kind:
		"Node3D":
			node = Node3D.new()
		"Marker3D":
			node = Marker3D.new()
		"Node2D":
			node = Node2D.new()
		"Control":
			node = Control.new()
		"Label":
			var label := Label.new()
			label.text = "RTV Tool Kit Label"
			node = label
		_:
			_set_status("Unknown helper node type.")
			return

	node.name = "TK%s" % kind
	parent.add_child(node)

	var selected := _get_selected_node()
	if selected != null:
		if node is Node3D and selected is Node3D:
			(node as Node3D).global_position = (selected as Node3D).global_position
		elif node is Node2D and selected is Node2D:
			(node as Node2D).global_position = (selected as Node2D).global_position
		elif node is Control and selected is Control:
			(node as Control).position = (selected as Control).position

	_set_selected_node(node)
	_rebuild_hierarchy_tree()
	_refresh_all_views(false)
	_record_create_node_transaction(node, "Create helper %s" % kind)
	_log_event("Created helper node %s under %s." % [kind, _absolute_node_path(parent)])
	_set_status("Created %s helper node." % kind)


func _spawn_scene(target_selected: bool) -> void:
	var res_path := _spawn_path_edit.text.strip_edges()
	if res_path == "":
		_set_status("Spawn path is empty.")
		return

	var res = load(res_path)
	if not (res is PackedScene):
		_set_status("Resource is not a PackedScene.")
		return

	var parent: Node = get_tree().current_scene
	if target_selected and _get_selected_node() != null:
		parent = _get_selected_node()

	if parent == null:
		_set_status("No valid parent for spawn.")
		return
	if _is_parent_add_locked(parent, "spawn under"):
		return

	var instance = (res as PackedScene).instantiate()
	parent.add_child(instance)

	var selected := _get_selected_node()
	if selected != null:
		if instance is Node3D and selected is Node3D:
			(instance as Node3D).global_position = (selected as Node3D).global_position
		elif instance is Node2D and selected is Node2D:
			(instance as Node2D).global_position = (selected as Node2D).global_position
		elif instance is Control and selected is Control:
			(instance as Control).position = (selected as Control).position

	_set_selected_node(instance)
	_rebuild_hierarchy_tree()
	_refresh_all_views(false)
	_record_create_node_transaction(instance, "Spawn scene %s" % res_path.get_file())
	_log_event("Spawned scene %s under %s." % [res_path, _absolute_node_path(parent)])
	_set_status("Spawned scene %s." % res_path.get_file())


func _refresh_file_list() -> void:
	if _file_list == null:
		return

	var previous := _selected_user_file
	var filter := ""
	if _file_filter_edit != null:
		filter = _file_filter_edit.text.strip_edges().to_lower()
	_file_entries.clear()
	_collect_user_files("user://", "", _file_entries)
	_file_entries.sort_custom(func(a, b): return String(a["relative_path"]).to_lower() < String(b["relative_path"]).to_lower())

	_file_list.clear()
	for entry in _file_entries:
		if filter != "" and not String(entry["relative_path"]).to_lower().contains(filter):
			continue
		var index := _file_list.get_item_count()
		_file_list.add_item(entry["relative_path"])
		_file_list.set_item_metadata(index, entry["user_path"])

	if previous != "":
		for i in range(_file_list.get_item_count()):
			if String(_file_list.get_item_metadata(i)) == previous:
				_file_list.select(i)
				break

	_refresh_file_preview()


func _collect_user_files(dir_path: String, relative_path: String, out: Array[Dictionary]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var child_relative := entry if relative_path == "" else relative_path.path_join(entry)
			var child_user_path := "user://" + child_relative
			if dir.current_is_dir():
				_collect_user_files(child_user_path, child_relative, out)
			else:
				out.append({
					"user_path": child_user_path,
					"relative_path": child_relative,
					"global_path": ProjectSettings.globalize_path(child_user_path),
					"size": _file_size(child_user_path),
					"mtime": FileAccess.get_modified_time(child_user_path),
				})
		entry = dir.get_next()
	dir.list_dir_end()


func _refresh_file_preview() -> void:
	if _file_preview == null or _file_meta_label == null:
		return

	if _selected_user_file == "":
		_file_meta_label.text = "No file selected."
		_file_preview.text = ""
		return

	var entry := _find_file_entry(_selected_user_file)
	if entry.is_empty():
		_file_meta_label.text = "Selected file missing."
		_file_preview.text = ""
		return

	_file_meta_label.text = "%s\n%s\n%s | %s" % [
		entry["relative_path"],
		entry["global_path"],
		_format_bytes(int(entry["size"])),
		_format_unix_time(int(entry["mtime"])),
	]

	var file := FileAccess.open(_selected_user_file, FileAccess.READ)
	if file == null:
		_file_preview.text = "<failed to open file>"
		return

	var bytes := file.get_buffer(min(file.get_length(), 16384))
	file.seek(0)

	if not _bytes_look_textual(bytes):
		_file_preview.text = "<binary preview omitted>"
		return

	var text := file.get_as_text()
	if text.length() > 16384:
		text = text.substr(0, 16384) + "\n\n... [truncated]"

	_file_preview.text = text


func _find_file_entry(user_path: String) -> Dictionary:
	for entry in _file_entries:
		if entry["user_path"] == user_path:
			return entry
	return {}


func _snapshot_user_files() -> String:
	_refresh_file_list()

	var slug := _timestamp_slug()
	var snapshot_root := SNAPSHOT_ROOT.path_join(slug)
	var copied := 0

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(snapshot_root))

	for entry in _file_entries:
		var relative_path := String(entry.get("relative_path", ""))
		if relative_path == "" or relative_path.begins_with("rtv_tool_kit_snapshots/"):
			continue

		var source_path := String(entry.get("user_path", ""))
		var target_path := snapshot_root.path_join(relative_path)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_path.get_base_dir()))

		var source_file := FileAccess.open(source_path, FileAccess.READ)
		if source_file == null:
			continue
		var bytes := source_file.get_buffer(source_file.get_length())

		var target_file := FileAccess.open(target_path, FileAccess.WRITE)
		if target_file == null:
			continue
		target_file.store_buffer(bytes)
		copied += 1

	_log_event("Created user:// snapshot %s (%d file(s))." % [snapshot_root, copied])
	return snapshot_root


func _refresh_runtime_controls() -> void:
	if _time_scale_spin == null:
		return

	_time_scale_spin.value = Engine.time_scale
	_tree_paused_check.button_pressed = get_tree().paused

	var simulation := get_node_or_null("/root/Simulation")
	if simulation != null:
		_simulation_day_spin.value = float(_read_property(simulation, "day", 0))
		_simulation_time_spin.value = float(_read_property(simulation, "time", 0.0))
		_simulation_season_spin.value = float(_read_property(simulation, "season", 0))
		_simulation_weather_spin.value = float(_read_property(simulation, "weather", 0))
		_simulation_weather_time_spin.value = float(_read_property(simulation, "weatherTime", 0.0))
		_simulation_simulate_check.button_pressed = bool(_read_property(simulation, "simulate", false))
	else:
		_simulation_day_spin.value = 0.0
		_simulation_time_spin.value = 0.0
		_simulation_season_spin.value = 0.0
		_simulation_weather_spin.value = 0.0
		_simulation_weather_time_spin.value = 0.0
		_simulation_simulate_check.button_pressed = false

	if game_data != null:
		_game_menu_check.button_pressed = bool(_read_property(game_data, "menu", false))
		_game_shelter_check.button_pressed = bool(_read_property(game_data, "shelter", false))
		_game_permadeath_check.button_pressed = bool(_read_property(game_data, "permadeath", false))
		_game_tutorial_check.button_pressed = bool(_read_property(game_data, "tutorial", false))
		_game_freeze_check.button_pressed = bool(_read_property(game_data, "freeze", false))
		_game_compatibility_check.button_pressed = bool(_read_property(game_data, "compatibility", false))


func _apply_runtime_controls() -> void:
	Engine.time_scale = _time_scale_spin.value
	get_tree().paused = _tree_paused_check.button_pressed

	var simulation := get_node_or_null("/root/Simulation")
	if simulation != null:
		if _has_property(simulation, "day"):
			simulation.set("day", int(_simulation_day_spin.value))
		if _has_property(simulation, "time"):
			simulation.set("time", _simulation_time_spin.value)
		if _has_property(simulation, "season"):
			simulation.set("season", int(_simulation_season_spin.value))
		if _has_property(simulation, "weather"):
			simulation.set("weather", int(_simulation_weather_spin.value))
		if _has_property(simulation, "weatherTime"):
			simulation.set("weatherTime", _simulation_weather_time_spin.value)
		if _has_property(simulation, "simulate"):
			simulation.set("simulate", _simulation_simulate_check.button_pressed)

	if game_data != null:
		_apply_object_property_if_present(game_data, "menu", _game_menu_check.button_pressed)
		_apply_object_property_if_present(game_data, "shelter", _game_shelter_check.button_pressed)
		_apply_object_property_if_present(game_data, "permadeath", _game_permadeath_check.button_pressed)
		_apply_object_property_if_present(game_data, "tutorial", _game_tutorial_check.button_pressed)
		_apply_object_property_if_present(game_data, "freeze", _game_freeze_check.button_pressed)
		_apply_object_property_if_present(game_data, "compatibility", _game_compatibility_check.button_pressed)

	_refresh_overview_report()
	_log_event("Applied runtime state.")
	_set_status("Applied runtime state.")


func _refresh_groups_view() -> void:
	if _group_list == null or _group_members == null:
		return

	var names: Array[String] = []
	var seen := {}
	var filter := _group_filter_edit.text.strip_edges().to_lower() if _group_filter_edit != null else ""

	for node in _collect_all_nodes():
		for group_name in node.get_groups():
			var name := String(group_name)
			if seen.has(name):
				continue
			seen[name] = true
			if filter == "" or name.to_lower().contains(filter):
				names.append(name)

	names.sort()
	_group_list.clear()
	for name in names:
		var index := _group_list.get_item_count()
		_group_list.add_item(name)
		_group_list.set_item_metadata(index, name)

	var found_selection := false
	if _group_list.get_item_count() == 0:
		_selected_group_name = ""
	if _selected_group_name != "":
		for i in range(_group_list.get_item_count()):
			if String(_group_list.get_item_metadata(i)) == _selected_group_name:
				_group_list.select(i)
				found_selection = true
				break
	if not found_selection and _group_list.get_item_count() > 0:
		_selected_group_name = String(_group_list.get_item_metadata(0))
		_group_list.select(0)

	_refresh_group_members()


func _refresh_group_members() -> void:
	if _group_members == null:
		return

	_group_members.clear()
	if _selected_group_name == "":
		if _group_status_label != null:
			_group_status_label.text = "No group selected."
		return

	var nodes: Array[Node] = []
	for node in get_tree().get_nodes_in_group(_selected_group_name):
		if node is Node:
			nodes.append(node)
	nodes.sort_custom(func(a, b): return _absolute_node_path(a).to_lower() < _absolute_node_path(b).to_lower())

	for node in nodes:
		var index := _group_members.get_item_count()
		var path := _absolute_node_path(node)
		_group_members.add_item("%s [%s] %s" % [node.name, node.get_class(), path])
		_group_members.set_item_metadata(index, path)

	if _group_status_label != null:
		_group_status_label.text = "Groups: %d | Selected: %s | Members: %d" % [_group_list.get_item_count(), _value_or_placeholder(_selected_group_name), nodes.size()]


func _refresh_watch_view() -> void:
	if _bookmark_list == null or _watch_list == null or _history_list == null:
		return

	_bookmark_list.clear()
	for path in _bookmarked_paths:
		var node := get_node_or_null(path)
		var label := ("%s  %s" % [_node_display_name(node), path]) if node != null else ("[missing] %s" % path)
		var index := _bookmark_list.get_item_count()
		_bookmark_list.add_item(label)
		_bookmark_list.set_item_metadata(index, path)

	_watch_list.clear()
	for path in _watch_paths:
		var index := _watch_list.get_item_count()
		_watch_list.add_item(_watch_summary(path))
		_watch_list.set_item_metadata(index, path)

	_history_list.clear()
	for path in _selection_history:
		var node := get_node_or_null(path)
		var label := ("%s  %s" % [_node_display_name(node), path]) if node != null else ("[missing] %s" % path)
		var index := _history_list.get_item_count()
		_history_list.add_item(label)
		_history_list.set_item_metadata(index, path)


func _refresh_transaction_views() -> void:
	_refresh_safety_controls()
	if _transaction_list == null:
		return

	var selected_id := -1
	var selected := _transaction_list.get_selected_items()
	if selected.size() > 0:
		selected_id = int(_transaction_list.get_item_metadata(selected[0]))

	_transaction_list.clear()
	for transaction in _transaction_history:
		var label := "%s  [%s] %s" % [
			String(transaction.get("time", "--:--:--")),
			String(transaction.get("state", "Applied")),
			String(transaction.get("label", String(transaction.get("kind", "tx")))),
		]
		var index := _transaction_list.get_item_count()
		_transaction_list.add_item(label)
		_transaction_list.set_item_metadata(index, int(transaction.get("id", -1)))

	var restore_index := -1
	if selected_id != -1:
		for index in range(_transaction_list.get_item_count()):
			if int(_transaction_list.get_item_metadata(index)) == selected_id:
				restore_index = index
				break
	if restore_index == -1 and _transaction_list.get_item_count() > 0:
		restore_index = 0

	if restore_index != -1:
		_transaction_list.select(restore_index)
		_refresh_selected_transaction_detail()
	elif _transaction_detail != null:
		_transaction_detail.clear()
		_transaction_detail.append_text("No transactions recorded.")


func _refresh_selected_transaction_detail() -> void:
	if _transaction_detail == null:
		return

	_transaction_detail.clear()
	if _transaction_list == null:
		_transaction_detail.append_text("No transaction UI available.")
		return

	var selected := _transaction_list.get_selected_items()
	if selected.size() == 0:
		_transaction_detail.append_text("No transaction selected.")
		return

	var transaction := _find_transaction_by_id(int(_transaction_list.get_item_metadata(selected[0])))
	if transaction.is_empty():
		_transaction_detail.append_text("Transaction not found.")
		return

	var lines: Array[String] = []
	lines.append("Label: %s" % String(transaction.get("label", transaction.get("kind", "transaction"))))
	lines.append("State: %s" % String(transaction.get("state", "Applied")))
	lines.append("Kind: %s" % String(transaction.get("kind", "<unknown>")))
	lines.append("Time: %s" % String(transaction.get("time", "--:--:--")))

	var node_path := _transaction_node_label(transaction)
	if node_path != "":
		lines.append("Node: %s" % node_path)

	match String(transaction.get("kind", "")):
		"property":
			lines.append("Property: %s" % String(transaction.get("property_name", "")))
			lines.append("Before: %s" % _format_variant_edit(transaction.get("old_value")))
			lines.append("After: %s" % _format_variant_edit(transaction.get("new_value")))
		"name":
			lines.append("Before: %s" % String(transaction.get("old_name", "")))
			lines.append("After: %s" % String(transaction.get("new_name", "")))
		"visibility":
			lines.append("Before: %s" % _bool_string(bool(transaction.get("old_value", false))))
			lines.append("After: %s" % _bool_string(bool(transaction.get("new_value", false))))
		"transform":
			lines.append("Before: %s" % _transaction_transform_summary(transaction.get("old_state", {})))
			lines.append("After: %s" % _transaction_transform_summary(transaction.get("new_state", {})))
		"reparent":
			lines.append("Before Parent: %s" % String(transaction.get("old_parent_path", "")))
			lines.append("After Parent: %s" % String(transaction.get("new_parent_path", "")))
		"group":
			lines.append("Group: %s" % String(transaction.get("group_name", "")))
			lines.append("Action: %s" % ("Add" if bool(transaction.get("added", false)) else "Remove"))
		"node_create", "node_delete":
			lines.append("Parent: %s" % String(transaction.get("parent_path", "")))
			lines.append("Child Index: %d" % int(transaction.get("child_index", -1)))

	_transaction_detail.append_text("\n".join(lines))


func _refresh_safety_controls() -> void:
	if _undo_button != null:
		_undo_button.disabled = _undo_stack.is_empty()
	if _redo_button != null:
		_redo_button.disabled = _redo_stack.is_empty()


func _find_transaction_by_id(transaction_id: int) -> Dictionary:
	for transaction in _transaction_history:
		if int(transaction.get("id", -1)) == transaction_id:
			return transaction
	return {}


func _transaction_node_label(transaction: Dictionary) -> String:
	var node := _resolve_transaction_node(transaction)
	if node != null:
		return _absolute_node_path(node)
	for key in ["node_path", "node_current_path", "node_old_path", "node_new_path"]:
		var value := String(transaction.get(key, ""))
		if value != "":
			return value
	return ""


func _transaction_transform_summary(state) -> String:
	if not (state is Dictionary):
		return "<none>"
	var transform_state: Dictionary = state
	return "pos=%s rot=%s scale=%s" % [
		_format_variant(transform_state.get("position")),
		_format_variant(transform_state.get("rotation")),
		_format_variant(transform_state.get("scale")),
	]


func _record_transaction(transaction: Dictionary) -> void:
	transaction["id"] = _transaction_serial
	transaction["time"] = Time.get_time_string_from_system()
	transaction["state"] = "Applied"
	_transaction_serial += 1

	_undo_stack.append(transaction)
	while _undo_stack.size() > MAX_TRANSACTIONS:
		_undo_stack.remove_at(0)
	_redo_stack.clear()
	_transaction_history.insert(0, transaction)
	while _transaction_history.size() > MAX_TRANSACTIONS:
		_transaction_history.remove_at(_transaction_history.size() - 1)
	_pending_confirmation.clear()
	_refresh_transaction_views()


func _resolve_instance(instance_id: int) -> Object:
	if instance_id == 0:
		return null
	var candidate = instance_from_id(instance_id)
	return candidate if candidate is Object else null


func _resolve_transaction_node(transaction: Dictionary) -> Node:
	var resolved = _resolve_instance(int(transaction.get("node_id", 0)))
	if resolved is Node:
		return resolved

	for key in ["node_current_path", "node_path", "node_new_path", "node_old_path"]:
		var path := String(transaction.get(key, ""))
		if path == "":
			continue
		var node := get_node_or_null(path)
		if node != null:
			return node
	return null


func _resolve_transaction_parent(transaction: Dictionary, prefix: String) -> Node:
	var resolved = _resolve_instance(int(transaction.get("%s_id" % prefix, 0)))
	if resolved is Node:
		return resolved
	var path := String(transaction.get("%s_path" % prefix, ""))
	if path == "":
		return null
	return get_node_or_null(path)


func _is_important_node(node: Node) -> bool:
	if node == null:
		return false
	if _is_protected_node(node):
		return true
	if node.get_parent() == get_tree().current_scene:
		return true
	return node.name in ["Map", "Core", "UI", "Interface", "Menu", "Shelter"]


func _is_node_edit_locked(node: Node, action_label: String) -> bool:
	if node == null:
		_set_status("No selected node.")
		return true
	if _is_protected_node(node):
		_set_status("Refusing to %s protected node." % action_label)
		return true
	if _lock_important_check != null and _lock_important_check.button_pressed and _is_important_node(node):
		_set_status("Lock Important is enabled. Unlock it to %s this node." % action_label)
		return true
	return false


func _is_parent_add_locked(parent: Node, action_label: String) -> bool:
	if parent == null:
		_set_status("No valid parent node.")
		return true
	if parent == self or parent == get_tree().root:
		_set_status("Refusing to %s protected parent." % action_label)
		return true
	if parent != get_tree().current_scene and _is_node_edit_locked(parent, action_label):
		return true
	return false


func _confirm_destructive_action(action_key: String, node: Node, detail: String = "") -> bool:
	if node == null:
		return false
	var now := Time.get_ticks_msec()
	var path := _absolute_node_path(node)
	if String(_pending_confirmation.get("key", "")) == action_key and String(_pending_confirmation.get("path", "")) == path and now - int(_pending_confirmation.get("time", 0)) <= DANGER_CONFIRM_WINDOW_MS:
		_pending_confirmation.clear()
		return true

	_pending_confirmation = {
		"key": action_key,
		"path": path,
		"time": now,
	}
	_set_status("Confirm %s on %s within 4s.%s" % [action_key, node.name, (" " + detail) if detail != "" else ""])
	return false


func _maybe_snapshot_before_danger(action_label: String) -> void:
	if _auto_snapshot_danger_check == null or not _auto_snapshot_danger_check.button_pressed:
		return
	var snapshot_root := _snapshot_user_files()
	_log_event("Auto snapshot before %s at %s." % [action_label, snapshot_root])


func _capture_transform_state(node: Node) -> Dictionary:
	if node is Node3D:
		var node3d := node as Node3D
		return {
			"mode": "Node3D",
			"position": node3d.global_position,
			"rotation": node3d.rotation_degrees,
			"scale": node3d.scale,
		}
	if node is Node2D:
		var node2d := node as Node2D
		return {
			"mode": "Node2D",
			"position": node2d.global_position,
			"rotation": node2d.rotation_degrees,
			"scale": node2d.scale,
		}
	if node is Control:
		var control := node as Control
		return {
			"mode": "Control",
			"position": control.position,
			"rotation": control.rotation_degrees,
			"scale": control.scale,
		}
	return {}


func _apply_transform_state(node: Node, state: Dictionary) -> bool:
	match String(state.get("mode", "")):
		"Node3D":
			if not (node is Node3D):
				return false
			var node3d := node as Node3D
			node3d.global_position = state.get("position", node3d.global_position)
			node3d.rotation_degrees = state.get("rotation", node3d.rotation_degrees)
			node3d.scale = state.get("scale", node3d.scale)
			return true
		"Node2D":
			if not (node is Node2D):
				return false
			var node2d := node as Node2D
			node2d.global_position = state.get("position", node2d.global_position)
			node2d.rotation_degrees = float(state.get("rotation", node2d.rotation_degrees))
			node2d.scale = state.get("scale", node2d.scale)
			return true
		"Control":
			if not (node is Control):
				return false
			var control := node as Control
			control.position = state.get("position", control.position)
			control.rotation_degrees = float(state.get("rotation", control.rotation_degrees))
			control.scale = state.get("scale", control.scale)
			return true
	return false


func _destroy_node_immediate(node: Node) -> void:
	if node == null:
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()


func _assign_snapshot_owners_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		if child is Node:
			child.owner = owner
			_assign_snapshot_owners_recursive(child, owner)


func _pack_node_snapshot(node: Node) -> PackedScene:
	if node == null:
		return null
	var clone = node.duplicate()
	if not (clone is Node):
		return null
	_assign_snapshot_owners_recursive(clone, clone)
	var packed := PackedScene.new()
	var status := packed.pack(clone)
	clone.free()
	if status != OK:
		return null
	return packed


func _restore_snapshot_under_parent(packed: PackedScene, parent: Node, child_index: int) -> Node:
	if packed == null or parent == null:
		return null
	var restored = packed.instantiate()
	if not (restored is Node):
		return null
	parent.add_child(restored)
	if child_index >= 0 and child_index < parent.get_child_count():
		parent.move_child(restored, child_index)
	return restored


func _record_property_transaction(node: Node, property_name: String, old_value, new_value) -> void:
	if _variant_signature(old_value) == _variant_signature(new_value):
		return
	_record_transaction({
		"kind": "property",
		"label": "Set %s" % property_name,
		"node_id": node.get_instance_id(),
		"node_path": _absolute_node_path(node),
		"property_name": property_name,
		"old_value": _duplicate_variant_for_baseline(old_value),
		"new_value": _duplicate_variant_for_baseline(new_value),
	})


func _record_name_transaction(node: Node, old_name: String, new_name: String, old_path: String, new_path: String) -> void:
	if old_name == new_name:
		return
	_record_transaction({
		"kind": "name",
		"label": "Rename node",
		"node_id": node.get_instance_id(),
		"node_old_path": old_path,
		"node_new_path": new_path,
		"old_name": old_name,
		"new_name": new_name,
	})


func _record_visibility_transaction(node: Node, old_value: bool, new_value: bool) -> void:
	if old_value == new_value:
		return
	_record_transaction({
		"kind": "visibility",
		"label": "Set visibility",
		"node_id": node.get_instance_id(),
		"node_path": _absolute_node_path(node),
		"old_value": old_value,
		"new_value": new_value,
	})


func _record_transform_transaction(node: Node, old_state: Dictionary, new_state: Dictionary) -> void:
	if old_state == new_state:
		return
	_record_transaction({
		"kind": "transform",
		"label": "Transform edit",
		"node_id": node.get_instance_id(),
		"node_path": _absolute_node_path(node),
		"old_state": old_state.duplicate(true),
		"new_state": new_state.duplicate(true),
	})


func _record_reparent_transaction(node: Node, old_parent: Node, old_index: int, new_parent: Node, new_index: int, old_path: String, new_path: String) -> void:
	_record_transaction({
		"kind": "reparent",
		"label": "Reparent node",
		"node_id": node.get_instance_id(),
		"node_old_path": old_path,
		"node_new_path": new_path,
		"old_parent_id": old_parent.get_instance_id() if old_parent != null else 0,
		"old_parent_path": _absolute_node_path(old_parent) if old_parent != null else "",
		"old_index": old_index,
		"new_parent_id": new_parent.get_instance_id() if new_parent != null else 0,
		"new_parent_path": _absolute_node_path(new_parent) if new_parent != null else "",
		"new_index": new_index,
	})


func _record_group_transaction(node: Node, group_name: String, added: bool) -> void:
	_record_transaction({
		"kind": "group",
		"label": "%s group %s" % ["Add" if added else "Remove", group_name],
		"node_id": node.get_instance_id(),
		"node_path": _absolute_node_path(node),
		"group_name": group_name,
		"added": added,
	})


func _record_create_node_transaction(node: Node, label: String) -> void:
	var parent := node.get_parent()
	if parent == null:
		return
	var snapshot := _pack_node_snapshot(node)
	if snapshot == null:
		_log_event("Failed to snapshot created node for undo.")
		return
	_record_transaction({
		"kind": "node_create",
		"label": label,
		"node_id": node.get_instance_id(),
		"node_path": _absolute_node_path(node),
		"parent_id": parent.get_instance_id(),
		"parent_path": _absolute_node_path(parent),
		"child_index": node.get_index(),
		"snapshot": snapshot,
	})


func _make_delete_node_transaction(node: Node, label: String) -> Dictionary:
	var parent := node.get_parent()
	if parent == null:
		return {}
	var snapshot := _pack_node_snapshot(node)
	if snapshot == null:
		return {}
	return {
		"kind": "node_delete",
		"label": label,
		"node_id": node.get_instance_id(),
		"node_path": _absolute_node_path(node),
		"parent_id": parent.get_instance_id(),
		"parent_path": _absolute_node_path(parent),
		"child_index": node.get_index(),
		"snapshot": snapshot,
	}


func _apply_transaction(transaction: Dictionary, undo: bool) -> bool:
	var kind := String(transaction.get("kind", ""))
	match kind:
		"property":
			var prop_node := _resolve_transaction_node(transaction)
			if prop_node == null:
				return false
			prop_node.set(String(transaction.get("property_name", "")), _duplicate_variant_for_baseline(transaction.get("old_value") if undo else transaction.get("new_value")))
			_set_selected_node(prop_node)
			return true
		"name":
			var name_node := _resolve_transaction_node(transaction)
			if name_node == null:
				return false
			name_node.name = String(transaction.get("old_name", "") if undo else transaction.get("new_name", ""))
			_set_selected_node(name_node)
			return true
		"visibility":
			var visible_node := _resolve_transaction_node(transaction)
			if visible_node == null:
				return false
			visible_node.set("visible", bool(transaction.get("old_value", false) if undo else transaction.get("new_value", false)))
			_set_selected_node(visible_node)
			return true
		"transform":
			var transform_node := _resolve_transaction_node(transaction)
			if transform_node == null:
				return false
			var state: Dictionary = transaction.get("old_state", {}) if undo else transaction.get("new_state", {})
			if not _apply_transform_state(transform_node, state):
				return false
			_set_selected_node(transform_node)
			return true
		"reparent":
			var reparent_node := _resolve_transaction_node(transaction)
			if reparent_node == null:
				return false
			var parent_prefix := "old_parent" if undo else "new_parent"
			var target_parent := _resolve_transaction_parent(transaction, parent_prefix)
			if target_parent == null:
				return false
			reparent_node.reparent(target_parent, true)
			var target_index := int(transaction.get("old_index", -1) if undo else transaction.get("new_index", -1))
			if target_index >= 0 and target_index < target_parent.get_child_count():
				target_parent.move_child(reparent_node, target_index)
			_set_selected_node(reparent_node)
			return true
		"group":
			var group_node := _resolve_transaction_node(transaction)
			if group_node == null:
				return false
			var group_name := String(transaction.get("group_name", ""))
			var added := bool(transaction.get("added", false))
			if undo == added:
				group_node.remove_from_group(group_name)
			else:
				group_node.add_to_group(group_name)
			_set_selected_node(group_node)
			return true
		"node_create":
			if undo:
				var created_node := _resolve_transaction_node(transaction)
				if created_node == null:
					return false
				_destroy_node_immediate(created_node)
				_selected_node_path = ""
				_capture_inspector_baseline(null)
				return true
			var create_parent := _resolve_transaction_parent(transaction, "parent")
			var recreated := _restore_snapshot_under_parent(transaction.get("snapshot"), create_parent, int(transaction.get("child_index", -1)))
			if recreated == null:
				return false
			transaction["node_id"] = recreated.get_instance_id()
			transaction["node_path"] = _absolute_node_path(recreated)
			_set_selected_node(recreated)
			return true
		"node_delete":
			if undo:
				var delete_parent := _resolve_transaction_parent(transaction, "parent")
				var restored := _restore_snapshot_under_parent(transaction.get("snapshot"), delete_parent, int(transaction.get("child_index", -1)))
				if restored == null:
					return false
				transaction["node_id"] = restored.get_instance_id()
				transaction["node_path"] = _absolute_node_path(restored)
				_set_selected_node(restored)
				return true
			var deleted_node := _resolve_transaction_node(transaction)
			if deleted_node == null:
				return false
			_destroy_node_immediate(deleted_node)
			_selected_node_path = ""
			_capture_inspector_baseline(null)
			return true
	return false


func _finalize_transaction_step(transaction: Dictionary, undo: bool) -> void:
	transaction["state"] = "Undone" if undo else "Redone"
	_rebuild_hierarchy_tree()
	_refresh_all_views(false)
	_refresh_transaction_views()


func _undo_last_transaction() -> void:
	if _undo_stack.is_empty():
		_set_status("Nothing to undo.")
		return
	var transaction := _undo_stack.pop_back()
	if not _apply_transaction(transaction, true):
		_undo_stack.append(transaction)
		_set_status("Undo failed for %s." % String(transaction.get("label", "transaction")))
		return
	_redo_stack.append(transaction)
	_log_event("Undid %s." % String(transaction.get("label", "transaction")))
	_set_status("Undid %s." % String(transaction.get("label", "transaction")))
	_finalize_transaction_step(transaction, true)


func _redo_last_transaction() -> void:
	if _redo_stack.is_empty():
		_set_status("Nothing to redo.")
		return
	var transaction := _redo_stack.pop_back()
	if not _apply_transaction(transaction, false):
		_redo_stack.append(transaction)
		_set_status("Redo failed for %s." % String(transaction.get("label", "transaction")))
		return
	_undo_stack.append(transaction)
	_log_event("Redid %s." % String(transaction.get("label", "transaction")))
	_set_status("Redid %s." % String(transaction.get("label", "transaction")))
	_finalize_transaction_step(transaction, false)


func _revert_selected_node_to_baseline() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return

	var matching: Array[Dictionary] = []
	for index in range(_undo_stack.size() - 1, -1, -1):
		var transaction := _undo_stack[index]
		if _resolve_transaction_node(transaction) == node:
			matching.append(transaction)

	if matching.is_empty():
		_set_status("No tracked toolkit edits to revert for this node.")
		return

	for transaction in matching:
		_undo_stack.erase(transaction)
		if _apply_transaction(transaction, true):
			transaction["state"] = "Baseline Revert"
			_redo_stack.append(transaction)

	_capture_inspector_baseline(node)
	_log_event("Reverted %d toolkit edit(s) on %s." % [matching.size(), _absolute_node_path(node)])
	_set_status("Reverted %d toolkit edit(s)." % matching.size())
	_rebuild_hierarchy_tree()
	_refresh_all_views(false)
	_refresh_transaction_views()


func _refresh_log_view() -> void:
	if _log_view != null:
		_log_view.text = "\n".join(_event_log)


func _log_event(text: String) -> void:
	var line := "%s  %s" % [Time.get_time_string_from_system(), text]
	_event_log.append(line)
	while _event_log.size() > MAX_LOG_LINES:
		_event_log.remove_at(0)
	_refresh_log_view()


func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func _validate_selection() -> void:
	if _selected_node_path == "":
		return
	if _get_selected_node() != null:
		return

	_log_event("Selection invalidated: %s" % _selected_node_path)
	_selected_node_path = ""
	_capture_inspector_baseline(null)
	_refresh_inspector()
	_refresh_world_controls()
	_refresh_watch_view()
	_refresh_pick_controls()


func _set_selected_node(node: Node) -> void:
	var previous_path := _selected_node_path
	if node == null:
		_selected_node_path = ""
	else:
		_selected_node_path = _absolute_node_path(node)

	if _selected_node_path != previous_path:
		_capture_inspector_baseline(node)

	if _hierarchy_path_label != null:
		_hierarchy_path_label.text = "Selected: %s" % _value_or_placeholder(_selected_node_path)
	if _inspector_path_edit != null:
		_inspector_path_edit.text = _selected_node_path
	if _world_selected_path_edit != null:
		_world_selected_path_edit.text = _selected_node_path
	_refresh_inspector()
	_refresh_world_controls()
	_refresh_groups_view()
	_refresh_watch_view()
	_refresh_pick_controls()

	if node != null:
		_push_selection_history(_selected_node_path)
		_log_event("Selected node %s." % _selected_node_path)


func _get_selected_node() -> Node:
	if _selected_node_path == "":
		return null
	return get_node_or_null(_selected_node_path)


func _select_path(path: String) -> void:
	var trimmed := path.strip_edges()
	if trimmed == "":
		_set_status("Path is empty.")
		return

	var node := get_node_or_null(trimmed)
	if node == null:
		_set_status("Path not found: %s" % trimmed)
		return

	_set_selected_node(node)
	_tabs.current_tab = TAB_INSPECTOR
	_rebuild_hierarchy_tree()
	_set_status("Selected %s." % trimmed)


func _call_loader(method: String, args: Array = []) -> Variant:
	var loader := get_node_or_null("/root/Loader")
	if loader == null or not loader.has_method(method):
		_set_status("Loader method unavailable: %s" % method)
		return null
	return loader.callv(method, args)


func _in_map_context() -> bool:
	return get_node_or_null("/root/Map/Core/UI/Interface") != null


func _is_protected_node(node: Node) -> bool:
	if node == self or node == get_tree().root or node == get_tree().current_scene:
		return true

	var protected_names := {
		"Loader": true,
		"Simulation": true,
		"ModLoader": true,
		"RTVToolKit": true,
	}
	return protected_names.has(node.name)


func _collect_all_nodes() -> Array[Node]:
	var out: Array[Node] = []
	_collect_node_recursive(get_tree().root, out)
	return out


func _collect_node_recursive(node: Node, out: Array[Node]) -> void:
	out.append(node)
	for child in node.get_children():
		if child is Node:
			_collect_node_recursive(child, out)


func _node_is_descendant(node: Node, possible_descendant: Node) -> bool:
	var cursor := possible_descendant
	while cursor != null:
		if cursor == node:
			return true
		cursor = cursor.get_parent()
	return false


func _push_selection_history(path: String) -> void:
	if path == "":
		return
	if not _selection_history.is_empty() and _selection_history[0] == path:
		return

	_selection_history.erase(path)
	_selection_history.insert(0, path)
	while _selection_history.size() > MAX_HISTORY_ITEMS:
		_selection_history.remove_at(_selection_history.size() - 1)


func _push_persistent_path(target: Array[String], path: String) -> bool:
	var trimmed := path.strip_edges()
	if trimmed == "" or target.has(trimmed):
		return false
	target.append(trimmed)
	_save_state()
	return true


func _remove_persistent_path(target: Array[String], path: String) -> bool:
	if not target.has(path):
		return false
	target.erase(path)
	_save_state()
	return true


func _absolute_node_path(node: Node) -> String:
	return String(node.get_path())


func _node_display_name(node: Node) -> String:
	return "%s [%s]" % [node.name, node.get_class()]


func _owner_label(node: Node) -> String:
	return node.owner.name if node.owner != null else "<none>"


func _transform_summary(node: Node) -> String:
	if node is Node3D:
		var n3 := node as Node3D
		return "pos=%s rot=%s scale=%s" % [_format_variant(n3.global_position), _format_variant(n3.rotation_degrees), _format_variant(n3.scale)]
	if node is Node2D:
		var n2 := node as Node2D
		return "pos=%s rot=%s scale=%s" % [_format_variant(n2.global_position), str(n2.rotation_degrees), _format_variant(n2.scale)]
	if node is Control:
		var c := node as Control
		return "pos=%s rot=%s scale=%s" % [_format_variant(c.position), str(c.rotation_degrees), _format_variant(c.scale)]
	return "<not transformable>"


func _method_summary(node: Object) -> String:
	var methods: Array[String] = []
	for method_info in node.get_method_list():
		methods.append(String(method_info.get("name", "")))
	methods.sort()
	if methods.size() > 18:
		methods.resize(18)
		methods.append("...")
	return ", ".join(methods)


func _type_name(type_id: int) -> String:
	match type_id:
		TYPE_NIL:
			return "Nil"
		TYPE_BOOL:
			return "bool"
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_STRING:
			return "String"
		TYPE_VECTOR2:
			return "Vector2"
		TYPE_VECTOR2I:
			return "Vector2i"
		TYPE_VECTOR3:
			return "Vector3"
		TYPE_VECTOR3I:
			return "Vector3i"
		TYPE_COLOR:
			return "Color"
		TYPE_OBJECT:
			return "Object"
		TYPE_ARRAY:
			return "Array"
		TYPE_DICTIONARY:
			return "Dictionary"
		TYPE_NODE_PATH:
			return "NodePath"
		TYPE_STRING_NAME:
			return "StringName"
		_:
			return str(type_id)


func _format_variant(value) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return _bool_string(value)
		TYPE_INT, TYPE_FLOAT:
			return str(value)
		TYPE_STRING, TYPE_STRING_NAME:
			return String(value)
		TYPE_VECTOR2:
			return "(%.2f, %.2f)" % [value.x, value.y]
		TYPE_VECTOR3:
			return "(%.2f, %.2f, %.2f)" % [value.x, value.y, value.z]
		TYPE_COLOR:
			return "rgba(%.2f, %.2f, %.2f, %.2f)" % [value.r, value.g, value.b, value.a]
		TYPE_ARRAY:
			return "Array[%d]" % value.size()
		TYPE_DICTIONARY:
			return "Dictionary[%d]" % value.size()
		TYPE_OBJECT:
			if value == null:
				return "null"
			if value is Node:
				return "<Node %s %s>" % [value.name, value.get_class()]
			return "<Object %s>" % value.get_class()
		_:
			return str(value)


func _format_variant_edit(value) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			return String(value)
		TYPE_VECTOR2:
			return "%.3f, %.3f" % [value.x, value.y]
		TYPE_VECTOR3:
			return "%.3f, %.3f, %.3f" % [value.x, value.y, value.z]
		TYPE_COLOR:
			return "%.3f, %.3f, %.3f, %.3f" % [value.r, value.g, value.b, value.a]
		TYPE_ARRAY:
			return JSON.stringify(value, "  ")
		TYPE_DICTIONARY:
			return JSON.stringify(value, "  ")
		_:
			return _format_variant(value)


func _parse_input_value(type_id: int, text: String) -> Dictionary:
	var raw := text.strip_edges()
	match type_id:
		0:
			return {"ok": true, "value": _guess_value_from_text(raw)}
		1:
			var bool_text := raw.to_lower()
			if bool_text in ["true", "1", "yes", "on"]:
				return {"ok": true, "value": true}
			if bool_text in ["false", "0", "no", "off"]:
				return {"ok": true, "value": false}
			return {"ok": false, "error": "Expected bool value."}
		2:
			if not raw.is_valid_int():
				return {"ok": false, "error": "Expected int value."}
			return {"ok": true, "value": int(raw.to_int())}
		3:
			if not raw.is_valid_float() and not raw.is_valid_int():
				return {"ok": false, "error": "Expected float value."}
			return {"ok": true, "value": float(raw.to_float())}
		4:
			return {"ok": true, "value": raw}
		5:
			return _parse_vector2_text(raw)
		6:
			return _parse_vector3_text(raw)
		7:
			return _parse_color_text(raw)
		8:
			return {"ok": true, "value": NodePath(raw)}
		9:
			return _parse_json_container(raw, TYPE_ARRAY)
		10:
			return _parse_json_container(raw, TYPE_DICTIONARY)
		_:
			return {"ok": true, "value": raw}


func _guess_value_from_text(text: String):
	var raw := text.strip_edges()
	if raw == "":
		return ""

	var lower := raw.to_lower()
	if lower == "null":
		return null
	if lower in ["true", "false"]:
		return lower == "true"
	if raw.is_valid_int():
		return raw.to_int()
	if raw.is_valid_float():
		return raw.to_float()
	if raw.begins_with("[") or raw.begins_with("{"):
		var json_value = JSON.parse_string(raw)
		if json_value != null:
			return json_value

	var token_count := _split_numeric_tokens(raw).size()
	if token_count == 2:
		var parsed2 := _parse_vector2_text(raw)
		if bool(parsed2.get("ok", false)):
			return parsed2.get("value")
	if token_count == 3:
		var parsed3 := _parse_vector3_text(raw)
		if bool(parsed3.get("ok", false)):
			return parsed3.get("value")
	if token_count == 4:
		var parsed_color := _parse_color_text(raw)
		if bool(parsed_color.get("ok", false)):
			return parsed_color.get("value")

	return raw


func _parse_json_container(text: String, expected_type: int) -> Dictionary:
	var parsed = JSON.parse_string(text)
	if parsed == null and text.strip_edges().to_lower() != "null":
		return {"ok": false, "error": "Expected valid JSON."}
	if typeof(parsed) != expected_type:
		return {"ok": false, "error": "Expected %s JSON." % _type_name(expected_type)}
	return {"ok": true, "value": parsed}


func _parse_vector2_text(text: String) -> Dictionary:
	var tokens := _split_numeric_tokens(text)
	if tokens.size() != 2:
		return {"ok": false, "error": "Expected Vector2 as x, y."}
	if not _tokens_are_numeric(tokens):
		return {"ok": false, "error": "Vector2 components must be numeric."}
	return {"ok": true, "value": Vector2(tokens[0].to_float(), tokens[1].to_float())}


func _parse_vector3_text(text: String) -> Dictionary:
	var tokens := _split_numeric_tokens(text)
	if tokens.size() != 3:
		return {"ok": false, "error": "Expected Vector3 as x, y, z."}
	if not _tokens_are_numeric(tokens):
		return {"ok": false, "error": "Vector3 components must be numeric."}
	return {"ok": true, "value": Vector3(tokens[0].to_float(), tokens[1].to_float(), tokens[2].to_float())}


func _parse_color_text(text: String) -> Dictionary:
	var tokens := _split_numeric_tokens(text)
	if tokens.size() != 3 and tokens.size() != 4:
		return {"ok": false, "error": "Expected Color as r, g, b[, a]."}
	if not _tokens_are_numeric(tokens):
		return {"ok": false, "error": "Color components must be numeric."}

	var r := tokens[0].to_float()
	var g := tokens[1].to_float()
	var b := tokens[2].to_float()
	var a := tokens[3].to_float() if tokens.size() >= 4 else 1.0
	return {"ok": true, "value": Color(r, g, b, a)}


func _split_numeric_tokens(text: String) -> PackedStringArray:
	var normalized := text.replace("(", "").replace(")", "").replace("[", "").replace("]", "").replace(";", ",").replace("|", ",")
	var parts := normalized.split(",", false)
	if parts.size() == 1:
		parts = normalized.split(" ", false)

	var out := PackedStringArray()
	for part in parts:
		var trimmed := String(part).strip_edges()
		if trimmed != "":
			out.append(trimmed)
	return out


func _tokens_are_numeric(tokens: PackedStringArray) -> bool:
	for token in tokens:
		if not String(token).is_valid_int() and not String(token).is_valid_float():
			return false
	return true


func _stringify_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(_format_variant_edit(value))
	return out


func _as_array(value) -> Array:
	return value if value is Array else []


func _as_dict(value) -> Dictionary:
	return value if value is Dictionary else {}


func _read_property(obj: Object, property_name: String, fallback):
	if obj == null:
		return fallback
	for property_info in obj.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return obj.get(property_name)
	return fallback


func _has_property(obj: Object, property_name: String) -> bool:
	if obj == null:
		return false
	for property_info in obj.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true
	return false


func _apply_object_property_if_present(obj: Object, property_name: String, value) -> void:
	if _has_property(obj, property_name):
		obj.set(property_name, value)


func _value_or_placeholder(value: String) -> String:
	return value if value != "" else "<empty>"


func _bool_string(value: bool) -> String:
	return "true" if value else "false"


func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	return file.get_length()


func _format_bytes(byte_count: int) -> String:
	if byte_count < 1024:
		return "%d B" % byte_count
	if byte_count < 1024 * 1024:
		return "%.1f KB" % (float(byte_count) / 1024.0)
	return "%.2f MB" % (float(byte_count) / 1024.0 / 1024.0)


func _format_unix_time(unix_time: int) -> String:
	if unix_time <= 0:
		return "unknown"
	var dt := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		int(dt.get("year", 0)),
		int(dt.get("month", 0)),
		int(dt.get("day", 0)),
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0)),
		int(dt.get("second", 0)),
	]


func _bytes_look_textual(bytes: PackedByteArray) -> bool:
	var limit := min(bytes.size(), 512)
	for i in range(limit):
		var b := int(bytes[i])
		if b == 0:
			return false
		if b < 8:
			return false
	return true


func _timestamp_slug() -> String:
	return Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")


func _set_tree_collapsed(item: TreeItem, collapsed: bool, skip_root: bool = false) -> void:
	if item == null:
		return

	if not skip_root:
		item.set_collapsed(collapsed)

	var child := item.get_first_child()
	while child != null:
		_set_tree_collapsed(child, collapsed)
		child = child.get_next()


func _watch_summary(path: String) -> String:
	var node := get_node_or_null(path)
	if node == null:
		return "[missing] %s" % path
	return "%s | %s | %s" % [_node_display_name(node), _method_groups_string(node), _transform_summary(node)]


func _build_watch_report() -> String:
	var lines: Array[String] = []
	lines.append("RTV Tool Kit watch report")
	lines.append("Generated: %s" % Time.get_datetime_string_from_system())
	lines.append("")
	for path in _watch_paths:
		lines.append(_watch_summary(path))
	return "\n".join(lines)


func _load_state() -> void:
	var state := ToolkitConfig.load_state()
	_bookmarked_paths = state.get("bookmarks", [] as Array[String])
	_watch_paths = state.get("watch_paths", [] as Array[String])
	_pinned_properties = state.get("pinned_properties", [] as Array[String])
	_watched_properties = state.get("watched_properties", [] as Array[String])
	_window_position = state.get("window_position", ToolkitConfig.DEFAULT_WINDOW_POSITION)
	_window_size = state.get("window_size", ToolkitConfig.DEFAULT_WINDOW_SIZE)


func _save_state() -> void:
	ToolkitConfig.save_state(
		_bookmarked_paths,
		_watch_paths,
		_pinned_properties,
		_watched_properties,
		_panel.position if _panel != null else _window_position,
		_panel.size if _panel != null else _window_size
	)


func _current_scene_signature() -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return ""
	return "%s|%s|%d" % [scene.name, String(scene.scene_file_path), scene.get_child_count()]


func _is_menu_scene() -> bool:
	var scene := get_tree().current_scene
	return scene != null and String(scene.scene_file_path) == MENU_SCENE_PATH


func _append_scene_section(lines: Array[String]) -> void:
	lines.append("[Scene]")
	var scene := get_tree().current_scene
	if scene == null:
		lines.append("No current scene.")
		lines.append("")
		return

	lines.append("Path: %s" % _value_or_placeholder(String(scene.scene_file_path)))
	lines.append("Name: %s" % scene.name)
	lines.append("Class: %s" % scene.get_class())
	lines.append("Direct children: %d" % scene.get_child_count())
	lines.append("")


func _append_toolkit_section(lines: Array[String]) -> void:
	lines.append("[Tool Kit]")
	lines.append("bookmarks=%d watches=%d history=%d" % [_bookmarked_paths.size(), _watch_paths.size(), _selection_history.size()])
	lines.append("engine_time_scale=%s tree_paused=%s" % [str(Engine.time_scale), _bool_string(get_tree().paused)])
	lines.append("")


func _append_selection_section(lines: Array[String]) -> void:
	lines.append("[Selection]")
	var node := _get_selected_node()
	if node == null:
		lines.append("No selected node.")
		lines.append("")
		return

	lines.append("Path: %s" % _absolute_node_path(node))
	lines.append("Class: %s" % node.get_class())
	lines.append("Groups: %s" % _method_groups_string(node))
	lines.append("Transform: %s" % _transform_summary(node))
	lines.append("")


func _append_game_data_section(lines: Array[String]) -> void:
	lines.append("[GameData]")
	if game_data == null:
		lines.append("GameData unavailable.")
		lines.append("")
		return

	lines.append("menu=%s shelter=%s permadeath=%s tutorial=%s freeze=%s compatibility=%s" % [
		_bool_string(_read_property(game_data, "menu", false)),
		_bool_string(_read_property(game_data, "shelter", false)),
		_bool_string(_read_property(game_data, "permadeath", false)),
		_bool_string(_read_property(game_data, "tutorial", false)),
		_bool_string(_read_property(game_data, "freeze", false)),
		_bool_string(_read_property(game_data, "compatibility", false)),
	])
	lines.append("health=%s energy=%s hydration=%s mental=%s temperature=%s" % [
		str(_read_property(game_data, "health", "?")),
		str(_read_property(game_data, "energy", "?")),
		str(_read_property(game_data, "hydration", "?")),
		str(_read_property(game_data, "mental", "?")),
		str(_read_property(game_data, "temperature", "?")),
	])
	lines.append("")


func _append_simulation_section(lines: Array[String]) -> void:
	lines.append("[Simulation]")
	var simulation := get_node_or_null("/root/Simulation")
	if simulation == null:
		lines.append("Simulation autoload not found.")
		lines.append("")
		return

	lines.append("day=%s time=%s season=%s weather=%s weatherTime=%s simulate=%s" % [
		str(_read_property(simulation, "day", "?")),
		str(_read_property(simulation, "time", "?")),
		str(_read_property(simulation, "season", "?")),
		str(_read_property(simulation, "weather", "?")),
		str(_read_property(simulation, "weatherTime", "?")),
		_bool_string(_read_property(simulation, "simulate", false)),
	])
	lines.append("")


func _append_loader_section(lines: Array[String]) -> void:
	lines.append("[Loader]")
	var loader := get_node_or_null("/root/Loader")
	lines.append("Loader present: %s" % _bool_string(loader != null))
	lines.append("RTVModLib meta: %s" % _bool_string(Engine.has_meta("RTVModLib")))
	if loader != null and loader.has_method("ValidateShelter"):
		lines.append("Latest shelter: %s" % _value_or_placeholder(String(loader.ValidateShelter())))
	lines.append("user:// path: %s" % ProjectSettings.globalize_path("user://"))
	lines.append("")


func _append_group_counts_section(lines: Array[String]) -> void:
	lines.append("[World Groups]")
	for group_name in QUICK_GROUPS:
		lines.append("%s: %d" % [group_name, get_tree().get_nodes_in_group(group_name).size()])
	lines.append("")


func _append_notes_section(lines: Array[String]) -> void:
	lines.append("[Task Notes]")
	var loader := get_node_or_null("/root/Loader")
	if loader == null or not loader.has_method("LoadTaskNotes"):
		lines.append("Task note API unavailable.")
		lines.append("")
		return

	var notes = loader.LoadTaskNotes()
	if not (notes is Array):
		lines.append("Task note data unavailable.")
		lines.append("")
		return

	lines.append("Count: %d" % notes.size())
	var shown := 0
	for task in notes:
		if task == null:
			continue
		lines.append("- %s [%s]" % [
			_value_or_placeholder(str(_read_property(task, "name", ""))),
			_value_or_placeholder(str(_read_property(task, "trader", ""))),
		])
		shown += 1
		if shown >= 10 and notes.size() > shown:
			lines.append("- ... (%d more)" % (notes.size() - shown))
			break

	lines.append("")


func _append_root_section(lines: Array[String]) -> void:
	lines.append("[Root Nodes]")
	for child in get_tree().root.get_children():
		lines.append("- %s [%s]" % [child.name, child.get_class()])
	lines.append("")


func _append_user_file_summary_section(lines: Array[String]) -> void:
	lines.append("[user:// Files]")
	lines.append("Tracked files: %d" % _file_entries.size())
	for i in range(min(_file_entries.size(), 10)):
		var entry := _file_entries[i]
		lines.append("- %s | %s | %s" % [
			entry["relative_path"],
			_format_bytes(int(entry["size"])),
			_format_unix_time(int(entry["mtime"])),
		])
	if _file_entries.size() > 10:
		lines.append("- ... (%d more)" % (_file_entries.size() - 10))
	lines.append("")


func _method_groups_string(node: Node) -> String:
	var groups: Array[String] = []
	for group_name in node.get_groups():
		groups.append(String(group_name))
	groups.sort()
	return "none" if groups.is_empty() else ", ".join(groups)


func _on_refresh_all_pressed() -> void:
	_refresh_all_views(true)
	_set_status("Refreshed all toolkit views.")


func _on_copy_report_pressed() -> void:
	_refresh_overview_report()
	DisplayServer.clipboard_set(_last_report_text)
	_log_event("Copied overview report to clipboard.")
	_set_status("Copied overview report.")


func _on_dump_report_pressed() -> void:
	_refresh_overview_report()
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		_set_status("Failed to write report.")
		return

	file.store_string(_last_report_text)
	_log_event("Dumped report to %s." % ProjectSettings.globalize_path(REPORT_PATH))
	_set_status("Report dumped to %s" % ProjectSettings.globalize_path(REPORT_PATH))


func _on_refresh_diagnostics_pressed() -> void:
	_refresh_diagnostics_view()
	_set_status("Diagnostics refreshed.")
	_log_event("Diagnostics refreshed.")


func _on_copy_diagnostics_pressed() -> void:
	_refresh_diagnostics_view()
	DisplayServer.clipboard_set(_last_diagnostics_report_text)
	_log_event("Copied diagnostics report.")
	_set_status("Copied diagnostics report.")


func _on_dump_diagnostics_pressed() -> void:
	_refresh_diagnostics_view()
	var file := FileAccess.open(DIAGNOSTICS_REPORT_PATH, FileAccess.WRITE)
	if file == null:
		_set_status("Failed to write diagnostics report.")
		return

	file.store_string(_last_diagnostics_report_text)
	file.close()
	_log_event("Dumped diagnostics report to %s." % ProjectSettings.globalize_path(DIAGNOSTICS_REPORT_PATH))
	_set_status("Diagnostics report dumped to %s" % ProjectSettings.globalize_path(DIAGNOSTICS_REPORT_PATH))


func _on_diagnostics_mod_selected(index: int) -> void:
	if _diagnostics_mod_list == null or index < 0:
		return
	_diagnostics_focus_kind = "mod"
	_diagnostics_focus_key = String(_diagnostics_mod_list.get_item_metadata(index))
	_refresh_diagnostics_detail()
	_set_status("Diagnostics detail focused on mod.")


func _on_diagnostics_issue_selected(index: int) -> void:
	if _diagnostics_issue_list == null or index < 0:
		return
	_diagnostics_focus_kind = "issue"
	_diagnostics_focus_key = String(_diagnostics_issue_list.get_item_metadata(index))
	_refresh_diagnostics_detail()
	_set_status("Diagnostics detail focused on issue.")


func _on_probe_pressed() -> void:
	var loader := get_node_or_null("/root/Loader")
	if loader == null or not loader.has_method("Message"):
		_set_status("Loader message API unavailable.")
		return

	loader.Message("RTV Tool Kit probe OK.", Color.GREEN)
	_log_event("Sent loader probe message.")
	_set_status("Sent probe message.")


func _on_toggle_simulation_pressed() -> void:
	var simulation := get_node_or_null("/root/Simulation")
	if simulation == null or not _has_property(simulation, "simulate"):
		_set_status("Simulation toggle unavailable.")
		return

	var new_value := not bool(simulation.get("simulate"))
	simulation.set("simulate", new_value)
	_log_event("Simulation.simulate set to %s." % _bool_string(new_value))
	_set_status("Simulation.simulate = %s" % _bool_string(new_value))
	_refresh_overview_report()


func _on_save_character_pressed() -> void:
	if not _in_map_context():
		_set_status("Save Character only works in map context.")
		return
	_call_loader("SaveCharacter")
	_log_event("Called Loader.SaveCharacter().")
	_set_status("Requested Loader.SaveCharacter().")


func _on_save_world_pressed() -> void:
	if not _in_map_context():
		_set_status("Save World only works in map context.")
		return
	_call_loader("SaveWorld")
	_log_event("Called Loader.SaveWorld().")
	_set_status("Requested Loader.SaveWorld().")


func _on_update_progression_pressed() -> void:
	if not _in_map_context():
		_set_status("Update Progression only works in map context.")
		return
	_call_loader("UpdateProgression")
	_log_event("Called Loader.UpdateProgression().")
	_set_status("Requested Loader.UpdateProgression().")


func _on_load_character_pressed() -> void:
	if not _in_map_context():
		_set_status("Load Character only works in map context.")
		return
	_call_loader("LoadCharacter")
	_log_event("Called Loader.LoadCharacter().")
	_set_status("Requested Loader.LoadCharacter().")


func _on_load_world_pressed() -> void:
	if not _in_map_context():
		_set_status("Load World only works in map context.")
		return
	_call_loader("LoadWorld")
	_log_event("Called Loader.LoadWorld().")
	_set_status("Requested Loader.LoadWorld().")


func _on_pull_runtime_pressed() -> void:
	_refresh_runtime_controls()
	_set_status("Pulled runtime state.")


func _on_apply_runtime_pressed() -> void:
	_apply_runtime_controls()


func _on_send_runtime_message_pressed() -> void:
	var loader := get_node_or_null("/root/Loader")
	if loader == null or not loader.has_method("Message"):
		_set_status("Loader message API unavailable.")
		return

	var text := _runtime_message_edit.text.strip_edges()
	if text == "":
		text = "RTV Tool Kit custom message."
	loader.Message(text, Color.GREEN)
	_log_event("Sent custom loader message.")
	_set_status("Sent custom loader message.")


func _on_rebuild_tree_pressed() -> void:
	_rebuild_hierarchy_tree()
	_log_event("Rebuilt hierarchy tree.")
	_set_status("Rebuilt hierarchy tree.")


func _on_expand_tree_pressed() -> void:
	_set_tree_collapsed(_hierarchy_tree.get_root(), false, true)
	_set_status("Expanded hierarchy tree.")


func _on_collapse_tree_pressed() -> void:
	_set_tree_collapsed(_hierarchy_tree.get_root(), true, true)
	_set_status("Collapsed hierarchy tree.")


func _on_copy_selected_path_pressed() -> void:
	if _selected_node_path == "":
		_set_status("No selected node path.")
		return
	DisplayServer.clipboard_set(_selected_node_path)
	_set_status("Copied selected node path.")


func _on_open_inspector_pressed() -> void:
	_tabs.current_tab = TAB_INSPECTOR
	_refresh_inspector()
	_set_status("Opened Inspector tab.")


func _on_pick_toggle_pressed() -> void:
	_set_pick_mode(not _pick_enabled, false if _pick_enabled else true)
	if _pick_enabled:
		_set_status("Pick mode active. Click an object to select it.")
	else:
		_set_status("Pick mode disabled.")


func _on_search_pressed() -> void:
	_run_search(true)


func _on_refresh_inspector_pressed() -> void:
	_refresh_inspector()
	_set_status("Refreshed inspector.")


func _on_copy_inspector_summary_pressed() -> void:
	DisplayServer.clipboard_set(_inspector_meta.get_parsed_text())
	_log_event("Copied inspector summary.")
	_set_status("Copied inspector summary.")


func _on_property_name_text_changed(_text: String) -> void:
	var node := _get_selected_node()
	var property_name := _resolve_target_property_name()
	if node != null and property_name != "" and _has_property(node, property_name):
		_inspector_selected_property = property_name
		_inspector_selected_property_type = typeof(node.get(property_name))
		_select_option_button_id(_property_type_option, _inspector_parse_mode_for_type(_inspector_selected_property_type))
	_refresh_resource_meta(node)
	_refresh_property_action_buttons(node)


func _on_property_tree_item_selected() -> void:
	if _property_tree == null:
		return

	var item := _property_tree.get_selected()
	if item == null:
		return

	var metadata = item.get_metadata(0)
	if not (metadata is Dictionary) or String(metadata.get("kind", "")) != "property":
		return

	var node := _get_selected_node()
	var property_name := String(metadata.get("name", ""))
	var type_id := int(metadata.get("type_id", TYPE_NIL))
	if _sync_inspector_property_selection(node, property_name, type_id, true):
		_set_status("Selected property %s." % property_name)


func _on_property_tree_item_activated() -> void:
	_on_property_tree_item_selected()
	_pull_selected_property_to_editor()


func _on_pull_property_pressed() -> void:
	_pull_selected_property_to_editor()


func _on_apply_property_pressed() -> void:
	_apply_property_to_selected()


func _on_copy_property_name_pressed() -> void:
	var node := _get_selected_node()
	var property_name := _resolve_target_property_name()
	if node == null or property_name == "" or not _has_property(node, property_name):
		_set_status("No property selected.")
		return

	DisplayServer.clipboard_set(_property_full_path(node, property_name))
	_set_status("Copied property path.")


func _on_copy_property_value_pressed() -> void:
	var node := _get_selected_node()
	var property_name := _resolve_target_property_name()
	if node == null or property_name == "" or not _has_property(node, property_name):
		_set_status("No property selected.")
		return

	DisplayServer.clipboard_set(_format_variant_edit(node.get(property_name)))
	_set_status("Copied property value.")


func _on_copy_property_type_pressed() -> void:
	var node := _get_selected_node()
	var property_name := _resolve_target_property_name()
	if node == null or property_name == "" or not _has_property(node, property_name):
		_set_status("No property selected.")
		return

	DisplayServer.clipboard_set(_type_name(typeof(node.get(property_name))))
	_set_status("Copied property type.")


func _on_toggle_property_pin_pressed() -> void:
	var node := _get_selected_node()
	var property_name := _resolve_target_property_name()
	if node == null or property_name == "" or not _has_property(node, property_name):
		_set_status("No property selected.")
		return

	var was_pinned := _pinned_properties.has(property_name)
	if was_pinned:
		_pinned_properties.remove_at(_pinned_properties.find(property_name))
	else:
		_pinned_properties.append(property_name)
		_pinned_properties.sort()

	_save_state()
	_refresh_inspector()
	_set_status("%s property %s." % ["Unpinned" if was_pinned else "Pinned", property_name])


func _on_toggle_property_watch_pressed() -> void:
	var node := _get_selected_node()
	var property_name := _resolve_target_property_name()
	if node == null or property_name == "" or not _has_property(node, property_name):
		_set_status("No property selected.")
		return

	var was_watched := _watched_properties.has(property_name)
	if was_watched:
		_watched_properties.remove_at(_watched_properties.find(property_name))
	else:
		_watched_properties.append(property_name)
		_watched_properties.sort()

	_save_state()
	_refresh_inspector()
	_set_status("%s property %s." % ["Unwatched" if was_watched else "Watching", property_name])


func _on_revert_property_pressed() -> void:
	var node := _get_selected_node()
	var property_name := _resolve_target_property_name()
	if node == null or property_name == "" or not _has_property(node, property_name):
		_set_status("No property selected.")
		return
	if _is_node_edit_locked(node, "revert property on"):
		return
	if not _inspector_baseline_values.has(property_name):
		_set_status("No baseline captured for %s." % property_name)
		return

	var old_value = node.get(property_name)
	node.set(property_name, _duplicate_variant_for_baseline(_inspector_baseline_values[property_name]))
	_record_property_transaction(node, property_name, old_value, node.get(property_name))
	_sync_inspector_property_selection(node, property_name, typeof(node.get(property_name)), true)
	_refresh_inspector()
	_refresh_world_controls()
	_log_event("Reverted %s." % _property_full_path(node, property_name))
	_set_status("Reverted property %s." % property_name)


func _on_call_method_pressed() -> void:
	_call_selected_method()


func _on_preview_status_changed(text: String) -> void:
	_set_status(text)


func _on_preview_selected_node_pressed() -> void:
	_load_preview_from_selected_node()


func _on_preview_selected_property_pressed() -> void:
	_load_preview_from_selected_property()


func _on_preview_load_path_pressed() -> void:
	_load_preview_from_manual_path()


func _on_preview_frame_pressed() -> void:
	if _preview_viewport == null or not _preview_viewport.has_method("frame_content"):
		_set_status("Preview viewport is unavailable.")
		return
	_preview_viewport.call("frame_content")


func _on_preview_reset_camera_pressed() -> void:
	if _preview_viewport == null or not _preview_viewport.has_method("reset_camera"):
		_set_status("Preview viewport is unavailable.")
		return
	_preview_viewport.call("reset_camera")


func _on_preview_clear_pressed() -> void:
	if _preview_viewport == null or not _preview_viewport.has_method("clear_preview"):
		_set_status("Preview viewport is unavailable.")
		return
	var result = _preview_viewport.call("clear_preview")
	if result is Dictionary:
		_set_preview_output(result)


func _on_preview_copy_report_pressed() -> void:
	DisplayServer.clipboard_set(_build_preview_report_text())
	_set_status("Copied preview report.")


func _on_preview_markers_toggled(enabled: bool) -> void:
	if _preview_viewport != null and _preview_viewport.has_method("set_marker_visibility"):
		_preview_viewport.call("set_marker_visibility", enabled)
	_set_status("Preview markers %s." % ("enabled" if enabled else "disabled"))


func _on_preview_floor_toggled(enabled: bool) -> void:
	if _preview_viewport != null and _preview_viewport.has_method("set_floor_visibility"):
		_preview_viewport.call("set_floor_visibility", enabled)
	_set_status("Preview floor %s." % ("enabled" if enabled else "disabled"))


func _on_preview_axes_toggled(enabled: bool) -> void:
	if _preview_viewport != null and _preview_viewport.has_method("set_axes_visibility"):
		_preview_viewport.call("set_axes_visibility", enabled)
	_set_status("Preview axes %s." % ("enabled" if enabled else "disabled"))


func _on_preview_spin_toggled(enabled: bool) -> void:
	if _preview_viewport != null and _preview_viewport.has_method("set_auto_spin"):
		_preview_viewport.call("set_auto_spin", enabled)
	_set_status("Preview auto spin %s." % ("enabled" if enabled else "disabled"))


func _on_preview_focus_entry_pressed() -> void:
	if _preview_special_list == null:
		_set_status("No preview entry list.")
		return
	var selected := _preview_special_list.get_selected_items()
	if selected.is_empty():
		_set_status("No preview entry selected.")
		return
	var path := String(_preview_special_list.get_item_metadata(selected[0]))
	if _preview_viewport != null and _preview_viewport.has_method("focus_special_path") and _preview_viewport.call("focus_special_path", path):
		return
	_set_status("Selected preview entry cannot be focused.")


func _on_preview_special_selected(index: int) -> void:
	if _preview_special_list == null or index < 0:
		return
	_set_status("Preview entry selected: %s" % _preview_special_list.get_item_text(index))


func _on_preview_special_activated(index: int) -> void:
	if _preview_special_list == null or index < 0:
		return
	_on_preview_focus_entry_pressed()


func _on_apply_name_pressed() -> void:
	_apply_selected_name()


func _on_apply_visible_pressed() -> void:
	_apply_selected_visibility()


func _on_pull_transform_pressed() -> void:
	_pull_transform_from_selected()


func _on_apply_transform_pressed() -> void:
	_apply_transform_to_selected()


func _on_duplicate_selected_pressed() -> void:
	_duplicate_selected()


func _on_delete_selected_pressed() -> void:
	_delete_selected()


func _on_spawn_scene_root_pressed() -> void:
	_spawn_scene(false)


func _on_spawn_selected_pressed() -> void:
	_spawn_scene(true)


func _on_select_path_pressed() -> void:
	_select_path(_world_jump_path_edit.text)


func _on_reparent_selected_pressed() -> void:
	_reparent_selected()


func _on_create_helper_pressed(kind: String, under_selected: bool) -> void:
	_create_helper_node(kind, under_selected)


func _on_refresh_files_pressed() -> void:
	_refresh_file_list()
	_log_event("Refreshed file list.")
	_set_status("Refreshed file list.")


func _on_snapshot_user_pressed() -> void:
	var snapshot_root := _snapshot_user_files()
	_refresh_file_list()
	_log_event("Snapshot stored at %s." % snapshot_root)
	_set_status("Snapshot stored at %s." % ProjectSettings.globalize_path(snapshot_root))


func _on_copy_preview_pressed() -> void:
	DisplayServer.clipboard_set(_file_preview.text)
	_set_status("Copied file preview.")


func _on_copy_user_file_path_pressed() -> void:
	if _selected_user_file == "":
		_set_status("No selected file.")
		return
	DisplayServer.clipboard_set(_selected_user_file)
	_set_status("Copied user:// file path.")


func _on_copy_global_file_path_pressed() -> void:
	if _selected_user_file == "":
		_set_status("No selected file.")
		return
	DisplayServer.clipboard_set(ProjectSettings.globalize_path(_selected_user_file))
	_set_status("Copied global file path.")


func _on_copy_log_pressed() -> void:
	DisplayServer.clipboard_set("\n".join(_event_log))
	_set_status("Copied toolkit log.")


func _on_transaction_selected() -> void:
	_refresh_selected_transaction_detail()


func _on_undo_pressed() -> void:
	_undo_last_transaction()


func _on_redo_pressed() -> void:
	_redo_last_transaction()


func _on_revert_selected_object_pressed() -> void:
	_revert_selected_node_to_baseline()


func _on_clear_transactions_pressed() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	_transaction_history.clear()
	_refresh_transaction_views()
	_set_status("Cleared transaction history.")


func _on_refresh_groups_pressed() -> void:
	_refresh_groups_view()
	_set_status("Refreshed groups.")


func _on_copy_group_paths_pressed() -> void:
	if _selected_group_name == "":
		_set_status("No group selected.")
		return

	var paths: Array[String] = []
	for node in get_tree().get_nodes_in_group(_selected_group_name):
		if node is Node:
			paths.append(_absolute_node_path(node))
	paths.sort()
	DisplayServer.clipboard_set("\n".join(paths))
	_set_status("Copied %d path(s) from %s." % [paths.size(), _selected_group_name])


func _on_add_selected_to_group_pressed() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return
	if _is_node_edit_locked(node, "add to group"):
		return

	var group_name := _group_name_edit.text.strip_edges()
	if group_name == "":
		group_name = _selected_group_name
	if group_name == "":
		_set_status("No group name specified.")
		return
	if node.is_in_group(group_name):
		_set_status("Selected node is already in %s." % group_name)
		return

	node.add_to_group(group_name)
	_record_group_transaction(node, group_name, true)
	_selected_group_name = group_name
	_refresh_groups_view()
	_refresh_inspector()
	_log_event("Added %s to group %s." % [_absolute_node_path(node), group_name])
	_set_status("Added selected node to %s." % group_name)


func _on_remove_selected_from_group_pressed() -> void:
	var node := _get_selected_node()
	if node == null:
		_set_status("No selected node.")
		return
	if _is_node_edit_locked(node, "remove from group"):
		return

	var group_name := _group_name_edit.text.strip_edges()
	if group_name == "":
		group_name = _selected_group_name
	if group_name == "":
		_set_status("No group name specified.")
		return
	if not node.is_in_group(group_name):
		_set_status("Selected node is not in %s." % group_name)
		return

	node.remove_from_group(group_name)
	_record_group_transaction(node, group_name, false)
	_refresh_groups_view()
	_refresh_inspector()
	_log_event("Removed %s from group %s." % [_absolute_node_path(node), group_name])
	_set_status("Removed selected node from %s." % group_name)


func _on_bookmark_selected_pressed() -> void:
	if _selected_node_path == "":
		_set_status("No selected node.")
		return
	if _push_persistent_path(_bookmarked_paths, _selected_node_path):
		_refresh_watch_view()
		_set_status("Bookmarked selected node.")
	else:
		_set_status("Selected node is already bookmarked.")


func _on_watch_selected_pressed() -> void:
	if _selected_node_path == "":
		_set_status("No selected node.")
		return
	if _push_persistent_path(_watch_paths, _selected_node_path):
		_refresh_watch_view()
		_set_status("Watching selected node.")
	else:
		_set_status("Selected node is already watched.")


func _on_remove_bookmark_pressed() -> void:
	var selected := _bookmark_list.get_selected_items()
	if selected.size() == 0:
		_set_status("No bookmark selected.")
		return

	var path := String(_bookmark_list.get_item_metadata(selected[0]))
	if _remove_persistent_path(_bookmarked_paths, path):
		_refresh_watch_view()
		_set_status("Removed bookmark.")


func _on_remove_watch_pressed() -> void:
	var selected := _watch_list.get_selected_items()
	if selected.size() == 0:
		_set_status("No watch selected.")
		return

	var path := String(_watch_list.get_item_metadata(selected[0]))
	if _remove_persistent_path(_watch_paths, path):
		_refresh_watch_view()
		_set_status("Removed watch.")


func _on_copy_watch_report_pressed() -> void:
	DisplayServer.clipboard_set(_build_watch_report())
	_set_status("Copied watch report.")


func _on_clear_log_pressed() -> void:
	_event_log.clear()
	_refresh_log_view()
	_set_status("Cleared toolkit log.")


func _on_select_scene_root_pressed() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		_set_status("No current scene.")
		return
	_set_selected_node(scene)
	_rebuild_hierarchy_tree()
	_set_status("Selected current scene root.")


func _on_select_loader_pressed() -> void:
	var loader := get_node_or_null("/root/Loader")
	if loader == null:
		_set_status("Loader not found.")
		return
	_set_selected_node(loader)
	_rebuild_hierarchy_tree()
	_set_status("Selected Loader.")


func _on_select_map_pressed() -> void:
	var map := get_node_or_null("/root/Map")
	if map == null:
		_set_status("Map not found.")
		return
	_set_selected_node(map)
	_rebuild_hierarchy_tree()
	_set_status("Selected Map.")


func _on_clear_selection_pressed() -> void:
	_set_selected_node(null)
	_rebuild_hierarchy_tree()
	_set_status("Cleared selection.")


func _on_select_parent_pressed() -> void:
	var node := _get_selected_node()
	if node == null or node.get_parent() == null:
		_set_status("Selected node has no parent.")
		return
	_set_selected_node(node.get_parent())
	_rebuild_hierarchy_tree()
	_set_status("Selected parent node.")


func _on_select_script_owner_pressed() -> void:
	_select_script_owner()


func _on_hierarchy_item_selected() -> void:
	var item := _hierarchy_tree.get_selected()
	if item == null:
		return
	var path := String(item.get_metadata(0))
	var node := get_node_or_null(path)
	if node == null:
		return

	_set_selected_node(node)
	_hierarchy_path_label.text = "Selected: %s" % path


func _on_hierarchy_item_activated() -> void:
	_tabs.current_tab = TAB_INSPECTOR
	_set_status("Opened Inspector for hierarchy selection.")


func _on_search_result_selected(index: int) -> void:
	var path := String(_search_results.get_item_metadata(index))
	var node := get_node_or_null(path)
	if node == null:
		return

	_set_selected_node(node)
	_set_status("Selected search result.")


func _on_search_result_activated(index: int) -> void:
	_on_search_result_selected(index)
	_tabs.current_tab = TAB_INSPECTOR


func _on_file_item_selected(index: int) -> void:
	_selected_user_file = String(_file_list.get_item_metadata(index))
	_refresh_file_preview()
	_set_status("Selected %s." % _selected_user_file)


func _on_group_selected(index: int) -> void:
	_selected_group_name = String(_group_list.get_item_metadata(index))
	_group_name_edit.text = _selected_group_name
	_refresh_group_members()
	_set_status("Selected group %s." % _selected_group_name)


func _on_group_member_selected(index: int) -> void:
	var path := String(_group_members.get_item_metadata(index))
	var node := get_node_or_null(path)
	if node == null:
		return
	_set_selected_node(node)
	_set_status("Selected group member.")


func _on_group_member_activated(index: int) -> void:
	_on_group_member_selected(index)
	_tabs.current_tab = TAB_INSPECTOR


func _on_bookmark_selected(index: int) -> void:
	var path := String(_bookmark_list.get_item_metadata(index))
	var node := get_node_or_null(path)
	if node != null:
		_set_selected_node(node)
		_set_status("Selected bookmarked node.")


func _on_bookmark_activated(index: int) -> void:
	_on_bookmark_selected(index)
	_tabs.current_tab = TAB_INSPECTOR


func _on_watch_item_selected(index: int) -> void:
	var path := String(_watch_list.get_item_metadata(index))
	var node := get_node_or_null(path)
	if node != null:
		_set_selected_node(node)
		_set_status("Selected watched node.")


func _on_watch_item_activated(index: int) -> void:
	_on_watch_item_selected(index)
	_tabs.current_tab = TAB_INSPECTOR


func _on_history_item_selected(index: int) -> void:
	var path := String(_history_list.get_item_metadata(index))
	var node := get_node_or_null(path)
	if node != null:
		_set_selected_node(node)
		_set_status("Selected history node.")


func _on_history_item_activated(index: int) -> void:
	_on_history_item_selected(index)
	_tabs.current_tab = TAB_INSPECTOR
