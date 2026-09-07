extends CharacterBody2D

@export var speed := 100.0
@export var dash_speed := 250.0
@export var dash_duration := 0.15
@export var estamina := 300
@onready var estamina_timer: Timer = $estamina_timer
@onready var dash_timer: Timer = $dashtimer
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")
@onready var label: Label = $Label


var current_state = player_state.MOVE
var last_direction := Vector2.DOWN

enum player_state {
	MOVE,
	DASH
}

func _ready() -> void:
	estamina_timer.start()
	dash_timer.wait_time = dash_duration
func _physics_process(_delta):
	label.text = str(estamina)
	
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
	if Input.is_action_just_pressed("dash") and estamina >= 100:
		estamina_timer.start()
		estamina -= 100
		current_state = player_state.DASH
		dash_timer.start()
		return
	move_and_slide()


func dash():
	velocity = last_direction * dash_speed
	move_and_slide()
func _on_dashtimer_timeout() -> void:
	current_state = player_state.MOVE

func animation_state(direction):
	anim_tree.set("parameters/idle/blend_position", direction)
	anim_tree.set("parameters/walk/blend_position", direction)


func _on_timer_timeout() -> void:
	if estamina < 300:
		estamina += 100
