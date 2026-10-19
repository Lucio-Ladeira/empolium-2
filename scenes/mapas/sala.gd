extends Node2D

signal concluida(sala)
const Porta = preload("res://scenes/mapas/porta.gd")
var portas: Array[StaticBody2D] = []
enum Estado { NAO_VISITADA, EM_COMBATE, CONCLUIDA }
@export_enum("inicio", "combate", "npc", "loja", "boss", "portal") var tipo: String = "combate"
@export var encontro: Array[PackedScene] = []
var visitada: bool = false
var estado: Estado = Estado.NAO_VISITADA
var celula: Vector2i
var retangulo: Rect2i
var indice: int
var vivos: Array[Node2D] = []
var criados: Array[Node2D] = []
var pontos: Array[Vector2] = []
var rotulo: Label

func configurar_area(poligono: PackedVector2Array):
	var area = Area2D.new()
	area.name = "Entrada"
	area.collision_layer = 0
	area.collision_mask = 128
	var forma = CollisionPolygon2D.new()
	forma.polygon = poligono
	area.add_child(forma)
	add_child(area)
	area.body_entered.connect(_entrada)

func _entrada(corpo: Node2D):
	if corpo.is_in_group("player") and corpo.vida > 0:
		visitada = true
		get_parent().get_parent().sala_atual = indice
		iniciar.call_deferred(corpo)

func iniciar(jogador: Node2D):
	if estado != Estado.NAO_VISITADA or not is_instance_valid(jogador) or jogador.vida <= 0:
		return
	if tipo not in ["combate", "boss"]:
		estado = Estado.CONCLUIDA
		return
	estado = Estado.EM_COMBATE
	for porta in portas: porta.definir_fechada(true)
	# Ordena os pontos mais distantes do jogador primeiro, sem repetir posições.
	var candidatos = pontos.duplicate()
	candidatos.sort_custom(func(a, b): return a.distance_squared_to(jogador.global_position) > b.distance_squared_to(jogador.global_position))
	for i in range(mini(encontro.size(), candidatos.size())):
		var inimigo = encontro[i].instantiate()
		inimigo.position = to_local(candidatos[i])
		inimigo.derrotado.connect(_derrotado.bind(inimigo), CONNECT_ONE_SHOT)
		add_child(inimigo)
		vivos.append(inimigo)
		criados.append(inimigo)
	if vivos.is_empty():
		_finalizar()

func _derrotado(inimigo: Node2D):
	vivos.erase(inimigo)
	if vivos.is_empty() and estado == Estado.EM_COMBATE:
		_finalizar()

func _finalizar():
	for porta in portas: porta.definir_fechada(false)
	estado = Estado.CONCLUIDA
	rotulo.text += " • LIVRE"
	concluida.emit(self)

func reiniciar_encontro():
	if estado != Estado.EM_COMBATE:
		return
	for inimigo in criados:
		if is_instance_valid(inimigo):
			inimigo.free()
	criados.clear()
	vivos.clear()
	estado = Estado.NAO_VISITADA
	for porta in portas: porta.definir_fechada(false)

func adicionar_porta(poligono: PackedVector2Array):
	var porta = Porta.new()
	porta.configurar(poligono)
	add_child(porta)
	portas.append(porta)