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
var hordas_extras: int = 0
var horda_atual: int = 0
var jogador_atual: Node2D
var proxima_pendente: bool = false
var ultimos_spawns: Array[Vector2] = []

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
	area.body_exited.connect(_saida)

func _entrada(corpo: Node2D):
	if corpo.is_in_group("player") and corpo.vida > 0:
		visitada = true
		var mapa = get_parent().get_parent()
		mapa.sala_atual = indice
		mapa.tocar_musica(tipo)
		iniciar.call_deferred(corpo)

func _saida(corpo: Node2D):
	if corpo.is_in_group("player") and corpo.vida > 0:
		get_parent().get_parent().tocar_musica("normal")

func iniciar(jogador: Node2D):
	if estado != Estado.NAO_VISITADA or not is_instance_valid(jogador) or jogador.vida <= 0:
		return
	if tipo not in ["combate", "boss"]:
		estado = Estado.CONCLUIDA
		return
	estado = Estado.EM_COMBATE
	for porta in portas: porta.definir_fechada(true)
	jogador_atual = jogador
	horda_atual = 0
	ultimos_spawns.clear()
	_spawnar_horda()

func _spawnar_horda():
	proxima_pendente = false
	if estado != Estado.EM_COMBATE or not is_instance_valid(jogador_atual) or jogador_atual.vida <= 0: return
	var mapa = get_parent().get_parent()
	var candidatos: Array[Vector2] = []
	var corpo = CircleShape2D.new()
	corpo.radius = 10.0
	for x in range(retangulo.position.x+2, retangulo.end.x-2, 2):
		for y in range(retangulo.position.y+2, retangulo.end.y-2, 2):
			var pos: Vector2 = mapa.ponto_personagem(Vector2i(x,y))
			if pos.distance_to(jogador_atual.global_position) < 64: continue
			# Reserva também a área visual da caixa; independe da atualização da física.
			if mapa.zonas_caixas.any(func(zona): return zona.has_point(pos)): continue
			if ultimos_spawns.any(func(p): return p.distance_to(pos) < 24): continue
			var consulta = PhysicsShapeQueryParameters2D.new()
			consulta.shape = corpo
			consulta.transform = Transform2D(0, pos + Vector2(0,10))
			consulta.collision_mask = 5
			if get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty(): candidatos.append(pos)
	var escolhidos: Array[Vector2] = []
	for i in range(encontro.size()):
		if candidatos.is_empty(): break
		var indice_sorteado = mapa.rng.randi_range(0, candidatos.size()-1)
		var pos = candidatos[indice_sorteado]
		escolhidos.append(pos)
		candidatos = candidatos.filter(func(p): return p.distance_to(pos) >= 32)
		var cena = encontro[i] if horda_atual == 0 else mapa.tipos_inimigos[mapa.rng.randi_range(0, mapa.tipos_inimigos.size()-1)]
		var inimigo = cena.instantiate()
		inimigo.position = to_local(pos)
		inimigo.derrotado.connect(_derrotado.bind(inimigo), CONNECT_ONE_SHOT)
		add_child(inimigo)
		if inimigo.has_method("configurar_arena"):
			inimigo.configurar_arena(mapa.ponto_personagem(retangulo.get_center()), mapa._poligono(retangulo.grow(-3),Vector2(0,-12)))
		vivos.append(inimigo)
		criados.append(inimigo)
	ultimos_spawns = escolhidos
	if vivos.is_empty():
		_finalizar()

func _derrotado(inimigo: Node2D):
	vivos.erase(inimigo)
	if vivos.is_empty() and estado == Estado.EM_COMBATE:
		if horda_atual < hordas_extras and not proxima_pendente:
			horda_atual += 1
			proxima_pendente = true
			_spawnar_horda.call_deferred()
		else:
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
	proxima_pendente = false
	horda_atual = 0
	criados.clear()
	vivos.clear()
	estado = Estado.NAO_VISITADA
	for porta in portas: porta.definir_fechada(false)

func adicionar_porta(poligono: PackedVector2Array):
	var porta = Porta.new()
	porta.configurar(poligono)
	add_child(porta)
	portas.append(porta)
func limpar_por_atalho():
	if estado != Estado.EM_COMBATE: return
	# O desbloqueio também cancela hordas ainda pendentes nesta sala.
	hordas_extras = horda_atual
	proxima_pendente = false
	for inimigo in vivos.duplicate():
		if is_instance_valid(inimigo): inimigo.dano(inimigo.vida, Vector2.ZERO, false)
	if estado == Estado.EM_COMBATE: _finalizar()
