extends CharacterBody2D

signal melhorias_alteradas
const Catalogo = preload("res://scenes/itens/melhorias.gd")
var moedas: int = 0
var inventario: Array[int] = [0, 0, 0, 0, 0]
var equipados: Array[int] = []
var vida_maxima: int = 5
var estamina_maxima: int = 300
var velocidade_base: float
var multiplicador_dano: float = 1.0
var moedas_label: Label

const PROJETIL = preload("res://scenes/player/projetil.tscn")
@export var intervalo_tiro: float = 0.4
@export var dano_tiro: int = 1
var tiro_restante: float = 0.0


@export var speed: float = 100.0
@export var dash_speed: float = 250.0
@export var dash_duration: float = 0.15
@export var estamina: int = 300
@export var vida: int = 5
@export var velocidade_avanco_ataque: float = 120.0
@export var duracao_avanco_ataque: float = 0.12
var avanco_restante: float = 0.0
@export var forca_knockback: float = 300.0
@export var duracao_knockback: float = 0.24
var recuo_restante: float = 0.0
var direcao_recuo: Vector2 = Vector2.ZERO


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
	ATTACK,
	HURT
}


var current_state: PlayerState = PlayerState.MOVE
var last_direction: Vector2 = Vector2.DOWN
@export var tempo_respawn: float = 2.0
var ponto_respawn: Vector2
var vida_inicial: int
var invulnerabilidade: float = 0.0
var restante_respawn: float = 0.0
var atingidos: Array[Node2D] = []


func _ready() -> void:
	ponto_respawn = global_position
	vida_inicial = vida
	vida_maxima = vida
	velocidade_base = speed
	moedas_label = Label.new()
	moedas_label.position = Vector2(18, 16)
	moedas_label.add_theme_font_size_override("font_size", 28)
	moedas_label.add_theme_color_override("font_color", Color("f6d779"))
	moedas_label.text = "Engrenagens: 0"
	$CanvasLayer.add_child(moedas_label)
	$dano.body_entered.connect(_atingir_inimigo)
	estamina_timer.start()

	dash_timer.wait_time = dash_duration

	anim_tree.active = true

	# O AnimationTree passa a avisar quando um estado termina.
	if not anim_state.state_finished.is_connected(_on_animation_state_finished):
		anim_state.state_finished.connect(_on_animation_state_finished)

	animation_state(last_direction)
	anim_state.travel("idle")


func _physics_process(_delta: float) -> void:
	tiro_restante = maxf(0.0, tiro_restante - _delta)
	invulnerabilidade = maxf(0.0, invulnerabilidade - _delta)
	$sprites.modulate.a = 0.45 if invulnerabilidade > 0 and fmod(invulnerabilidade, 0.2) < 0.1 else 1.0
	if current_state == PlayerState.DEATH:
		restante_respawn -= _delta
		label.text = "Derrotado! Retorno em %.1f" % maxf(0.0, restante_respawn)
		if restante_respawn <= 0:
			respawn()
		return
	if current_state == PlayerState.ATTACK:
		for corpo in $dano.get_overlapping_bodies():
			_atingir_inimigo(corpo)
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
			ataque(_delta)

		PlayerState.HURT:
			recuar(_delta)


# =========================================================
# MOVIMENTO
# =========================================================

func move() -> void:
	# O ataque só pode ser iniciado enquanto o personagem está em MOVE.
	if Input.is_action_just_pressed("attack"):
		iniciar_ataque()
		return

	if Input.is_action_pressed("shoot"):
		atirar()

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

	var direcao_mouse = get_global_mouse_position() - global_position
	if direcao_mouse.length_squared() > 1.0:
		last_direction = direcao_mouse.normalized()
	avanco_restante = duracao_avanco_ataque
	atingidos.clear()
	current_state = PlayerState.ATTACK
	velocity = Vector2.ZERO

	# A direção é definida apenas uma vez, no início do ataque.
	animation_state(last_direction)

	# IMPORTANTE:
	# travel("attack") não fica sendo chamado a cada frame.
	anim_state.travel("attack")


func ataque(delta: float) -> void:
	# Mantem a direcao escolhida no inicio e colide normalmente com paredes.
	var passo = minf(delta, avanco_restante)
	avanco_restante = maxf(0.0, avanco_restante - delta)
	velocity = last_direction * velocidade_avanco_ataque * passo / delta
	move_and_slide()


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

func dano(vlr_dano: int, direcao_impacto: Vector2 = Vector2.ZERO) -> void:
	if invulnerabilidade > 0 or vlr_dano <= 0:
		return
	if current_state == PlayerState.DEATH:
		return

	if vida <= 0:
		return

	vida = maxi(0, vida - vlr_dano)
	invulnerabilidade = 0.7

	if vida <= 0:
		current_state = PlayerState.DEATH
		morre()
	elif not direcao_impacto.is_zero_approx():
		direcao_recuo = direcao_impacto.normalized()
		recuo_restante = duracao_knockback
		avanco_restante = 0.0
		current_state = PlayerState.HURT
		dash_timer.stop()
		$"dano/CollisionShape2D".set_deferred("disabled", true)
		anim_state.start("idle", true)


func recuar(delta: float) -> void:
	velocity = direcao_recuo * forca_knockback * recuo_restante / maxf(duracao_knockback, 0.001)
	recuo_restante = maxf(0.0, recuo_restante - delta)
	move_and_slide()
	if recuo_restante <= 0.0:
		velocity = Vector2.ZERO
		current_state = PlayerState.MOVE


func morre() -> void:
	recuo_restante = 0.0
	avanco_restante = 0.0
	restante_respawn = tempo_respawn
	dash_timer.stop()
	$"dano/CollisionShape2D".set_deferred("disabled", true)
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
	if estamina < estamina_maxima:
		estamina = min(estamina + 100, estamina_maxima)

func _atingir_inimigo(corpo: Node2D) -> void:
	if current_state != PlayerState.ATTACK or $"dano/CollisionShape2D".disabled:
		return
	if corpo.is_in_group("inimigos") and corpo.has_method("dano") and not atingidos.has(corpo):
		# A espada nao atravessa paredes.
		var raio = PhysicsRayQueryParameters2D.create(global_position, corpo.global_position, 1)
		if get_world_2d().direct_space_state.intersect_ray(raio).is_empty():
			atingidos.append(corpo)
			corpo.dano(multiplicador_dano, global_position.direction_to(corpo.global_position) if not global_position.is_equal_approx(corpo.global_position) else last_direction)

func respawn() -> void:
	tiro_restante = 0.0
	get_tree().call_group("projeteis_player", "queue_free")
	get_tree().call_group("drops", "queue_free")
	recuo_restante = 0.0
	direcao_recuo = Vector2.ZERO
	avanco_restante = 0.0
	global_position = ponto_respawn
	vida = vida_maxima
	estamina = estamina_maxima
	velocity = Vector2.ZERO
	current_state = PlayerState.MOVE
	atingidos.clear()
	invulnerabilidade = 2.0
	dash_timer.stop()
	estamina_timer.start()
	anim_state.start("idle", true)
	$"dano/CollisionShape2D".set_deferred("disabled", true)
	$Camera2D.reset_smoothing()
	if get_tree().has_group("mapas"):
		get_tree().call_group("mapas", "reiniciar_encontros")
	else:
		get_tree().call_group("inimigos", "resetar")



func atirar() -> void:
	if current_state != PlayerState.MOVE or tiro_restante > 0.0 or get_tree().paused:
		return
	var mira = get_global_mouse_position() - global_position
	if mira.length_squared() <= 1.0:
		return
	var tiro = PROJETIL.instantiate()
	tiro.direcao = mira.normalized()
	tiro.dano = dano_tiro * multiplicador_dano
	get_parent().add_child(tiro)
	tiro.global_position = global_position
	tiro_restante = intervalo_tiro
	last_direction = tiro.direcao
	animation_state(last_direction)


func coletar_drop(dados: Dictionary) -> bool:
	if vida <= 0:
		return false
	match dados.tipo:
		"moeda":
			moedas += dados.quantidade
			moedas_label.text = "Engrenagens: %d" % moedas
		"cura":
			if vida >= vida_maxima:
				return false
			vida = mini(vida_maxima, vida + dados.quantidade)
		"chip":
			inventario[dados.chip] += dados.quantidade
		_:
			return false
	melhorias_alteradas.emit()
	return true

func equipar_chip(indice: int) -> bool:
	if indice < 0 or indice >= inventario.size() or equipados.size() >= 6:
		return false
	if inventario[indice] <= equipados.count(indice):
		return false
	equipados.append(indice)
	recalcular_melhorias()
	return true

func remover_chip(slot: int):
	if slot >= 0 and slot < equipados.size():
		equipados.remove_at(slot)
		recalcular_melhorias()

func recalcular_melhorias():
	vida_maxima = vida_inicial + equipados.count(1)
	estamina_maxima = MAX_ESTAMINA + 100 * equipados.count(3)
	speed = velocidade_base * (1.0 + 0.05 * equipados.count(2))
	multiplicador_dano = 1.0 + 0.05 * equipados.count(0) + 0.15 * equipados.count(4)
	vida = mini(vida, vida_maxima)
	estamina = mini(estamina, estamina_maxima)
	melhorias_alteradas.emit()
