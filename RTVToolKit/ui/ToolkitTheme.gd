extends RefCounted

const GAME_THEME_PATH := "res://UI/Themes/Theme.tres"
const WINDOW_STYLE_PATH := "res://UI/Buttons/Window.tres"
const TITLE_FONT_PATH := "res://Fonts/Lora-SemiBold.ttf"
const BODY_FONT_PATH := "res://Fonts/Lora-Regular.ttf"
const HEADER_ICON_PATH := "res://UI/Sprites/Icon_Testbench.png"
const RESIZE_GRIP_PATH := "res://UI/Sprites/Grabber.png"

static var _cached_theme: Theme
static var _cached_window_style: StyleBox
static var _cached_title_font: Font
static var _cached_body_font: Font
static var _cached_header_icon: Texture2D
static var _cached_resize_grip: Texture2D


static func load_game_theme() -> Theme:
	if _cached_theme != null:
		return _cached_theme

	var candidate = load(GAME_THEME_PATH)
	if candidate is Theme:
		_cached_theme = candidate
	else:
		_cached_theme = Theme.new()
	return _cached_theme


static func load_window_style() -> StyleBox:
	if _cached_window_style == null:
		var candidate = load(WINDOW_STYLE_PATH)
		if candidate is StyleBox:
			_cached_window_style = candidate
	return _cached_window_style


static func load_title_font() -> Font:
	if _cached_title_font == null:
		var candidate = load(TITLE_FONT_PATH)
		if candidate is Font:
			_cached_title_font = candidate
	return _cached_title_font


static func load_body_font() -> Font:
	if _cached_body_font == null:
		var candidate = load(BODY_FONT_PATH)
		if candidate is Font:
			_cached_body_font = candidate
	return _cached_body_font


static func load_header_icon() -> Texture2D:
	if _cached_header_icon == null:
		var candidate = load(HEADER_ICON_PATH)
		if candidate is Texture2D:
			_cached_header_icon = candidate
	return _cached_header_icon


static func load_resize_grip() -> Texture2D:
	if _cached_resize_grip == null:
		var candidate = load(RESIZE_GRIP_PATH)
		if candidate is Texture2D:
			_cached_resize_grip = candidate
	return _cached_resize_grip


static func make_window_style() -> StyleBox:
	var style_from_game := load_window_style()
	if style_from_game != null:
		return style_from_game.duplicate(true)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.050, 0.050, 0.050, 0.96)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.92, 0.92, 0.92, 0.14)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 18
	return style


static func make_header_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.090, 0.090, 0.090, 0.98)
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 1.0, 1.0, 0.08)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	return style


static func make_body_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.10)
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	return style


static func make_section_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.10, 0.72)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 1.0, 1.0, 0.08)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style


static func make_footer_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.10, 0.94)
	style.border_width_top = 1
	style.border_color = Color(1.0, 1.0, 1.0, 0.08)
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	return style


static func make_hint_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.03, 0.78)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 1.0, 1.0, 0.10)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	return style


static func make_pick_hint_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.85, 0.95, 1.0, 0.22)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style


static func make_pick_outline_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.60, 0.90, 1.0, 0.95)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style


static func make_pick_marker_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.60, 0.75, 0.28)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.78, 0.95, 1.0, 0.95)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	return style
