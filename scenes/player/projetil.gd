extends Node2D

@export var velocidade: float = 400.0
@export var duracao: float = 1.5
var direcao: Vector2 = Vector2.RIGHT
var dano: float = 1.0

func _ready():
	rotation = direcao.angle()

func _physics_process(delta):
	duracao -= delta
	if duracao <= 0:
		queue_free()
		return
	var destino = global_position + direcao * velocidade * delta
	# As colisoes dos personagens ficam nos pes: projeta o tiro no mesmo plano.
	var altura_colisao = Vector2(0, 10)
	var consulta = PhysicsRayQueryParameters2D.create(global_position + altura_colisao, destino + altura_colisao, 5)
	var impacto = get_world_2d().direct_space_state.intersect_ray(consulta)
	if not impacto.is_empty():
		var corpo = impacto.collider
		if corpo.is_in_group("inimigos") and corpo.has_method("dano"):
			corpo.dano(dano, direcao, false)
		queue_free()
		return
	global_position = destino

