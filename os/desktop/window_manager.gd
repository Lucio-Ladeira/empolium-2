class_name OSWindowManager
extends Control

signal window_opened(window, title)
signal window_closed(window, title)
signal window_minimized(window, title)
signal window_focused(window)

const WINDOW_SCENE := preload("res://os/window/window.tscn")
const TASKBAR_HEIGHT: float = 52.0
const WINDOW_MARGIN: float = 24.0

var windows: Array[OSWindow] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
    var area := _work_area()
    for window in windows:
        window.set_work_area(area)
        if window.maximized:
            window.global_position = area.position
            window.size = area.size

func _work_area() -> Rect2:
    var viewport_size: Vector2 = get_viewport_rect().size
    return Rect2(Vector2.ZERO, Vector2(maxf(1.0, viewport_size.x), maxf(1.0, viewport_size.y - TASKBAR_HEIGHT)))

func open_app(scene: PackedScene, title: String, initial_size: Vector2 = Vector2.ZERO, app_icon: Texture2D = null) -> OSWindow:
    var window: OSWindow = WINDOW_SCENE.instantiate()
    add_child(window)
    window.setup(title, app_icon)
    if initial_size != Vector2.ZERO:
        window.size = initial_size

    var content: Control = scene.instantiate() as Control
    window.set_content(content)
    window.closed.connect(close_window)
    window.minimized.connect(minimize_window)
    window.focused.connect(focus_window)
    windows.append(window)

    var area: Rect2 = _work_area()
    window.set_work_area(area)
    var x: float = maxf(area.position.x + WINDOW_MARGIN, (area.size.x - window.size.x) * 0.5 + randf_range(-70.0, 70.0))
    var y: float = maxf(area.position.y + WINDOW_MARGIN, (area.size.y - window.size.y) * 0.5 + randf_range(-40.0, 40.0))
    window.global_position = Vector2(x, y)
    window._clamp_to_work_area()
    focus_window(window)
    window_opened.emit(window, title)
    return window

func close_window(window: OSWindow) -> void:
    if not is_instance_valid(window):
        return
    var title: String = window.get_node("TitleBar/Title").text
    windows.erase(window)
    window_closed.emit(window, title)
    window.queue_free()

func minimize_window(window: OSWindow) -> void:
    if not is_instance_valid(window):
        return
    window.hide()
    window_minimized.emit(window, window.get_node("TitleBar/Title").text)

func restore_window(window: OSWindow) -> void:
    if not is_instance_valid(window):
        return
    window.show()
    focus_window(window)

func focus_window(window: OSWindow) -> void:
    if not is_instance_valid(window):
        return
    window.show()
    window.set_work_area(_work_area())
    window.move_to_front()
    window_focused.emit(window)

func close_all() -> void:
    for window in windows.duplicate():
        close_window(window)
