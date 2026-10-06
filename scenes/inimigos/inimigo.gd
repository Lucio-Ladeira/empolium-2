extends CharacterBody2D


enum Estado {
	VIGILANCIA,
	PERSEGUICAO,
	ATAQUE,
	DANO
}


@export_category("Vida")
@export var vida: int = 3
@export var dano_por_area: int = 1

@export_category("Referências")
@onready var visao: Area2D = $visao
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area_dano: Area2D = $dano
@onready var area_deteccao: Area2D = $Area2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

@export_category("Camadas")
# Camada 8 é o jogador. Camada 2 é a área/hitbox que causa dano.
@export var camada_jogador: int = 8
@export var camada_dano: int = 2
# Ajuste para a camada onde estão as paredes. Aqui, 1 significa camada 1.
@export var mascara_paredes: int = 1

@export_category("Vigilância")
@export var velocidade: float = 50.0
@export var distancia_vigilancia: float = 150.0
@export var distancia_chegada: float = 10.0
@export var tempo_parado_min: float = 0.5
@export var tempo_parado_max: float = 1.5

@export_category("Perseguição")
@export var velocidade_perseguicao: float = 80.0

@export_category("Dano")
@export var tempo_de_dano: float = 0.25


var estado_atual: Estado = Estado.VIGILANCIA
var jogador: Node2D = null
var jogador_visivel: bool = false
var tempo_estado: float = 0.0
var ultima_direcao: Vector2 = Vector2.DOWN
var ataque_em_andamento: bool = false


func _ready() -> void:
	# A área dano serve apenas para detectar o jogador.
	area_dano.collision_mask = 1 << (camada_jogador - 1)

	# A área de detecção recebe áreas que causam dano ao inimigo.
	area_deteccao.collision_mask = 1 << (camada_dano - 1)
	if not area_deteccao.area_entered.is_connected(_on_area_deteccao_area_entered):
		area_deteccao.area_entered.connect(_on_area_deteccao_area_entered)

	# Conectar aqui evita depender de conexões feitas manualmente no editor.
	if not visao.body_entered.is_connected(_on_visao_body_entered):
		visao.body_entered.connect(_on_visao_body_entered)
	if not visao.body_exited.is_connected(_on_visao_body_exited):
		visao.body_exited.connect(_on_visao_body_exited)
	if not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)

	# O RayCast deve verificar paredes, não o jogador.
	ray_cast_2d.collision_mask = mascara_paredes
	ray_cast_2d.enabled = true

	navigation_agent_2d.path_desired_distance = distancia_chegada
	navigation_agent_2d.target_desired_distance = distancia_chegada

	tocar_idle()

	# Aguarda o mapa de navegação ser sincronizado.
	await get_tree().physics_frame
	if is_inside_tree():
		escolher_novo_destino()


func _physics_process(delta: float) -> void:
	atualizar_visao()

	match estado_atual:
		Estado.VIGILANCIA:
			estado_vigilancia(delta)
		Estado.PERSEGUICAO:
			estado_perseguicao()
		Estado.ATAQUE:
			estado_ataque()
		Estado.DANO:
			estado_dano(delta)


func estado_vigilancia(delta: float) -> void:
	if jogador_visivel:
		mudar_estado(Estado.PERSEGUICAO)
		return

	if tempo_estado > 0.0:
		tempo_estado -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if navigation_agent_2d.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		tocar_idle()
		tempo_estado = randf_range(tempo_parado_min, tempo_parado_max)
		escolher_novo_destino()
		return

	var proximo_ponto := navigation_agent_2d.get_next_path_position()
	var direcao := global_position.direction_to(proximo_ponto)

	if direcao != Vector2.ZERO:
		ultima_direcao = direcao.normalized()
		tocar_andando(ultima_direcao)

	velocity = direcao * velocidade
	move_and_slide()


func escolher_novo_destino() -> void:
	var ponto_aleatorio := global_position + Vector2(
		randf_range(-distancia_vigilancia, distancia_vigilancia),
		randf_range(-distancia_vigilancia, distancia_vigilancia)
	)

	navigation_agent_2d.target_position = ponto_aleatorio


func estado_perseguicao() -> void:
	if jogador == null:
		mudar_estado(Estado.VIGILANCIA)
		return

	if jogador_visivel and jogador_dentro_da_area_de_ataque():
		mudar_estado(Estado.ATAQUE)
		return

	if not jogador_visivel:
		mudar_estado(Estado.VIGILANCIA)
		return

	navigation_agent_2d.target_position = jogador.global_position

	if navigation_agent_2d.is_navigation_finished():
		velocity = Vector2.ZERO
		tocar_idle()
		move_and_slide()
		return

	var proximo_ponto := navigation_agent_2d.get_next_path_position()
	var direcao := global_position.direction_to(proximo_ponto)

	if direcao != Vector2.ZERO:
		ultima_direcao = direcao.normalized()
		tocar_andando(ultima_direcao)

	velocity = direcao * velocidade_perseguicao
	move_and_slide()


func estado_ataque() -> void:
	velocity = Vector2.ZERO
	move_and_slide()


func estado_dano(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	tempo_estado -= delta

	if tempo_estado > 0.0:
		return

	if jogador != null and jogador_visivel:
		mudar_estado(Estado.PERSEGUICAO)
	else:
		mudar_estado(Estado.VIGILANCIA)


func mudar_estado(novo_estado: Estado) -> void:
	if estado_atual == novo_estado:
		return

	estado_atual = novo_estado

	match estado_atual:
		Estado.VIGILANCIA:
			velocity = Vector2.ZERO
			ataque_em_andamento = false
			tocar_idle()
			escolher_novo_destino()

		Estado.PERSEGUICAO:
			ataque_em_andamento = false
			if jogador != null:
				navigation_agent_2d.target_position = jogador.global_position
			tocar_andando(ultima_direcao)

		Estado.ATAQUE:
			velocity = Vector2.ZERO
			iniciar_ataque()

		Estado.DANO:
			velocity = Vector2.ZERO
			ataque_em_andamento = false
			tempo_estado = tempo_de_dano
			tocar_dano()


func iniciar_ataque() -> void:
	if ataque_em_andamento:
		return

	if jogador == null or not jogador_visivel or not jogador_dentro_da_area_de_ataque():
		mudar_estado(Estado.PERSEGUICAO)
		return

	ataque_em_andamento = true

	var direcao := global_position.direction_to(jogador.global_position)
	if direcao != Vector2.ZERO:
		ultima_direcao = direcao.normalized()

	anim.play(nome_animacao_ataque(ultima_direcao))


func _on_animation_finished(nome_animacao: StringName) -> void:
	if not str(nome_animacao).begins_with("ataque_"):
		return

	# Uma animação antiga não pode alterar o fluxo enquanto o inimigo está em dano.
	if estado_atual != Estado.ATAQUE:
		return

	ataque_em_andamento = false

	if jogador != null and jogador_visivel and jogador_dentro_da_area_de_ataque():
		# Continua no mesmo estado, iniciando outro golpe sem truques de transição.
		iniciar_ataque()
	elif jogador != null and jogador_visivel:
		mudar_estado(Estado.PERSEGUICAO)
	else:
		mudar_estado(Estado.VIGILANCIA)


func jogador_dentro_da_area_de_ataque() -> bool:
	if jogador == null:
		return false

	for corpo in area_dano.get_overlapping_bodies():
		if corpo == jogador:
			return true

	return false


func _on_area_deteccao_area_entered(area: Area2D) -> void:
	if not area.get_collision_layer_value(camada_dano):
		return

	receber_dano(dano_por_area)


func receber_dano(valor: int) -> void:
	if vida <= 0 or estado_atual == Estado.DANO:
		return

	vida -= valor

	if vida <= 0:
		morrer()
		return

	mudar_estado(Estado.DANO)


func morrer() -> void:
	set_physics_process(false)
	queue_free()


func _on_visao_body_entered(body: Node2D) -> void:
	if not body.get_collision_layer_value(camada_jogador):
		return

	jogador = body


func _on_visao_body_exited(body: Node2D) -> void:
	if body != jogador:
		return

	jogador = null
	jogador_visivel = false


func atualizar_visao() -> void:
	if jogador == null or not is_instance_valid(jogador):
		jogador = null
		jogador_visivel = false
		ray_cast_2d.target_position = Vector2.ZERO
		return

	ray_cast_2d.target_position = to_local(jogador.global_position)
	ray_cast_2d.force_raycast_update()

	if not ray_cast_2d.is_colliding():
		jogador_visivel = true
		return

	# Com mascara_paredes correta, qualquer colisão é obstáculo.
	# Esta exceção torna o código robusto caso a camada do jogador também esteja no RayCast.
	jogador_visivel = ray_cast_2d.get_collider() == jogador


func tocar_idle() -> void:
	var nome := nome_animacao_idle(ultima_direcao)
	if anim.current_animation != nome:
		anim.play(nome)


func tocar_andando(direcao: Vector2) -> void:
	var nome := nome_animacao_andando(direcao)
	if anim.current_animation != nome:
		anim.play(nome)


func tocar_dano() -> void:
	anim.play(nome_animacao_dano(ultima_direcao))


func nome_animacao_ataque(direcao: Vector2) -> String:
	if abs(direcao.x) > abs(direcao.y):
		return "ataque_right" if direcao.x > 0.0 else "ataque_left"
	return "ataque_down" if direcao.y > 0.0 else "ataque_top"


func nome_animacao_andando(direcao: Vector2) -> String:
	if abs(direcao.x) > abs(direcao.y):
		return "right" if direcao.x > 0.0 else "left"
	return "down" if direcao.y > 0.0 else "top"


func nome_animacao_idle(direcao: Vector2) -> String:
	if abs(direcao.x) > abs(direcao.y):
		return "right_idle" if direcao.x > 0.0 else "left_idle"
	return "down_idle" if direcao.y > 0.0 else "top_idle"


func nome_animacao_dano(direcao: Vector2) -> String:
	if abs(direcao.x) > abs(direcao.y):
		return "dano_right" if direcao.x > 0.0 else "dano_left"
	return "dano_down" if direcao.y > 0.0 else "dano_top"
