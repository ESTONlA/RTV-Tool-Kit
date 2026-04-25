extends RefCounted

const QUICK_GROUPS := ["Furniture", "Item", "Switch"]
const ToolkitTheme = preload("res://RTVToolKit/ui/ToolkitTheme.gd")
const PreviewViewport = preload("res://RTVToolKit/ui/PreviewViewport.gd")


static func build_tabs(host, tabs: TabContainer) -> void:
	_add_tab(tabs, "Overview", _build_overview_tab(host))
	_add_tab(tabs, "Hierarchy", _build_hierarchy_tab(host))
	_add_tab(tabs, "Search", _build_search_tab(host))
	_add_tab(tabs, "Inspector", _build_inspector_tab(host))
	_add_tab(tabs, "Preview", _build_preview_tab(host))
	_add_tab(tabs, "World Edit", _build_world_tab(host))
	_add_tab(tabs, "Files", _build_files_tab(host))
	_add_tab(tabs, "Runtime", _build_runtime_tab(host))
	_add_tab(tabs, "Diagnostics", _build_diagnostics_tab(host))
	_add_tab(tabs, "Groups", _build_groups_tab(host))
	_add_tab(tabs, "Watch", _build_watch_tab(host))
	_add_tab(tabs, "Log", _build_log_tab(host))


static func _build_overview_tab(host) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var row1 := _make_action_flow()
	root.add_child(row1)
	row1.add_child(_make_button("Refresh All", Callable(host, "_on_refresh_all_pressed")))
	row1.add_child(_make_button("Copy Report", Callable(host, "_on_copy_report_pressed")))
	row1.add_child(_make_button("Dump Report", Callable(host, "_on_dump_report_pressed")))
	row1.add_child(_make_button("Probe Msg", Callable(host, "_on_probe_pressed")))
	row1.add_child(_make_button("Toggle Sim", Callable(host, "_on_toggle_simulation_pressed")))

	var row2 := _make_action_flow()
	root.add_child(row2)
	row2.add_child(_make_button("Save Character", Callable(host, "_on_save_character_pressed")))
	row2.add_child(_make_button("Save World", Callable(host, "_on_save_world_pressed")))
	row2.add_child(_make_button("Update Progression", Callable(host, "_on_update_progression_pressed")))
	row2.add_child(_make_button("Select Scene", Callable(host, "_on_select_scene_root_pressed")))
	row2.add_child(_make_button("Select Loader", Callable(host, "_on_select_loader_pressed")))
	row2.add_child(_make_button("Select Map", Callable(host, "_on_select_map_pressed")))
	row2.add_child(_make_button("Clear Selection", Callable(host, "_on_clear_selection_pressed")))

	host._overview_label = RichTextLabel.new()
	host._overview_label.bbcode_enabled = false
	host._overview_label.scroll_active = true
	host._overview_label.selection_enabled = true
	host._overview_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._overview_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_make_panel_shell("Runtime Report", host._overview_label))

	return root


static func _build_hierarchy_tab(host) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var row := _make_action_flow()
	root.add_child(row)
	row.add_child(_make_button("Rebuild Tree", Callable(host, "_on_rebuild_tree_pressed")))
	row.add_child(_make_button("Expand All", Callable(host, "_on_expand_tree_pressed")))
	row.add_child(_make_button("Collapse All", Callable(host, "_on_collapse_tree_pressed")))
	row.add_child(_make_button("Select Scene", Callable(host, "_on_select_scene_root_pressed")))
	row.add_child(_make_button("Select Loader", Callable(host, "_on_select_loader_pressed")))
	row.add_child(_make_button("Select Map", Callable(host, "_on_select_map_pressed")))
	row.add_child(_make_button("Copy Path", Callable(host, "_on_copy_selected_path_pressed")))
	row.add_child(_make_button("Open Inspector", Callable(host, "_on_open_inspector_pressed")))

	var pick_row := _make_action_flow()
	root.add_child(pick_row)

	host._pick_toggle_button = _make_button("Start Pick", Callable(host, "_on_pick_toggle_pressed"))
	pick_row.add_child(host._pick_toggle_button)

	host._pick_freeze_check = CheckBox.new()
	host._pick_freeze_check.text = "Freeze Hover"
	pick_row.add_child(host._pick_freeze_check)

	host._pick_controls_check = CheckBox.new()
	host._pick_controls_check.text = "UI"
	host._pick_controls_check.button_pressed = true
	pick_row.add_child(host._pick_controls_check)

	host._pick_world_check = CheckBox.new()
	host._pick_world_check.text = "World"
	host._pick_world_check.button_pressed = true
	pick_row.add_child(host._pick_world_check)

	pick_row.add_child(_make_button("Pick Parent", Callable(host, "_on_select_parent_pressed")))

	host._pick_script_owner_button = _make_button("Script Owner", Callable(host, "_on_select_script_owner_pressed"))
	pick_row.add_child(host._pick_script_owner_button)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 6)
	root.add_child(filter_row)

	host._hierarchy_filter_edit = LineEdit.new()
	host._hierarchy_filter_edit.placeholder_text = "Filter hierarchy by name, class, or path..."
	host._hierarchy_filter_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_row.add_child(host._hierarchy_filter_edit)
	filter_row.add_child(_make_button("Apply Filter", Callable(host, "_on_rebuild_tree_pressed")))

	var split := _make_horizontal_split(660)
	root.add_child(split)

	host._hierarchy_path_label = Label.new()
	host._hierarchy_path_label.text = "Selected: <none>"
	host._hierarchy_path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._hierarchy_path_label.modulate = Color(1.0, 1.0, 1.0, 0.8)

	host._pick_target_label = Label.new()
	host._pick_target_label.text = "Pick: inactive"
	host._pick_target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._pick_target_label.modulate = Color(1.0, 1.0, 1.0, 0.68)

	host._hierarchy_tree = Tree.new()
	host._hierarchy_tree.columns = 1
	host._hierarchy_tree.hide_root = false
	host._hierarchy_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._hierarchy_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._hierarchy_tree.item_selected.connect(Callable(host, "_on_hierarchy_item_selected"))
	host._hierarchy_tree.item_activated.connect(Callable(host, "_on_hierarchy_item_activated"))
	split.add_child(_make_panel_shell("Scene Tree", host._hierarchy_tree))

	var side_column := VBoxContainer.new()
	side_column.custom_minimum_size = Vector2(300.0, 0.0)
	side_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_column.add_theme_constant_override("separation", 8)
	split.add_child(side_column)

	side_column.add_child(_make_panel_shell("Selection", host._hierarchy_path_label))
	side_column.add_child(_make_panel_shell("Pick Target", host._pick_target_label))

	var hint_label := Label.new()
	hint_label.text = "Tip: use Start Pick to select UI or world objects directly, then jump straight into the inspector."
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.modulate = Color(1.0, 1.0, 1.0, 0.62)
	side_column.add_child(_make_panel_shell("Workflow", hint_label))

	return root


static func _build_search_tab(host) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 6)
	root.add_child(input_row)

	host._search_query_edit = LineEdit.new()
	host._search_query_edit.placeholder_text = "Search nodes by name, class, path, or group..."
	host._search_query_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_row.add_child(host._search_query_edit)

	host._search_mode = OptionButton.new()
	host._search_mode.add_item("Any", 0)
	host._search_mode.add_item("Name", 1)
	host._search_mode.add_item("Class", 2)
	host._search_mode.add_item("Path", 3)
	host._search_mode.add_item("Group", 4)
	host._search_mode.add_item("Script", 5)
	host._search_mode.add_item("Method", 6)
	host._search_mode.add_item("Property", 7)
	host._search_mode.select(0)
	input_row.add_child(host._search_mode)

	input_row.add_child(_make_button("Search", Callable(host, "_on_search_pressed")))

	host._search_selected_scope_check = CheckBox.new()
	host._search_selected_scope_check.text = "Selected Subtree"
	var action_row := _make_action_flow()
	root.add_child(action_row)
	action_row.add_child(_make_button("Copy Path", Callable(host, "_on_copy_selected_path_pressed")))
	action_row.add_child(_make_button("Open Inspector", Callable(host, "_on_open_inspector_pressed")))
	action_row.add_child(host._search_selected_scope_check)

	var quick_row := _make_action_flow()
	root.add_child(quick_row)
	for group_name in QUICK_GROUPS:
		quick_row.add_child(_make_group_button(host, group_name))

	host._search_results = ItemList.new()
	host._search_results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._search_results.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._search_results.item_selected.connect(Callable(host, "_on_search_result_selected"))
	host._search_results.item_activated.connect(Callable(host, "_on_search_result_activated"))
	root.add_child(_make_panel_shell("Search Results", host._search_results))

	return root


static func _build_inspector_tab(host) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	root.add_child(row1)

	host._inspector_path_edit = LineEdit.new()
	host._inspector_path_edit.editable = false
	host._inspector_path_edit.placeholder_text = "No node selected"
	host._inspector_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(host._inspector_path_edit)
	row1.add_child(_make_button("Copy Path", Callable(host, "_on_copy_selected_path_pressed")))
	row1.add_child(_make_button("Select Parent", Callable(host, "_on_select_parent_pressed")))
	row1.add_child(_make_button("Select Scene", Callable(host, "_on_select_scene_root_pressed")))

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	root.add_child(row2)

	host._property_filter_edit = LineEdit.new()
	host._property_filter_edit.placeholder_text = "Property filter..."
	host._property_filter_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._property_filter_edit.text_changed.connect(func(_text: String) -> void: host._refresh_property_tree(host._get_selected_node()))
	row2.add_child(host._property_filter_edit)

	host._property_changed_only_check = CheckBox.new()
	host._property_changed_only_check.text = "Changed Only"
	host._property_changed_only_check.toggled.connect(func(_pressed: bool) -> void: host._refresh_property_tree(host._get_selected_node()))
	row2.add_child(host._property_changed_only_check)

	row2.add_child(_make_button("Refresh Inspector", Callable(host, "_on_refresh_inspector_pressed")))
	row2.add_child(_make_button("Copy Summary", Callable(host, "_on_copy_inspector_summary_pressed")))

	var split := _make_horizontal_split(500)
	root.add_child(split)

	host._property_tree = Tree.new()
	host._property_tree.columns = 3
	host._property_tree.column_titles_visible = true
	host._property_tree.hide_root = true
	host._property_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._property_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._property_tree.item_selected.connect(Callable(host, "_on_property_tree_item_selected"))
	host._property_tree.item_activated.connect(Callable(host, "_on_property_tree_item_activated"))
	split.add_child(_make_panel_shell("Properties", host._property_tree))

	var right_split := _make_vertical_split(260)
	split.add_child(right_split)

	var info_tabs := TabContainer.new()
	info_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_split.add_child(info_tabs)

	host._inspector_meta = RichTextLabel.new()
	host._inspector_meta.bbcode_enabled = false
	host._inspector_meta.fit_content = false
	host._inspector_meta.scroll_active = true
	host._inspector_meta.selection_enabled = true
	host._inspector_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._inspector_meta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_add_tab(info_tabs, "Summary", _make_panel_shell("", host._inspector_meta))

	host._inspector_watch_view = RichTextLabel.new()
	host._inspector_watch_view.bbcode_enabled = false
	host._inspector_watch_view.fit_content = false
	host._inspector_watch_view.scroll_active = true
	host._inspector_watch_view.selection_enabled = true
	host._inspector_watch_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._inspector_watch_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_add_tab(info_tabs, "Watch", _make_panel_shell("", host._inspector_watch_view))

	host._resource_meta = RichTextLabel.new()
	host._resource_meta.bbcode_enabled = false
	host._resource_meta.fit_content = false
	host._resource_meta.scroll_active = true
	host._resource_meta.selection_enabled = true
	host._resource_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._resource_meta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_add_tab(info_tabs, "Resource", _make_panel_shell("", host._resource_meta))

	var editor_stack := VBoxContainer.new()
	editor_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_stack.add_theme_constant_override("separation", 8)
	right_split.add_child(editor_stack)

	var property_panel := VBoxContainer.new()
	property_panel.add_theme_constant_override("separation", 6)

	var property_head := HBoxContainer.new()
	property_head.add_theme_constant_override("separation", 6)
	property_panel.add_child(property_head)

	host._property_name_edit = LineEdit.new()
	host._property_name_edit.placeholder_text = "Property name"
	host._property_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._property_name_edit.text_changed.connect(Callable(host, "_on_property_name_text_changed"))
	property_head.add_child(host._property_name_edit)

	host._property_type_option = OptionButton.new()
	host._property_type_option.add_item("Auto", 0)
	host._property_type_option.add_item("Bool", 1)
	host._property_type_option.add_item("Int", 2)
	host._property_type_option.add_item("Float", 3)
	host._property_type_option.add_item("String", 4)
	host._property_type_option.add_item("Vector2", 5)
	host._property_type_option.add_item("Vector3", 6)
	host._property_type_option.add_item("Color", 7)
	host._property_type_option.add_item("NodePath", 8)
	host._property_type_option.add_item("Array", 9)
	host._property_type_option.add_item("Dictionary", 10)
	property_head.add_child(host._property_type_option)

	host._property_value_edit = TextEdit.new()
	host._property_value_edit.placeholder_text = "Property value"
	host._property_value_edit.custom_minimum_size = Vector2(0.0, 118.0)
	host._property_value_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	host._property_value_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._property_value_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	property_panel.add_child(host._property_value_edit)

	var property_actions := _make_action_flow()
	property_panel.add_child(property_actions)
	property_actions.add_child(_make_button("Pull", Callable(host, "_on_pull_property_pressed")))
	property_actions.add_child(_make_button("Apply", Callable(host, "_on_apply_property_pressed")))
	property_actions.add_child(_make_button("Copy Path", Callable(host, "_on_copy_property_name_pressed")))
	property_actions.add_child(_make_button("Copy Value", Callable(host, "_on_copy_property_value_pressed")))
	property_actions.add_child(_make_button("Copy Type", Callable(host, "_on_copy_property_type_pressed")))

	host._property_pin_button = _make_button("Pin", Callable(host, "_on_toggle_property_pin_pressed"))
	property_actions.add_child(host._property_pin_button)

	host._property_watch_button = _make_button("Watch", Callable(host, "_on_toggle_property_watch_pressed"))
	property_actions.add_child(host._property_watch_button)

	host._property_revert_button = _make_button("Revert", Callable(host, "_on_revert_property_pressed"))
	property_actions.add_child(host._property_revert_button)

	editor_stack.add_child(_make_panel_shell("Property Editor", property_panel))

	var method_panel := VBoxContainer.new()
	method_panel.add_theme_constant_override("separation", 6)

	var method_inputs := HBoxContainer.new()
	method_inputs.add_theme_constant_override("separation", 6)
	method_panel.add_child(method_inputs)

	host._method_name_edit = LineEdit.new()
	host._method_name_edit.placeholder_text = "Method name"
	host._method_name_edit.custom_minimum_size = Vector2(190.0, 0.0)
	host._method_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	method_inputs.add_child(host._method_name_edit)

	host._method_use_arg_check = CheckBox.new()
	host._method_use_arg_check.text = "Use Arg"
	method_inputs.add_child(host._method_use_arg_check)

	host._method_arg_type_option = OptionButton.new()
	host._method_arg_type_option.add_item("Auto", 0)
	host._method_arg_type_option.add_item("Bool", 1)
	host._method_arg_type_option.add_item("Int", 2)
	host._method_arg_type_option.add_item("Float", 3)
	host._method_arg_type_option.add_item("String", 4)
	host._method_arg_type_option.add_item("Vector2", 5)
	host._method_arg_type_option.add_item("Vector3", 6)
	method_inputs.add_child(host._method_arg_type_option)

	host._method_arg_edit = LineEdit.new()
	host._method_arg_edit.placeholder_text = "Optional argument"
	host._method_arg_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	method_inputs.add_child(host._method_arg_edit)

	var method_actions := _make_action_flow()
	method_panel.add_child(method_actions)
	method_actions.add_child(_make_button("Call Method", Callable(host, "_on_call_method_pressed")))

	editor_stack.add_child(_make_panel_shell("Method Runner", method_panel))

	return root


static func _build_world_tab(host) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var selected_row := HBoxContainer.new()
	selected_row.add_theme_constant_override("separation", 6)
	root.add_child(selected_row)

	host._world_selected_path_edit = LineEdit.new()
	host._world_selected_path_edit.editable = false
	host._world_selected_path_edit.placeholder_text = "No node selected"
	host._world_selected_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selected_row.add_child(host._world_selected_path_edit)
	selected_row.add_child(_make_button("Copy Path", Callable(host, "_on_copy_selected_path_pressed")))
	selected_row.add_child(_make_button("Pull Selected", Callable(host, "_on_pull_transform_pressed")))

	var jump_row := HBoxContainer.new()
	jump_row.add_theme_constant_override("separation", 6)
	root.add_child(jump_row)

	host._world_jump_path_edit = LineEdit.new()
	host._world_jump_path_edit.placeholder_text = "/root/Map/..."
	host._world_jump_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jump_row.add_child(host._world_jump_path_edit)
	jump_row.add_child(_make_button("Select Path", Callable(host, "_on_select_path_pressed")))
	jump_row.add_child(_make_button("Select Parent", Callable(host, "_on_select_parent_pressed")))
	jump_row.add_child(_make_button("Select Scene", Callable(host, "_on_select_scene_root_pressed")))

	var reparent_row := HBoxContainer.new()
	reparent_row.add_theme_constant_override("separation", 6)
	root.add_child(reparent_row)

	host._world_reparent_path_edit = LineEdit.new()
	host._world_reparent_path_edit.placeholder_text = "Reparent target path"
	host._world_reparent_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reparent_row.add_child(host._world_reparent_path_edit)
	reparent_row.add_child(_make_button("Reparent", Callable(host, "_on_reparent_selected_pressed")))

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	root.add_child(name_row)

	host._world_name_edit = LineEdit.new()
	host._world_name_edit.placeholder_text = "Selected node name"
	host._world_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(host._world_name_edit)
	name_row.add_child(_make_button("Apply Name", Callable(host, "_on_apply_name_pressed")))

	host._world_visible_check = CheckBox.new()
	host._world_visible_check.text = "Visible"
	name_row.add_child(host._world_visible_check)
	name_row.add_child(_make_button("Apply Visible", Callable(host, "_on_apply_visible_pressed")))

	host._world_mode_label = Label.new()
	host._world_mode_label.text = "Mode: no transformable node selected."
	host._world_mode_label.modulate = Color(1.0, 1.0, 1.0, 0.8)
	root.add_child(host._world_mode_label)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	root.add_child(grid)

	grid.add_child(_grid_header(""))
	grid.add_child(_grid_header("X"))
	grid.add_child(_grid_header("Y"))
	grid.add_child(_grid_header("Z"))

	grid.add_child(_grid_header("Position"))
	host._world_pos_x = _make_spinbox()
	host._world_pos_y = _make_spinbox()
	host._world_pos_z = _make_spinbox()
	grid.add_child(host._world_pos_x)
	grid.add_child(host._world_pos_y)
	grid.add_child(host._world_pos_z)

	grid.add_child(_grid_header("Rotation"))
	host._world_rot_x = _make_spinbox(-3600.0, 3600.0, 0.5)
	host._world_rot_y = _make_spinbox(-3600.0, 3600.0, 0.5)
	host._world_rot_z = _make_spinbox(-3600.0, 3600.0, 0.5)
	grid.add_child(host._world_rot_x)
	grid.add_child(host._world_rot_y)
	grid.add_child(host._world_rot_z)

	grid.add_child(_grid_header("Scale"))
	host._world_scale_x = _make_spinbox(-1000.0, 1000.0, 0.1)
	host._world_scale_y = _make_spinbox(-1000.0, 1000.0, 0.1)
	host._world_scale_z = _make_spinbox(-1000.0, 1000.0, 0.1)
	grid.add_child(host._world_scale_x)
	grid.add_child(host._world_scale_y)
	grid.add_child(host._world_scale_z)

	var action_row := _make_action_flow()
	root.add_child(action_row)
	action_row.add_child(_make_button("Apply Transform", Callable(host, "_on_apply_transform_pressed")))

	var step_label := Label.new()
	step_label.text = "Step"
	action_row.add_child(step_label)

	host._world_step_spin = _make_spinbox(0.01, 1000.0, 0.1)
	host._world_step_spin.value = 1.0
	host._world_step_spin.custom_minimum_size = Vector2(90.0, 0.0)
	action_row.add_child(host._world_step_spin)

	action_row.add_child(_make_button("X-", func() -> void: host._nudge_selected("x", -1.0)))
	action_row.add_child(_make_button("X+", func() -> void: host._nudge_selected("x", 1.0)))
	action_row.add_child(_make_button("Y-", func() -> void: host._nudge_selected("y", -1.0)))
	action_row.add_child(_make_button("Y+", func() -> void: host._nudge_selected("y", 1.0)))
	action_row.add_child(_make_button("Z-", func() -> void: host._nudge_selected("z", -1.0)))
	action_row.add_child(_make_button("Z+", func() -> void: host._nudge_selected("z", 1.0)))

	var destructive_row := _make_action_flow()
	root.add_child(destructive_row)
	destructive_row.add_child(_make_button("Duplicate Selected", Callable(host, "_on_duplicate_selected_pressed")))
	destructive_row.add_child(_make_button("Delete Selected", Callable(host, "_on_delete_selected_pressed")))

	var safety_row := _make_action_flow()
	root.add_child(safety_row)

	host._undo_button = _make_button("Undo", Callable(host, "_on_undo_pressed"))
	safety_row.add_child(host._undo_button)

	host._redo_button = _make_button("Redo", Callable(host, "_on_redo_pressed"))
	safety_row.add_child(host._redo_button)

	safety_row.add_child(_make_button("Revert Selected", Callable(host, "_on_revert_selected_object_pressed")))
	safety_row.add_child(_make_button("Snapshot user://", Callable(host, "_on_snapshot_user_pressed")))

	host._auto_snapshot_danger_check = CheckBox.new()
	host._auto_snapshot_danger_check.text = "Auto Snapshot"
	host._auto_snapshot_danger_check.button_pressed = true
	safety_row.add_child(host._auto_snapshot_danger_check)

	host._lock_important_check = CheckBox.new()
	host._lock_important_check.text = "Lock Important"
	host._lock_important_check.button_pressed = true
	safety_row.add_child(host._lock_important_check)

	var spawn_row := HBoxContainer.new()
	spawn_row.add_theme_constant_override("separation", 6)
	root.add_child(spawn_row)

	host._spawn_path_edit = LineEdit.new()
	host._spawn_path_edit.placeholder_text = "res://Path/To/Scene.tscn"
	host._spawn_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spawn_row.add_child(host._spawn_path_edit)
	spawn_row.add_child(_make_button("Spawn Under Scene", Callable(host, "_on_spawn_scene_root_pressed")))
	spawn_row.add_child(_make_button("Spawn Under Selected", Callable(host, "_on_spawn_selected_pressed")))

	var helper_row := _make_action_flow()
	root.add_child(helper_row)
	helper_row.add_child(_make_button("New Node3D", Callable(host, "_on_create_helper_pressed").bind("Node3D", false)))
	helper_row.add_child(_make_button("New Marker3D", Callable(host, "_on_create_helper_pressed").bind("Marker3D", false)))
	helper_row.add_child(_make_button("New Node2D", Callable(host, "_on_create_helper_pressed").bind("Node2D", false)))
	helper_row.add_child(_make_button("New Control", Callable(host, "_on_create_helper_pressed").bind("Control", false)))
	helper_row.add_child(_make_button("New Label", Callable(host, "_on_create_helper_pressed").bind("Label", false)))

	return root


static func _build_preview_tab(host) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var action_row := _make_action_flow()
	root.add_child(action_row)
	action_row.add_child(_make_button("From Selected Node", Callable(host, "_on_preview_selected_node_pressed")))
	action_row.add_child(_make_button("From Selected Property", Callable(host, "_on_preview_selected_property_pressed")))
	action_row.add_child(_make_button("Load Path", Callable(host, "_on_preview_load_path_pressed")))
	action_row.add_child(_make_button("Frame", Callable(host, "_on_preview_frame_pressed")))
	action_row.add_child(_make_button("Reset Camera", Callable(host, "_on_preview_reset_camera_pressed")))
	action_row.add_child(_make_button("Focus Entry", Callable(host, "_on_preview_focus_entry_pressed")))
	action_row.add_child(_make_button("Copy Report", Callable(host, "_on_preview_copy_report_pressed")))
	action_row.add_child(_make_button("Clear", Callable(host, "_on_preview_clear_pressed")))

	var toggle_row := _make_action_flow()
	root.add_child(toggle_row)

	host._preview_markers_check = CheckBox.new()
	host._preview_markers_check.text = "Markers"
	host._preview_markers_check.button_pressed = true
	host._preview_markers_check.toggled.connect(Callable(host, "_on_preview_markers_toggled"))
	toggle_row.add_child(host._preview_markers_check)

	host._preview_floor_check = CheckBox.new()
	host._preview_floor_check.text = "Floor"
	host._preview_floor_check.button_pressed = true
	host._preview_floor_check.toggled.connect(Callable(host, "_on_preview_floor_toggled"))
	toggle_row.add_child(host._preview_floor_check)

	host._preview_axes_check = CheckBox.new()
	host._preview_axes_check.text = "Axes"
	host._preview_axes_check.button_pressed = true
	host._preview_axes_check.toggled.connect(Callable(host, "_on_preview_axes_toggled"))
	toggle_row.add_child(host._preview_axes_check)

	host._preview_spin_check = CheckBox.new()
	host._preview_spin_check.text = "Auto Spin"
	host._preview_spin_check.toggled.connect(Callable(host, "_on_preview_spin_toggled"))
	toggle_row.add_child(host._preview_spin_check)

	var path_row := HBoxContainer.new()
	path_row.add_theme_constant_override("separation", 6)
	root.add_child(path_row)

	host._preview_source_path_edit = LineEdit.new()
	host._preview_source_path_edit.placeholder_text = "res://Items/.../Item.tres or res://Scenes/.../Scene.tscn"
	host._preview_source_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_row.add_child(host._preview_source_path_edit)

	var split := _make_horizontal_split(380)
	root.add_child(split)

	var left_column := VBoxContainer.new()
	left_column.custom_minimum_size = Vector2(320.0, 0.0)
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 8)
	split.add_child(left_column)

	var summary_box := HBoxContainer.new()
	summary_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_box.add_theme_constant_override("separation", 10)

	host._preview_icon_rect = TextureRect.new()
	host._preview_icon_rect.custom_minimum_size = Vector2(108.0, 108.0)
	host._preview_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host._preview_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	summary_box.add_child(_make_panel_shell("Icon", host._preview_icon_rect))

	host._preview_summary = RichTextLabel.new()
	host._preview_summary.bbcode_enabled = false
	host._preview_summary.fit_content = false
	host._preview_summary.scroll_active = true
	host._preview_summary.selection_enabled = true
	host._preview_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._preview_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_box.add_child(_make_panel_shell("Summary", host._preview_summary))
	left_column.add_child(summary_box)

	host._preview_scene_report = RichTextLabel.new()
	host._preview_scene_report.bbcode_enabled = false
	host._preview_scene_report.fit_content = false
	host._preview_scene_report.scroll_active = true
	host._preview_scene_report.selection_enabled = true
	host._preview_scene_report.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._preview_scene_report.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_child(_make_panel_shell("Scene Readout", host._preview_scene_report))

	host._preview_special_list = ItemList.new()
	host._preview_special_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._preview_special_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._preview_special_list.item_selected.connect(Callable(host, "_on_preview_special_selected"))
	host._preview_special_list.item_activated.connect(Callable(host, "_on_preview_special_activated"))
	left_column.add_child(_make_panel_shell("Special Nodes", host._preview_special_list))

	host._preview_viewport = PreviewViewport.new()
	split.add_child(_make_panel_shell("Live Preview", host._preview_viewport))

	return root


static func _build_files_tab(host) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var actions := _make_action_flow()
	root.add_child(actions)
	actions.add_child(_make_button("Refresh Files", Callable(host, "_on_refresh_files_pressed")))
	actions.add_child(_make_button("Snapshot user://", Callable(host, "_on_snapshot_user_pressed")))
	actions.add_child(_make_button("Copy Preview", Callable(host, "_on_copy_preview_pressed")))
	actions.add_child(_make_button("Copy user:// Path", Callable(host, "_on_copy_user_file_path_pressed")))
	actions.add_child(_make_button("Copy Global Path", Callable(host, "_on_copy_global_file_path_pressed")))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	root.add_child(row)
	host._file_filter_edit = LineEdit.new()
	host._file_filter_edit.placeholder_text = "Filter files..."
	host._file_filter_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(host._file_filter_edit)

	var split := _make_horizontal_split(340)
	root.add_child(split)

	host._file_list = ItemList.new()
	host._file_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._file_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._file_list.item_selected.connect(Callable(host, "_on_file_item_selected"))
	split.add_child(_make_panel_shell("user:// Files", host._file_list))

	var right := _make_vertical_split(120)
	split.add_child(right)

	host._file_meta_label = Label.new()
	host._file_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host._file_meta_label.modulate = Color(1.0, 1.0, 1.0, 0.8)
	right.add_child(_make_panel_shell("File Info", host._file_meta_label))

	host._file_preview = TextEdit.new()
	host._file_preview.editable = false
	host._file_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._file_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_make_panel_shell("Preview", host._file_preview))

	return root


static func _build_runtime_tab(host) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var top_row := _make_action_flow()
	root.add_child(top_row)
	top_row.add_child(_make_button("Pull Runtime", Callable(host, "_on_pull_runtime_pressed")))
	top_row.add_child(_make_button("Apply Runtime", Callable(host, "_on_apply_runtime_pressed")))
	top_row.add_child(_make_button("Probe Msg", Callable(host, "_on_probe_pressed")))
	top_row.add_child(_make_button("Save Character", Callable(host, "_on_save_character_pressed")))
	top_row.add_child(_make_button("Load Character", Callable(host, "_on_load_character_pressed")))
	top_row.add_child(_make_button("Save World", Callable(host, "_on_save_world_pressed")))
	top_row.add_child(_make_button("Load World", Callable(host, "_on_load_world_pressed")))
	top_row.add_child(_make_button("Update Progression", Callable(host, "_on_update_progression_pressed")))

	var engine_row := HBoxContainer.new()
	engine_row.add_theme_constant_override("separation", 6)
	root.add_child(engine_row)

	var engine_label := Label.new()
	engine_label.text = "Engine"
	engine_row.add_child(engine_label)

	host._time_scale_spin = _make_spinbox(0.0, 20.0, 0.1)
	host._time_scale_spin.custom_minimum_size = Vector2(120.0, 0.0)
	engine_row.add_child(host._time_scale_spin)

	host._tree_paused_check = CheckBox.new()
	host._tree_paused_check.text = "Tree Paused"
	engine_row.add_child(host._tree_paused_check)

	host._runtime_message_edit = LineEdit.new()
	host._runtime_message_edit.placeholder_text = "Custom loader message"
	host._runtime_message_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	engine_row.add_child(host._runtime_message_edit)
	engine_row.add_child(_make_button("Send Message", Callable(host, "_on_send_runtime_message_pressed")))

	var simulation_grid := GridContainer.new()
	simulation_grid.columns = 4
	simulation_grid.add_theme_constant_override("h_separation", 8)
	simulation_grid.add_theme_constant_override("v_separation", 6)
	root.add_child(simulation_grid)

	simulation_grid.add_child(_grid_header("Sim Day"))
	simulation_grid.add_child(_grid_header("Sim Time"))
	simulation_grid.add_child(_grid_header("Season"))
	simulation_grid.add_child(_grid_header("Weather"))

	host._simulation_day_spin = _make_spinbox(-9999.0, 9999.0, 1.0)
	host._simulation_time_spin = _make_spinbox(-9999.0, 9999.0, 0.1)
	host._simulation_season_spin = _make_spinbox(-99.0, 99.0, 1.0)
	host._simulation_weather_spin = _make_spinbox(-99.0, 99.0, 1.0)
	simulation_grid.add_child(host._simulation_day_spin)
	simulation_grid.add_child(host._simulation_time_spin)
	simulation_grid.add_child(host._simulation_season_spin)
	simulation_grid.add_child(host._simulation_weather_spin)

	simulation_grid.add_child(_grid_header("Weather Time"))
	simulation_grid.add_child(_grid_header("Simulate"))
	simulation_grid.add_child(_grid_header(""))
	simulation_grid.add_child(_grid_header(""))

	host._simulation_weather_time_spin = _make_spinbox(-9999.0, 9999.0, 0.1)
	simulation_grid.add_child(host._simulation_weather_time_spin)
	host._simulation_simulate_check = CheckBox.new()
	host._simulation_simulate_check.text = "Enabled"
	simulation_grid.add_child(host._simulation_simulate_check)
	simulation_grid.add_child(Control.new())
	simulation_grid.add_child(Control.new())

	var game_row := _make_action_flow()
	root.add_child(game_row)

	host._game_menu_check = CheckBox.new()
	host._game_menu_check.text = "menu"
	game_row.add_child(host._game_menu_check)
	host._game_shelter_check = CheckBox.new()
	host._game_shelter_check.text = "shelter"
	game_row.add_child(host._game_shelter_check)
	host._game_permadeath_check = CheckBox.new()
	host._game_permadeath_check.text = "permadeath"
	game_row.add_child(host._game_permadeath_check)
	host._game_tutorial_check = CheckBox.new()
	host._game_tutorial_check.text = "tutorial"
	game_row.add_child(host._game_tutorial_check)
	host._game_freeze_check = CheckBox.new()
	host._game_freeze_check.text = "freeze"
	game_row.add_child(host._game_freeze_check)
	host._game_compatibility_check = CheckBox.new()
	host._game_compatibility_check.text = "compatibility"
	game_row.add_child(host._game_compatibility_check)

	return root


static func _build_groups_tab(host) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	root.add_child(row)

	host._group_filter_edit = LineEdit.new()
	host._group_filter_edit.placeholder_text = "Filter group names..."
	host._group_filter_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(host._group_filter_edit)
	row.add_child(_make_button("Refresh Groups", Callable(host, "_on_refresh_groups_pressed")))
	row.add_child(_make_button("Copy Group Paths", Callable(host, "_on_copy_group_paths_pressed")))

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	root.add_child(row2)

	host._group_name_edit = LineEdit.new()
	host._group_name_edit.placeholder_text = "Group name"
	host._group_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(host._group_name_edit)
	row2.add_child(_make_button("Add Selected", Callable(host, "_on_add_selected_to_group_pressed")))
	row2.add_child(_make_button("Remove Selected", Callable(host, "_on_remove_selected_from_group_pressed")))

	host._group_status_label = Label.new()
	host._group_status_label.modulate = Color(1.0, 1.0, 1.0, 0.78)
	root.add_child(host._group_status_label)

	var split := _make_horizontal_split(300)
	root.add_child(split)

	host._group_list = ItemList.new()
	host._group_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._group_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._group_list.item_selected.connect(Callable(host, "_on_group_selected"))
	split.add_child(_make_panel_shell("Groups", host._group_list))

	host._group_members = ItemList.new()
	host._group_members.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._group_members.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._group_members.item_selected.connect(Callable(host, "_on_group_member_selected"))
	host._group_members.item_activated.connect(Callable(host, "_on_group_member_activated"))
	split.add_child(_make_panel_shell("Members", host._group_members))

	return root


static func _build_diagnostics_tab(host) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var row := _make_action_flow()
	root.add_child(row)
	row.add_child(_make_button("Refresh Diagnostics", Callable(host, "_on_refresh_diagnostics_pressed")))
	row.add_child(_make_button("Copy Report", Callable(host, "_on_copy_diagnostics_pressed")))
	row.add_child(_make_button("Dump Report", Callable(host, "_on_dump_diagnostics_pressed")))
	row.add_child(_make_button("Select Loader", Callable(host, "_on_select_loader_pressed")))

	var split := _make_horizontal_split(330)
	root.add_child(split)

	var left := _make_vertical_split(260)
	split.add_child(left)

	host._diagnostics_mod_list = ItemList.new()
	host._diagnostics_mod_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._diagnostics_mod_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._diagnostics_mod_list.item_selected.connect(Callable(host, "_on_diagnostics_mod_selected"))
	left.add_child(_make_panel_shell("Loaded Mods", host._diagnostics_mod_list))

	host._diagnostics_issue_list = ItemList.new()
	host._diagnostics_issue_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._diagnostics_issue_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._diagnostics_issue_list.item_selected.connect(Callable(host, "_on_diagnostics_issue_selected"))
	left.add_child(_make_panel_shell("Issues", host._diagnostics_issue_list))

	var right := _make_vertical_split(290)
	split.add_child(right)

	host._diagnostics_report = RichTextLabel.new()
	host._diagnostics_report.bbcode_enabled = false
	host._diagnostics_report.fit_content = false
	host._diagnostics_report.scroll_active = true
	host._diagnostics_report.selection_enabled = true
	host._diagnostics_report.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._diagnostics_report.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_make_panel_shell("Diagnostics Report", host._diagnostics_report))

	host._diagnostics_detail = RichTextLabel.new()
	host._diagnostics_detail.bbcode_enabled = false
	host._diagnostics_detail.fit_content = false
	host._diagnostics_detail.scroll_active = true
	host._diagnostics_detail.selection_enabled = true
	host._diagnostics_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._diagnostics_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_make_panel_shell("Detail", host._diagnostics_detail))

	return root


static func _build_watch_tab(host) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var row := _make_action_flow()
	root.add_child(row)
	row.add_child(_make_button("Bookmark Selected", Callable(host, "_on_bookmark_selected_pressed")))
	row.add_child(_make_button("Watch Selected", Callable(host, "_on_watch_selected_pressed")))
	row.add_child(_make_button("Remove Bookmark", Callable(host, "_on_remove_bookmark_pressed")))
	row.add_child(_make_button("Remove Watch", Callable(host, "_on_remove_watch_pressed")))
	row.add_child(_make_button("Copy Watch Report", Callable(host, "_on_copy_watch_report_pressed")))

	var split := _make_vertical_split(260)
	root.add_child(split)

	var top_split := _make_horizontal_split(380)
	split.add_child(top_split)

	host._bookmark_list = ItemList.new()
	host._bookmark_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._bookmark_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._bookmark_list.item_selected.connect(Callable(host, "_on_bookmark_selected"))
	host._bookmark_list.item_activated.connect(Callable(host, "_on_bookmark_activated"))
	top_split.add_child(_make_panel_shell("Bookmarks", host._bookmark_list))

	host._watch_list = ItemList.new()
	host._watch_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._watch_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._watch_list.item_selected.connect(Callable(host, "_on_watch_item_selected"))
	host._watch_list.item_activated.connect(Callable(host, "_on_watch_item_activated"))
	top_split.add_child(_make_panel_shell("Watch List", host._watch_list))

	host._history_list = ItemList.new()
	host._history_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._history_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._history_list.item_selected.connect(Callable(host, "_on_history_item_selected"))
	host._history_list.item_activated.connect(Callable(host, "_on_history_item_activated"))
	split.add_child(_make_panel_shell("Selection History", host._history_list))

	return root


static func _build_log_tab(host) -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)

	var row := _make_action_flow()
	root.add_child(row)
	row.add_child(_make_button("Undo", Callable(host, "_on_undo_pressed")))
	row.add_child(_make_button("Redo", Callable(host, "_on_redo_pressed")))
	row.add_child(_make_button("Copy Log", Callable(host, "_on_copy_log_pressed")))
	row.add_child(_make_button("Clear Log", Callable(host, "_on_clear_log_pressed")))
	row.add_child(_make_button("Clear Tx", Callable(host, "_on_clear_transactions_pressed")))

	var split := _make_horizontal_split(360)
	root.add_child(split)

	host._transaction_list = ItemList.new()
	host._transaction_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._transaction_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._transaction_list.item_selected.connect(Callable(host, "_on_transaction_selected"))
	split.add_child(_make_panel_shell("Transactions", host._transaction_list))

	var right := _make_vertical_split(220)
	split.add_child(right)

	host._transaction_detail = RichTextLabel.new()
	host._transaction_detail.bbcode_enabled = false
	host._transaction_detail.fit_content = false
	host._transaction_detail.scroll_active = true
	host._transaction_detail.selection_enabled = true
	host._transaction_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._transaction_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_make_panel_shell("Transaction Detail", host._transaction_detail))

	host._log_view = TextEdit.new()
	host._log_view.editable = false
	host._log_view.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	host._log_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host._log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_make_panel_shell("Toolkit Log", host._log_view))

	return root


static func _add_tab(tabs: TabContainer, title: String, control: Control) -> void:
	tabs.add_child(control)
	tabs.set_tab_title(tabs.get_tab_count() - 1, title)


static func _make_button(text: String, callable: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 30.0)
	button.pressed.connect(callable)
	return button


static func _make_action_flow() -> HFlowContainer:
	var row := HFlowContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	return row


static func _make_group_button(host, group_name: String) -> Button:
	return _make_button(
		"Group: %s" % group_name,
		func() -> void:
			host._search_query_edit.text = group_name
			host._search_mode.select(4)
			host._run_search(true)
	)


static func _grid_header(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


static func _make_horizontal_split(offset: int) -> HSplitContainer:
	var split := HSplitContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = offset
	return split


static func _make_vertical_split(offset: int) -> VSplitContainer:
	var split := VSplitContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = offset
	return split


static func _make_panel_shell(title: String, content: Control) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", ToolkitTheme.make_section_style())

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	if title != "":
		var label := Label.new()
		label.text = title
		label.modulate = Color(1.0, 1.0, 1.0, 0.74)
		column.add_child(label)

	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(content)
	return panel


static func _make_spinbox(min_value: float = -100000.0, max_value: float = 100000.0, step: float = 0.1) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.allow_lesser = true
	spin.allow_greater = true
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spin
