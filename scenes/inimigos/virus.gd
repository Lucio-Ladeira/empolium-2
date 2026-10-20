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
		if deve_perseguir():
			estado = Estado.PERSEGUIR
			if distancia <= distancia_ativacao and linha_livre(jogador.global_position):
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
	var explosao = AnimatedSprite2D.new()
	explosao.sprite_frames = preload("res://assets/artes_equipe/Creeper/animacoes.tres")
	explosao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	explosao.scale = Vector2.ONE * 0.65
	explosao.position = position + Vector2(0,-10)
	explosao.z_index = z_index
	explosao.animation_finished.connect(explosao.queue_free)
	get_parent().add_child(explosao)
	explosao.play("Explosion")
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
		return
	super._draw()
	if armado and estado != Estado.MORTO:
		draw_circle(Vector2.ZERO, raio_explosao, Color(1, 0.15, 0.05, 0.12))
		draw_arc(Vector2.ZERO, raio_explosao, 0, TAU, 48, Color(1, 0.4, 0.1, 0.7), 1)
