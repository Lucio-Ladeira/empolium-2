extends Node2D

@export var velocidade: float = 400.0
@export var duracao: float = 1.5
var direcao: Vector2 = Vector2.RIGHT
var dano: float = 1.0
var exclusoes: Array[RID] = []

func _ready():
	rotation = direcao.angle()
	var jogador = get_tree().get_first_node_in_group("player") as CollisionObject2D
	if jogador:
		exclusoes.append(jogador.get_rid())
		var hitbox = jogador.get_node_or_null("dano") as Area2D
		if hitbox:
			exclusoes.append(hitbox.get_rid())

func _physics_process(delta):
	duracao -= delta
	if duracao <= 0:
		queue_free()
		return
	var destino = global_position + direcao * velocidade * delta
	# Alinha o raio ao plano de colisão dos personagens e das paredes.
	var altura_colisao = Vector2(0, 18)
	var consulta = PhysicsRayQueryParameters2D.create(global_position + altura_colisao, destino + altura_colisao, 0xFFFFFFFF)
	consulta.exclude = exclusoes
	consulta.collide_with_areas = true
	var impacto = get_world_2d().direct_space_state.intersect_ray(consulta)
	if not impacto.is_empty():
		var corpo = impacto.collider
		if corpo.is_in_group("inimigos") and corpo.has_method("dano"):
			corpo.dano(dano, direcao, false)
		queue_free()
		return
	global_position = destino

