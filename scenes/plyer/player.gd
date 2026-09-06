extends CharacterBody2D

@export var speed := 100.0
@onready var anim: AnimationPlayer = $Visuals/anim
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")

var current_state = player_state.MOVE
enum player_state{MOVE}

func _physics_process(_delta):
	match current_state:
		player_state.MOVE:
			move()
			
func move():
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		animation_state()
		anim_state.travel("walk")
		velocity = direction * speed
		move_and_slide()
	if direction == Vector2.ZERO:
		anim_state.travel("idle")
	
func animation_state():
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	anim_tree.set("parameters/idle/blend_position", direction)
	anim_tree.set("parameters/walk/blend_position", direction)
	
