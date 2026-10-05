extends CanvasLayer
@onready var label: Label = $Label

func _ready():
	label.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("pause"):
		label.visible = not label.visible
		get_tree().paused = not get_tree().paused
