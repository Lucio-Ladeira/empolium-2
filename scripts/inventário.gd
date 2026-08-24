extends Control

signal aberto
signal fechado

var isOpen : bool = false

func _ready():
	visible = false

func _input(event):
	if event.is_action_pressed("Inventario"):
		if isOpen:
			close()
		else:
			open()

func open():
	visible = true
	isOpen = true
	aberto.emit()
	
func close():
	visible = false
	isOpen = false
	fechado.emit()
