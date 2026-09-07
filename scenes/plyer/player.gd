extends CharacterBody2D

@export var speed := 100.0
@export var dash_speed := 250.0
@export var dash_duration := 0.15
@onready var dash_timer: Timer = $dash_timer


@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")

var current_state = player_state.MOVE
var last_direction := Vector2.DOWN
var pode_dash = true
enum player_state {
	MOVE,
	DASH
}

func _ready() -> void:
	dash_timer.start()
func _physics_process(_delta):
	print(pode_dash)
	match current_state:
			
		player_state.MOVE:
			move()

		player_state.DASH:
			dash()

func move():
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	#andar
	if direction != Vector2.ZERO:
		last_direction = direction.normalized()
		animation_state(direction)
		anim_state.travel("walk")
		velocity = direction * speed
	#parar
	else:
		anim_state.travel("idle")
		velocity = Vector2.ZERO
	#dash
	if Input.is_action_just_pressed("dash") and pode_dash:
		dash_timer.start()
		pode_dash = false
		current_state = player_state.DASH
		velocity = last_direction * dash_speed
		return
	move_and_slide()


func dash():
		velocity = last_direction * dash_speed
		move_and_slide()
		await get_tree().create_timer(dash_duration).timeout
		current_state = player_state.MOVE


func animation_state(direction):
	anim_tree.set("parameters/idle/blend_position", direction)
	anim_tree.set("parameters/walk/blend_position", direction)


func _on_timer_timeout() -> void:
	pode_dash = true
