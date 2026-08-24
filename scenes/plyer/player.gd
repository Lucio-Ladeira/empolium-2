extends CharacterBody2D

@export var speed := 100.0
@onready var player_animation : AnimatedSprite2D = $player_animation

func _physics_process(_delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = direction * speed
	move_and_slide()
