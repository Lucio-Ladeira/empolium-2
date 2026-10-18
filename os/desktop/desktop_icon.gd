class_name DesktopIcon
extends Button

@export var icon_kind: String = "game"
var selected: bool = false
var display_name: String = ""
var custom_icon: Texture2D

func _ready() -> void:
    display_name = text
    text = ""
    flat = true
    focus_mode = Control.FOCUS_NONE
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    queue_redraw()

func set_selected(value: bool) -> void:
    selected = value
    queue_redraw()

func set_custom_icon(texture: Texture2D) -> void:
    custom_icon = texture
    queue_redraw()

func _on_mouse_entered() -> void:
    queue_redraw()

func _on_mouse_exited() -> void:
    queue_redraw()

func _draw() -> void:
    if selected or is_hovered():
        draw_rect(Rect2(4, 1, size.x - 8.0, size.y - 3.0), Color(0.08, 0.16, 0.26, 0.76), true)
        draw_rect(Rect2(4, 1, size.x - 8.0, size.y - 3.0), Color(0.2, 0.82, 0.94, 0.62), false, 1.0)
    _draw_icon()
    var font: Font = get_theme_default_font()
    draw_string(font, Vector2(4, 82), display_name, HORIZONTAL_ALIGNMENT_CENTER, size.x - 8.0, 12, Color("#f0efe8"))

func _draw_icon() -> void:
    if custom_icon != null:
        draw_texture_rect(custom_icon, Rect2(Vector2((size.x - 44.0) * 0.5, 8.0), Vector2(44.0, 44.0)), false)
        return
    var paper := Color("#dce9f8")
    var ink := Color("#111a2d")
    var accent := Color("#ee62ce")
    var center := Vector2(size.x * 0.5, 30.0)
    match icon_kind:
        "game":
            draw_rect(Rect2(center.x - 20, center.y - 16, 40, 28), ink, true)
            draw_rect(Rect2(center.x - 16, center.y - 12, 32, 20), paper, true)
            draw_rect(Rect2(center.x - 12, center.y - 8, 24, 12), Color("#43dff2"), true)
            draw_rect(Rect2(center.x - 4, center.y - 8, 4, 12), paper, true)
            draw_rect(Rect2(center.x - 8, center.y - 4, 12, 4), paper, true)
            draw_rect(Rect2(center.x - 2, center.y + 12, 4, 8), ink, true)
            draw_rect(Rect2(center.x - 12, center.y + 20, 24, 4), ink, true)
        "settings":
            draw_rect(Rect2(center.x - 12, center.y - 20, 24, 40), ink, true)
            draw_rect(Rect2(center.x - 20, center.y - 12, 40, 24), ink, true)
            draw_rect(Rect2(center.x - 8, center.y - 12, 16, 24), paper, true)
            draw_rect(Rect2(center.x - 12, center.y - 8, 24, 16), paper, true)
            draw_rect(Rect2(center.x - 4, center.y - 4, 8, 8), accent, true)
        "files":
            draw_rect(Rect2(center.x - 20, center.y - 8, 40, 28), ink, true)
            draw_rect(Rect2(center.x - 16, center.y - 4, 32, 20), paper, true)
            draw_rect(Rect2(center.x - 16, center.y - 12, 20, 8), ink, true)
            draw_rect(Rect2(center.x - 12, center.y, 24, 4), accent, true)
            draw_rect(Rect2(center.x - 12, center.y + 8, 16, 4), ink, true)
        "extras":
            draw_rect(Rect2(center.x - 20, center.y - 20, 40, 40), ink, true)
            draw_rect(Rect2(center.x - 12, center.y - 12, 24, 24), paper, true)
            draw_rect(Rect2(center.x - 4, center.y - 4, 8, 8), accent, true)
            draw_rect(Rect2(center.x - 4, center.y - 20, 8, 4), accent, true)
            draw_rect(Rect2(center.x - 4, center.y + 16, 8, 4), accent, true)
        "about":
            draw_rect(Rect2(center.x - 16, center.y - 20, 32, 40), ink, true)
            draw_rect(Rect2(center.x - 12, center.y - 16, 24, 32), paper, true)
            draw_rect(Rect2(center.x - 4, center.y - 8, 8, 4), accent, true)
            draw_rect(Rect2(center.x - 4, center.y, 8, 12), accent, true)
            draw_rect(Rect2(center.x - 4, center.y + 16, 8, 4), accent, true)
