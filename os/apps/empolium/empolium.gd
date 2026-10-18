extends Control

signal play_requested

@onready var status: Label = $Content/Status


func _on_play_pressed() -> void:
    play_requested.emit()
    status.text = "O jogo ainda não está disponível nesta instalação."


func _on_extras_pressed() -> void:
    status.text = "Abra Extras para ver mais conteúdo."
