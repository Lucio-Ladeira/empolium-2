extends Control

var active: bool = false
var start: Vector2 = Vector2.ZERO
var current: Vector2 = Vector2.ZERO

func begin(point: Vector2) -> void:
    active = true
    start = point
    current = point
    queue_redraw()

func update_point(point: Vector2) -> void:
    if not active:
        return
    current = point
    queue_redraw()

func finish() -> void:
    active = false
    queue_redraw()

func selection_rect() -> Rect2:
    return Rect2(start, current - start).abs()

func _draw() -> void:
    if not active:
        return
    var rect: Rect2 = selection_rect()
    draw_rect(rect, Color(0.16, 0.78, 0.92, 0.16), true)
    draw_rect(rect, Color(0.28, 0.88, 1.0, 0.82), false, 1.0)
