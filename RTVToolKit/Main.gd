extends CanvasLayer

const VERSION := "1.0.0"
const ToolkitWindow = preload("res://RTVToolKit/ui/ToolkitWindow.gd")
const ToolkitTheme = preload("res://RTVToolKit/ui/ToolkitTheme.gd")

var _window: Control
var _hint_panel: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_build_hint()
	_window = ToolkitWindow.new()
	add_child(_window)


func _build_hint() -> void:
	_hint_panel = PanelContainer.new()
	_hint_panel.anchor_left = 1.0
	_hint_panel.anchor_right = 1.0
	_hint_panel.offset_left = -228.0
	_hint_panel.offset_right = -18.0
	_hint_panel.offset_top = 12.0
	_hint_panel.offset_bottom = 42.0
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_panel.theme = ToolkitTheme.load_game_theme()
	_hint_panel.add_theme_stylebox_override("panel", ToolkitTheme.make_hint_style())
	add_child(_hint_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 6)
	_hint_panel.add_child(margin)

	var label := Label.new()
	label.text = "RTV Tool Kit   F8 open/close   F9 refresh"
	var font = ToolkitTheme.load_body_font()
	if font != null:
		label.add_theme_font_override("font", font)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color(1.0, 1.0, 1.0, 0.74)
	margin.add_child(label)
