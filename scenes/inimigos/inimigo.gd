extends CharacterBody2D

signal derrotado

const Catalogo = preload("res://scenes/itens/melhorias.gd")
const Drop = preload("res://scenes/itens/drop.gd")
@export_enum("comum", "trojan", "virus") var tipo_drop: String = "trojan"
var loot_gerado: bool = false

@export var vida_maxima: int = 3
@export var velocidade: float = 48.0
@export var alcance_visao: float = 140.0
@export var forca_knockback: float = 160.0
@export var duracao_knockback: float = 0.16
var recuo_restante: float = 0.0
var direcao_recuo: Vector2 = Vector2.ZERO
enum Estado { PATRULHA, PERSEGUIR, PREPARAR, ATACAR, RECUPERAR, MORTO }
var estado: Estado = Estado.PATRULHA
var vida: float
var origem: Vector2
var tempo: float = 0.0
var fase: float = 0.0
var ponto: int = 0
var golpes: int = 0
var acertou: bool = false
var direcao: Vector2 = Vector2.ZERO
var jogador: Node2D
@onready var agente: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	var nome = get_node_or_null("Nome")
	if nome: nome.hide()
	origem = global_position
	vida = vida_maxima
	jogador = get_tree().get_first_node_in_group("player")

func alvo_valido() -> bool:
	return is_instance_valid(jogador) and jogador.vida > 0

func linha_livre(destino: Vector2) -> bool:
	var consulta = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, 10), destino + Vector2(0, 10), 1)
	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()

func _physics_process(delta):
	if estado == Estado.MORTO:
		return
	if recuo_restante > 0.0:
		velocity = direcao_recuo * forca_knockback * recuo_restante / maxf(duracao_knockback, 0.001)
		recuo_restante = maxf(0.0, recuo_restante - delta)
		move_and_slide()
		sprite.modulate = Color(1.5, 0.6, 0.6)
		queue_redraw()
		return
	tempo -= delta
	fase += delta
	velocity = Vector2.ZERO
	var distancia = global_position.distance_to(jogador.global_position) if alvo_valido() else INF
	var jogador_visivel = distancia < alcance_visao and linha_livre(jogador.global_position)
	match estado:
		Estado.PATRULHA:
			var destino = origem + Vector2(-40, 0) if ponto == 1 else origem
			andar(destino, velocidade * 0.5)
			if global_position.distance_to(destino) < 6.0:
				ponto = 1 - ponto
			if jogador_visivel:
				estado = Estado.PERSEGUIR
		Estado.PERSEGUIR:
			if not jogador_visivel or global_position.distance_to(origem) > 190:
				estado = Estado.PATRULHA
			elif distancia < (110.0 if golpes % 3 == 2 else 30.0) and linha_livre(jogador.global_position):
				direcao = global_position.direction_to(jogador.global_position)
				estado = Estado.PREPARAR
				tempo = 0.08 if golpes % 3 == 2 else 0.15
			else:
				andar(jogador.global_position, velocidade)
		Estado.PREPARAR:
			if not jogador_visivel:
				estado = Estado.PATRULHA
			elif tempo <= 0:
				estado = Estado.ATACAR
				tempo = 0.5 if golpes % 3 == 2 else 0.18
				acertou = false
		Estado.ATACAR:
			velocity = direcao * (220.0 if golpes % 3 == 2 else 55.0)
			if golpes % 3 == 2 and tempo > 0.0 and not acertou and distancia < 25.0 and alvo_valido() and linha_livre(jogador.global_position):
				jogador.dano(2, direcao)
				acertou = true
			if tempo <= 0:
				golpes += 1
				estado = Estado.RECUPERAR
				tempo = 0.3
		Estado.RECUPERAR:
			if tempo <= 0:
				estado = Estado.PERSEGUIR if jogador_visivel else Estado.PATRULHA
	move_and_slide()
	sprite.flip_h = direcao.x < 0 if estado == Estado.PREPARAR else velocity.x < 0
	sprite.position.y = -absf(sin(fase * 10.0)) * 2.0 if velocity.length() > 1 else 0.0
	sprite.modulate = Color(1.8, 1.2, 0.4) if estado == Estado.PREPARAR else Color.WHITE
	queue_redraw()

func andar(destino: Vector2, rapidez: float):
	if NavigationServer2D.map_get_iteration_id(agente.get_navigation_map()) == 0:
		return
	agente.target_position = destino
	if not agente.is_navigation_finished():
		velocity = global_position.direction_to(agente.get_next_path_position()) * rapidez

func dano(valor: float, direcao_impacto: Vector2 = Vector2.ZERO, aplicar_knockback: bool = true):
	if estado == Estado.MORTO or valor <= 0:
		return
	vida = maxf(0.0, vida - valor)
	if vida > 0:
		if aplicar_knockback:
			direcao_recuo = direcao_impacto.normalized()
			if direcao_recuo.is_zero_approx() and is_instance_valid(jogador):
				direcao_recuo = jogador.global_position.direction_to(global_position)
			recuo_restante = duracao_knockback
		estado = Estado.RECUPERAR
		tempo = 0.3
		acertou = true
	if vida == 0:
		gerar_drops()
		estado = Estado.MORTO
		velocity = Vector2.ZERO
		$CollisionShape2D.set_deferred("disabled", true)
		if sprite.has_method("morrer"):
			sprite.morrer()
		else:
			hide()
	queue_redraw()

func resetar():
	loot_gerado = false
	recuo_restante = 0.0
	direcao_recuo = Vector2.ZERO
	sprite.modulate = Color.WHITE
	global_position = origem
	vida = vida_maxima
	estado = Estado.PATRULHA
	golpes = 0
	ponto = 0
	tempo = 0
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", false)
	if sprite.has_method("reiniciar"):
		sprite.reiniciar()
	show()

func _draw():
	if estado == Estado.MORTO:
		return
	draw_rect(Rect2(-12, -18, 24, 3), Color(0.15, 0.05, 0.05))
	draw_rect(Rect2(-12, -18, 24.0 * vida / vida_maxima, 3), Color(0.9, 0.2, 0.25))










func gerar_drops():
	if loot_gerado:
		return
	loot_gerado = true
	derrotado.emit()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var itens = Catalogo.sortear(tipo_drop, rng)
	for i in range(itens.size()):
		var drop = Drop.new()
		drop.dados = itens[i]
		# Espalha apenas onde nao houver uma parede entre o corpo e o item.
		var destino = global_position + Vector2((i - 1) * 16, 0)
		drop.position = get_parent().to_local(destino if linha_livre(destino) else global_position)
		get_parent().call_deferred("add_child", drop)