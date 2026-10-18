class_name OSWindow
extends Panel

signal closed(window)
signal minimized(window)
signal focused(window)

const RESIZE_MARGIN: float = 8.0
const MIN_WINDOW_SIZE := Vector2(360.0, 240.0)

enum ResizeEdge { NONE, LEFT, RIGHT, TOP, BOTTOM, TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var resizing: bool = false
var resize_edge: ResizeEdge = ResizeEdge.NONE
var resize_start: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var original_size: Vector2 = Vector2.ZERO
var normal_position: Vector2 = Vector2.ZERO
var normal_size: Vector2 = Vector2.ZERO
var maximized: bool = false
var work_area: Rect2 = Rect2()

@onready var titlebar: Panel = $TitleBar
@onready var title_label: Label = $TitleBar/Title
@onready var app_icon_texture: TextureRect = $TitleBar/AppIconTexture
@onready var app_icon_fallback: Label = $TitleBar/AppIconFallback
@onready var content: ScrollContainer = $Content/ScrollContainer

func _ready() -> void:
	gui_input.connect(_on_root_gui_input)
	mouse_default_cursor_shape = Control.CURSOR_ARROW

func setup(title: String, app_icon: Texture2D = null) -> void:
	title_label.text = title
	app_icon_texture.texture = app_icon
	app_icon_texture.visible = app_icon != null
	app_icon_fallback.visible = app_icon == null
	app_icon_fallback.text = _fallback_app_icon(title)

func _fallback_app_icon(title: String) -> String:
	match title:
		"Configurações": return "⚙"
		"Arquivos": return "▤"
		"Extras": return "✦"
		"Sobre", "Sobre o sistema": return "i"
		"Empolium 2": return "E"
		_: return title.left(1)

func set_work_area(area: Rect2) -> void:
	work_area = area
	var minimum := Vector2(minf(MIN_WINDOW_SIZE.x, area.size.x), minf(MIN_WINDOW_SIZE.y, area.size.y))
	custom_minimum_size = minimum
	size = size.min(area.size).max(minimum)
	_clamp_to_work_area()

func set_content(node: Control) -> void:
	for child in content.get_children():
		child.queue_free()
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.position = Vector2.ZERO
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(node)
	call_deferred("_fit_content_minimum", node)

func _fit_content_minimum(node: Control) -> void:
	await get_tree().process_frame
	if not is_instance_valid(node) or node.get_child_count() == 0:
		return
	var app_content := node.get_child(0) as Control
	if app_content == null:
		return
	var insets := Vector2(
		maxf(0.0, app_content.offset_left - app_content.offset_right),
		maxf(0.0, app_content.offset_top - app_content.offset_bottom)
	)
	node.custom_minimum_size = app_content.get_combined_minimum_size() + insets

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var parent_node: Node = get_parent()
	if parent_node != null and parent_node.get_child_count() > 0 and parent_node.get_child(parent_node.get_child_count() - 1) != self:
		return
	if event is InputEventMouseMotion:
		if resizing:
			_apply_resize(get_global_mouse_position())
			get_viewport().set_input_as_handled()
		elif dragging and not maximized:
			global_position = get_global_mouse_position() - drag_offset
			_clamp_to_work_area()
			get_viewport().set_input_as_handled()
		elif not maximized and get_global_rect().has_point(get_global_mouse_position()):
			mouse_default_cursor_shape = _cursor_for_edge(_get_resize_edge(get_local_mouse_position()))
		else:
			mouse_default_cursor_shape = Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not maximized and get_global_rect().has_point(get_global_mouse_position()):
			var edge: ResizeEdge = _get_resize_edge(get_local_mouse_position())
			if edge != ResizeEdge.NONE:
				focused.emit(self)
				resizing = true
				resize_edge = edge
				resize_start = get_global_mouse_position()
				original_position = global_position
				original_size = size
				get_viewport().set_input_as_handled()
		elif not event.pressed:
			dragging = false
			if resizing:
				resizing = false
				resize_edge = ResizeEdge.NONE
				mouse_default_cursor_shape = Control.CURSOR_ARROW
				get_viewport().set_input_as_handled()

func _on_titlebar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			focused.emit(self)
			if not maximized and _get_resize_edge(get_local_mouse_position()) == ResizeEdge.NONE:
				dragging = true
				drag_offset = get_global_mouse_position() - global_position
				get_viewport().set_input_as_handled()
		else:
			dragging = false
	elif event is InputEventMouseMotion and not dragging and not maximized:
		titlebar.mouse_default_cursor_shape = _cursor_for_edge(_get_resize_edge(titlebar.position + event.position))

func _on_root_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		focused.emit(self)

func _get_resize_edge(local_pos: Vector2) -> ResizeEdge:
	if maximized:
		return ResizeEdge.NONE
	var on_left: bool = local_pos.x <= RESIZE_MARGIN
	var on_right: bool = local_pos.x >= size.x - RESIZE_MARGIN
	var on_top: bool = local_pos.y <= RESIZE_MARGIN
	var on_bottom: bool = local_pos.y >= size.y - RESIZE_MARGIN
	if on_top and on_left: return ResizeEdge.TOP_LEFT
	if on_top and on_right: return ResizeEdge.TOP_RIGHT
	if on_bottom and on_left: return ResizeEdge.BOTTOM_LEFT
	if on_bottom and on_right: return ResizeEdge.BOTTOM_RIGHT
	if on_left: return ResizeEdge.LEFT
	if on_right: return ResizeEdge.RIGHT
	if on_top: return ResizeEdge.TOP
	if on_bottom: return ResizeEdge.BOTTOM
	return ResizeEdge.NONE

func _cursor_for_edge(edge: ResizeEdge) -> Control.CursorShape:
	match edge:
		ResizeEdge.LEFT, ResizeEdge.RIGHT: return Control.CURSOR_HSIZE
		ResizeEdge.TOP, ResizeEdge.BOTTOM: return Control.CURSOR_VSIZE
		ResizeEdge.TOP_LEFT, ResizeEdge.BOTTOM_RIGHT: return Control.CURSOR_FDIAGSIZE
		ResizeEdge.TOP_RIGHT, ResizeEdge.BOTTOM_LEFT: return Control.CURSOR_BDIAGSIZE
		_: return Control.CURSOR_ARROW

func _apply_resize(mouse_pos: Vector2) -> void:
	var delta: Vector2 = mouse_pos - resize_start
	var pos: Vector2 = original_position
	var new_size: Vector2 = original_size
	var min_width: float = minf(MIN_WINDOW_SIZE.x, work_area.size.x)
	var min_height: float = minf(MIN_WINDOW_SIZE.y, work_area.size.y)

	if resize_edge in [ResizeEdge.LEFT, ResizeEdge.TOP_LEFT, ResizeEdge.BOTTOM_LEFT]:
		var max_width: float = original_size.x + (original_position.x - work_area.position.x)
		var width: float = clampf(original_size.x - delta.x, min_width, maxf(min_width, max_width))
		pos.x = original_position.x + (original_size.x - width)
		new_size.x = width
	elif resize_edge in [ResizeEdge.RIGHT, ResizeEdge.TOP_RIGHT, ResizeEdge.BOTTOM_RIGHT]:
		var max_width_right: float = work_area.end.x - original_position.x
		new_size.x = clampf(original_size.x + delta.x, min_width, maxf(min_width, max_width_right))

	if resize_edge in [ResizeEdge.TOP, ResizeEdge.TOP_LEFT, ResizeEdge.TOP_RIGHT]:
		var max_height: float = original_size.y + (original_position.y - work_area.position.y)
		var height: float = clampf(original_size.y - delta.y, min_height, maxf(min_height, max_height))
		pos.y = original_position.y + (original_size.y - height)
		new_size.y = height
	elif resize_edge in [ResizeEdge.BOTTOM, ResizeEdge.BOTTOM_LEFT, ResizeEdge.BOTTOM_RIGHT]:
		var max_height_bottom: float = work_area.end.y - original_position.y
		new_size.y = clampf(original_size.y + delta.y, min_height, maxf(min_height, max_height_bottom))

	global_position = pos
	size = new_size
	_clamp_to_work_area()

func _clamp_to_work_area() -> void:
	if work_area.size.x <= 0.0 or work_area.size.y <= 0.0:
		return
	global_position.x = clampf(global_position.x, work_area.position.x, work_area.end.x - size.x)
	global_position.y = clampf(global_position.y, work_area.position.y, work_area.end.y - size.y)

func _on_close_pressed() -> void:
	closed.emit(self)

func _on_minimize_pressed() -> void:
	minimized.emit(self)
	hide()

func _on_maximize_pressed() -> void:
	if not maximized:
		normal_position = global_position
		normal_size = size
		global_position = work_area.position
		size = work_area.size
		maximized = true
	else:
		global_position = normal_position
		size = normal_size
		maximized = false
		_clamp_to_work_area()
	focused.emit(self)
