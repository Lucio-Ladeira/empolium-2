extends Control

signal login_success

func _ready() -> void:
	$Center/Card.custom_minimum_size.x = minf(360.0, maxf(1.0, get_viewport_rect().size.x - 32.0))

func _on_login_button_pressed() -> void:
	login_success.emit()
