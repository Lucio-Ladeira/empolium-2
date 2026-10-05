extends CharacterBody2D


@export var speed: float = 100.0
@export var dash_speed: float = 250.0
@export var dash_duration: float = 0.15
@export var estamina: int = 300
@export var vida: int = 5


const DEADZONE: float = 0.2
const MAX_ESTAMINA: int = 300
const DASH_COST: int = 100


@onready var estamina_timer: Timer = $estamina_timer
@onready var dash_timer: Timer = $dashtimer
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_state: AnimationNodeStateMachinePlayback = (
	anim_tree.get("parameters/playback")
)
@onready var label: Label = $CanvasLayer/Label


enum PlayerState {
	MOVE,
	DASH,
	DEATH,
	ATTACK
}


var current_state: PlayerState = PlayerState.MOVE
var last_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	estamina_timer.start()

	dash_timer.wait_time = dash_duration

	anim_tree.active = true

	# O AnimationTree passa a avisar quando um estado termina.
	if not anim_state.state_finished.is_connected(_on_animation_state_finished):
		anim_state.state_finished.connect(_on_animation_state_finished)

	animation_state(last_direction)
	anim_state.travel("idle")


func _physics_process(_delta: float) -> void:
	label.text = "Vida: " + str(vida) + \
		"\nEstamina: " + str(estamina)

	match current_state:
		PlayerState.MOVE:
			move()

		PlayerState.DASH:
			dash()

		PlayerState.DEATH:
			morre()

		PlayerState.ATTACK:
			ataque()


# =========================================================
# MOVIMENTO
# =========================================================

func move() -> void:
	# O ataque só pode ser iniciado enquanto o personagem está em MOVE.
	if Input.is_action_just_pressed("attack"):
		iniciar_ataque()
		return

	var direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if direction.length() > DEADZONE:
		last_direction = direction.normalized()

		animation_state(last_direction)
		anim_state.travel("walk")

		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
		anim_state.travel("idle")

	# O dash também só é verificado durante MOVE.
	if Input.is_action_just_pressed("dash") and estamina >= DASH_COST:
		iniciar_dash()
		return

	move_and_slide()


# =========================================================
# ATAQUE
# =========================================================

func iniciar_ataque() -> void:
	# Esta proteção impede que um novo ataque seja iniciado
	# enquanto o ataque atual ainda estiver executando.
	if current_state != PlayerState.MOVE:
		return

	current_state = PlayerState.ATTACK
	velocity = Vector2.ZERO

	# A direção é definida apenas uma vez, no início do ataque.
	animation_state(last_direction)

	# IMPORTANTE:
	# travel("attack") não fica sendo chamado a cada frame.
	anim_state.travel("attack")


func ataque() -> void:
	# Enquanto o ataque estiver tocando, o personagem fica parado.
	# Não chame travel("attack") aqui.
	velocity = Vector2.ZERO


func _on_animation_state_finished(state: StringName) -> void:
	# O AnimationTree informa que o estado "attack" terminou.
	if state != &"attack":
		return

	# Evita que um sinal atrasado altere o estado de outra ação.
	if current_state != PlayerState.ATTACK:
		return

	current_state = PlayerState.MOVE
	velocity = Vector2.ZERO

	# Força a saída visual do último frame do ataque.
	anim_state.travel("idle")


# =========================================================
# DASH
# =========================================================

func iniciar_dash() -> void:
	current_state = PlayerState.DASH

	estamina -= DASH_COST
	estamina_timer.start()

	dash_timer.start()


func dash() -> void:
	velocity = last_direction * dash_speed
	move_and_slide()


func _on_dashtimer_timeout() -> void:
	if current_state == PlayerState.DASH:
		current_state = PlayerState.MOVE
		velocity = Vector2.ZERO

		anim_state.travel("idle")


# =========================================================
# MORTE E DANO
# =========================================================

func dano(vlr_dano: int) -> void:
	if current_state == PlayerState.DEATH:
		return

	if vida <= 0:
		return

	vida -= vlr_dano

	if vida <= 0:
		current_state = PlayerState.DEATH
		morre()


func morre() -> void:
	velocity = Vector2.ZERO
	anim_state.travel("death")


# =========================================================
# ANIMAÇÕES
# =========================================================

func animation_state(direction: Vector2) -> void:
	anim_tree.set(
		"parameters/idle/blend_position",
		direction
	)

	anim_tree.set(
		"parameters/walk/blend_position",
		direction
	)

	anim_tree.set(
		"parameters/attack/blend_position",
		direction
	)


# =========================================================
# ESTAMINA
# =========================================================

func _on_timer_timeout() -> void:
	if estamina < MAX_ESTAMINA:
		estamina = min(estamina + 100, MAX_ESTAMINA)
