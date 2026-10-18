extends "res://scenes/inimigos/inimigo.gd"

@export var distancia_ativacao: float = 30.0
@export var raio_explosao: float = 64.0
@export var dano_explosao: int = 3
@export var tempo_preparacao: float = 0.65
var armado: bool = false
var explodiu: bool = false
var restante: float = 0.0

func _physics_process(delta):
	if explodiu:
		restante = maxf(0.0, restante - delta)
		if restante <= 0:
			hide()
		queue_redraw()
		return
	if estado == Estado.MORTO:
		return
	fase += delta
	velocity = Vector2.ZERO
	if recuo_restante > 0:
		velocity = direcao_recuo * forca_knockback * recuo_restante / maxf(duracao_knockback, 0.001)
		recuo_restante = maxf(0.0, recuo_restante - delta)
	elif not armado and alvo_valido():
		var distancia = global_position.distance_to(jogador.global_position)
		if distancia < alcance_visao and linha_livre(jogador.global_position):
			estado = Estado.PERSEGUIR
			if distancia <= distancia_ativacao:
				armado = true
				estado = Estado.PREPARAR
				restante = tempo_preparacao
			else:
				andar(jogador.global_position, velocidade)
		else:
			estado = Estado.PATRULHA
	move_and_slide()
	if armado:
		restante -= delta
		if restante <= 0:
			explodir()
			return
	sprite.modulate = Color(1.8, 0.55, 0.3) if armado and sin(fase * 35.0) > 0 else Color.WHITE
	sprite.position.y = sin(fase * 3.0) * 1.5
	queue_redraw()

func explodir():
	if explodiu or estado == Estado.MORTO:
		return
	explodiu = true
	gerar_drops()
	armado = false
	estado = Estado.MORTO
	vida = 0
	velocity = Vector2.ZERO
	restante = 0.4
	$CollisionShape2D.set_deferred("disabled", true)
	sprite.hide()
	$Nome.hide()
	if alvo_valido() and global_position.distance_to(jogador.global_position) <= raio_explosao and linha_livre(jogador.global_position):
		var empurrao = global_position.direction_to(jogador.global_position)
		jogador.dano(dano_explosao, empurrao if not empurrao.is_zero_approx() else Vector2.DOWN)
	queue_redraw()

func resetar():
	super.resetar()
	armado = false
	explodiu = false
	restante = 0
	sprite.show()
	$Nome.show()
	queue_redraw()

func _draw():
	if explodiu:
		var progresso = 1.0 - restante / 0.4
		draw_circle(Vector2.ZERO, raio_explosao * (0.3 + progresso * 0.7), Color(1, 0.4, 0.05, (1.0 - progresso) * 0.55))
		draw_arc(Vector2.ZERO, raio_explosao * progresso, 0, TAU, 48, Color(1, 0.85, 0.2, 1.0 - progresso), 3)
		return
	super._draw()
	if armado and estado != Estado.MORTO:
		draw_circle(Vector2.ZERO, raio_explosao, Color(1, 0.15, 0.05, 0.12))
		draw_arc(Vector2.ZERO, raio_explosao, 0, TAU, 48, Color(1, 0.4, 0.1, 0.7), 1)
