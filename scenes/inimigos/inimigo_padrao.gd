extends "res://scenes/inimigos/inimigo.gd"

@export var intervalo_ataque: float = 1.0
@export var velocidade_avanco: float = 100.0
@export var duracao_avanco: float = 0.16
var ataque_restante: float = 0.0

func _physics_process(delta):
	if estado == Estado.MORTO:
		return
	tempo = maxf(0.0, tempo - delta)
	if recuo_restante > 0.0:
		velocity = direcao_recuo * forca_knockback * recuo_restante / maxf(duracao_knockback, 0.001)
		recuo_restante = maxf(0.0, recuo_restante - delta)
		move_and_slide()
		sprite.modulate = Color(1.5, 0.6, 0.6)
		queue_redraw()
		return
	velocity = Vector2.ZERO
	fase += delta
	var distancia = global_position.distance_to(jogador.global_position) if alvo_valido() else INF
	var visivel = distancia < alcance_visao and linha_livre(jogador.global_position)
	if estado != Estado.ATACAR:
		estado = Estado.PERSEGUIR if visivel else Estado.PATRULHA
		if visivel:
			if distancia <= 32.0 and tempo <= 0.0:
				estado = Estado.ATACAR
				direcao = global_position.direction_to(jogador.global_position)
				if direcao.is_zero_approx():
					direcao = Vector2.DOWN
				ataque_restante = duracao_avanco
				acertou = false
				tempo = intervalo_ataque
			elif distancia > 23.0:
				andar(jogador.global_position, velocidade)
	if estado == Estado.ATACAR:
		# Avanco curto com direcao fixa, usando a colisao normal do corpo.
		velocity = direcao * velocidade_avanco * minf(delta, ataque_restante) / delta
	move_and_slide()
	if estado == Estado.ATACAR:
		if not acertou and alvo_valido() and global_position.distance_to(jogador.global_position) < 25.0 and linha_livre(jogador.global_position):
			jogador.dano(1, direcao)
			acertou = true
		ataque_restante = maxf(0.0, ataque_restante - delta)
		if ataque_restante <= 0.0:
			estado = Estado.RECUPERAR
	if absf(velocity.x) > 0.1:
		sprite.flip_h = velocity.x < 0
	sprite.position.y = -absf(sin(fase * 10.0)) * 2.0 if velocity.length() > 1 else 0.0
	sprite.modulate = Color.WHITE
	queue_redraw()

func resetar():
	super.resetar()
	ataque_restante = 0.0
