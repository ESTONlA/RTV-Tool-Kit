extends RefCounted


static func find_control_target(root: Node, mouse_position: Vector2, skip: Callable = Callable()) -> Control:
	if root == null:
		return null
	return _find_control_target_recursive(root, mouse_position, skip)


static func find_world_target(viewport: Viewport, mouse_position: Vector2, skip: Callable = Callable()) -> Node:
	if viewport == null:
		return null

	var camera := viewport.get_camera_3d()
	if camera == null:
		return null

	var world := camera.get_world_3d()
	if world == null:
		return null

	var query := PhysicsRayQueryParameters3D.new()
	query.from = camera.project_ray_origin(mouse_position)
	query.to = query.from + camera.project_ray_normal(mouse_position) * 5000.0
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null

	var collider = hit.get("collider")
	if collider is Node:
		return _normalize_target(collider, skip)
	return null


static func find_nearest_script_owner(node: Node, skip: Callable = Callable()) -> Node:
	var cursor := node
	while cursor != null:
		if not _should_skip(cursor, skip) and cursor.get_script() != null:
			return cursor
		cursor = cursor.get_parent()

	cursor = node
	while cursor != null:
		if cursor.owner != null and not _should_skip(cursor.owner, skip) and cursor.owner.get_script() != null:
			return cursor.owner
		cursor = cursor.get_parent()

	return null


static func _find_control_target_recursive(node: Node, mouse_position: Vector2, skip: Callable) -> Control:
	var best_match: Control = null
	if node is Control:
		var control := node as Control
		if _can_pick_control(control, mouse_position, skip):
			best_match = control

	for child in node.get_children():
		if child is Node:
			var nested := _find_control_target_recursive(child, mouse_position, skip)
			if nested != null:
				best_match = nested

	return best_match


static func _can_pick_control(control: Control, mouse_position: Vector2, skip: Callable) -> bool:
	if _should_skip(control, skip):
		return false
	if not control.is_visible_in_tree():
		return false
	if control.size.x <= 0.0 or control.size.y <= 0.0:
		return false
	return control.get_global_rect().has_point(mouse_position)


static func _normalize_target(node: Node, skip: Callable) -> Node:
	var cursor := node
	while cursor != null:
		if not _should_skip(cursor, skip):
			return cursor
		cursor = cursor.get_parent()
	return null


static func _should_skip(node: Node, skip: Callable) -> bool:
	return skip.is_valid() and bool(skip.call(node))
