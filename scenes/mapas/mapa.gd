extends Node2D

const NPC = preload("res://scenes/mapas/npc.gd")
const Interacao = preload("res://scenes/mapas/interacao.gd")
var interacao: CanvasLayer
var limites: StaticBody2D
var zonas_caixas: Array[Rect2] = []
var leds: Node2D
var obstaculos_caixas: Array[PackedVector2Array] = []

const Sala = preload("res://scenes/mapas/sala.gd")
const Portal = preload("res://scenes/mapas/portal.gd")
const NOMES = {"inicio": "ENTRADA", "combate": "SEGURANÇA", "npc": "APOIO", "loja": "LOJA", "boss": "NÚCLEO", "portal": "SAÍDA"}
const DIRECOES = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
@export var seed_mapa: int = 0 # Zero sorteia; qualquer outro valor reproduz o mapa.
@export_range(2, 6) var combates_min: int = 3
@export_range(2, 6) var combates_max: int = 4
@export_range(1, 6) var inimigos_min: int = 2
@export_range(1, 6) var inimigos_max: int = 3
@export_range(19, 27, 2) var tamanho_sala: int = 23
@export_range(5, 9, 2) var largura_corredor: int = 5
@export var tipos_inimigos: Array[PackedScene] = [preload("res://scenes/inimigos/caveira_virus.tscn"), preload("res://scenes/inimigos/malware.tscn"), preload("res://scenes/inimigos/inimigo.tscn"), preload("res://scenes/inimigos/virus.tscn")]
@export var cena_boss: PackedScene
@export var cenas_npcs: Array[PackedScene] = []
@export var cena_vendedor: PackedScene
var seed_atual: int
var etapa: int = 1
var arena_final: bool = false
var sala_atual: int = 0
var salas: Array = []
var ligacoes: Array[Vector2i] = []
var piso: Dictionary = {}
var areas: Array[Rect2i] = []
var gerando: bool = false
var tempo_partida: float = 0.0
var partida_concluida: bool = false
var portal: Node2D
var rng = RandomNumberGenerator.new()
@onready var chao: TileMapLayer = $Chao
@onready var paredes: TileMapLayer = $Paredes
@onready var jogador = $player_base
@onready var objetivo: Label = $HUDMapa/Objetivo
@onready var tempo_label: Label = $HUDMapa/Tempo
@onready var resultado: Label = $HUDMapa/Resultado

func _ready():
	interacao = Interacao.new()
	add_child(interacao)
	limites = StaticBody2D.new()
	limites.name = "LimitesDoPiso"
	limites.collision_layer = 1
	limites.collision_mask = 0
	add_child(limites)
	RenderingServer.set_default_clear_color(Color("171421"))
	gerar(seed_mapa)

func _process(delta: float) -> void:
	if partida_concluida: return
	tempo_partida += delta
	tempo_label.text = "TEMPO %s" % _formatar_tempo(tempo_partida)

func _formatar_tempo(segundos: float) -> String:
	var total = floori(segundos)
	return "%02d:%02d" % [floori(float(total) / 60.0), total % 60]

func gerar(seed_nova: int = 0):
	if gerando:
		return
	interacao.fechar()
	gerando = true
	objetivo.hide()
	jogador.set_physics_process(false)
	get_tree().call_group("projeteis_player", "queue_free")
	get_tree().call_group("drops", "queue_free")
	portal = null
	for filho in $Salas.get_children():
		filho.free()
	sala_atual = 0
	salas.clear()
	ligacoes.clear()
	piso.clear()
	areas.clear()
	chao.clear()
	paredes.clear()
	obstaculos_caixas.clear()
	zonas_caixas.clear()
	if is_instance_valid(leds): leds.free()
	for filho in limites.get_children(): filho.free()
	if seed_nova == 0:
		rng.randomize()
		seed_atual = int(rng.randi())
	else:
		seed_atual = seed_nova
	rng.seed = seed_atual
	if arena_final:
		_adicionar_sala("inicio", Vector2i.ZERO)
		salas[0].visitada = true
		_adicionar_sala("boss", Vector2i.RIGHT)
		ligacoes.append(Vector2i(0,1))
	else:
		var quantidade = rng.randi_range(clampi(combates_min, 2, 6), clampi(maxi(combates_max, combates_min), 2, 6))
		var celula = Vector2i.ZERO
		_adicionar_sala("inicio", celula)
		salas[0].visitada = true
		# Caminho principal monotônico: não cruza a si mesmo nem sobrepõe salas.
		for i in range(quantidade + 2):
			celula += Vector2i.RIGHT if rng.randf() < 0.5 else Vector2i.DOWN
			var tipo = "combate" if i < quantidade else "boss" if i == quantidade else "portal"
			_adicionar_sala(tipo, celula)
			ligacoes.append(Vector2i(i, i + 1))
		# Sorteia entre todas as posições livres ligadas a salas de combate.
		var bases_especiais: Array[int] = []
		for tipo in ["npc", "loja"]:
			var opcoes: Array = []
			for base in range(1, quantidade + 1):
				if base in bases_especiais: continue
				for dir in DIRECOES:
					var candidata: Vector2i = salas[base].celula + dir
					if salas.any(func(s): return s.celula == candidata): continue
					var perto_final = salas.any(func(s): return s.tipo in ["boss", "portal"] and absi(s.celula.x-candidata.x) + absi(s.celula.y-candidata.y) <= 1)
					if not perto_final: opcoes.append({"base": base, "celula": candidata})
			if not opcoes.is_empty():
				var escolha = opcoes[rng.randi_range(0, opcoes.size()-1)]
				bases_especiais.append(escolha.base)
				_adicionar_sala(tipo, escolha.celula)
				ligacoes.append(Vector2i(escolha.base, salas.size()-1))
	for sala in salas:
		_preencher(sala.retangulo)
	for par in ligacoes:
		var a: Vector2i = salas[par.x].retangulo.get_center()
		var b: Vector2i = salas[par.y].retangulo.get_center()
		var meia = clampi(largura_corredor, 5, 9) / 2
		var canto = Vector2i(mini(a.x, b.x), mini(a.y, b.y)) - Vector2i(meia, meia)
		var dimensao = Vector2i(absi(b.x - a.x), absi(b.y - a.y)) + Vector2i.ONE * (meia * 2 + 1)
		_preencher(Rect2i(canto, dimensao))
	if not validar_conectividade():
		push_error("Mapa rejeitado: conectividade inválida, seed %d" % seed_atual)
		objetivo.text = "Falha na geração. Reinicie a partida."
		gerando = false
		return
	for c in piso:
		chao.set_cell(c, 0, Vector2i(1 if posmod(c.x, 9) == 0 else 2 if posmod(c.y, 11) == 0 else 0, 12))
		for x in range(-1, 2):
			for y in range(-1, 2):
				var vizinha: Vector2i = c + Vector2i(x,y)
				if not piso.has(vizinha):
					paredes.set_cell(vizinha, 0, Vector2i(8 if posmod(vizinha.x + vizinha.y, 4) == 0 else 7, 10))
	leds = preload("res://scenes/mapas/leds_dutos.gd").new()
	leds.z_index = -1
	for c in piso:
		if posmod(c.x,9) != 0 and posmod(c.y,11) != 0: continue
		var cantos = _poligono(Rect2i(c,Vector2i.ONE), Vector2(0,-8))
		for i in range(4):
			var vizinho = c + DIRECOES[i]
			if piso.has(vizinho) and (posmod(vizinho.x,9) == 0 or posmod(vizinho.y,11) == 0): continue
			leds.segmentos.append(PackedVector2Array([cantos[(i+1)%4],cantos[(i+2)%4]]))
	add_child(leds)
	chao.update_internals()
	paredes.update_internals()
	_criar_limites()
	var combates = salas.filter(func(s): return s.tipo in ["combate", "boss"])
	var candidatos_hordas = combates.duplicate()
	if etapa == 2 and not arena_final:
		for i in range(maxi(1, combates.size() / 2)):
			var indice = rng.randi_range(0, candidatos_hordas.size()-1)
			candidatos_hordas[indice].hordas_extras = 1
			candidatos_hordas.remove_at(indice)
	elif etapa == 3 and not arena_final:
		for sala in combates: sala.hordas_extras = 2
	for sala in salas:
		_montar_sala(sala)
	_criar_navegacao()
	NavigationServer2D.map_force_update(get_world_2d().navigation_map)
	_criar_portas()
	$OcclusionOutline.rebuild_masks.call_deferred()
	jogador.ponto_respawn = ponto_personagem(salas[0].retangulo.get_center())
	jogador.respawn()
	# O servidor de navegação e as colisões recebem as alterações antes de jogar.
	await get_tree().physics_frame
	await get_tree().physics_frame
	jogador.set_physics_process(true)
	gerando = false
	_atualizar_objetivo()
	$HUDMapa/Minimapa.queue_redraw()

func _adicionar_sala(tipo: String, celula: Vector2i):
	var sala = Sala.new()
	sala.name = "%02d_%s" % [salas.size(), tipo]
	sala.tipo = tipo
	sala.celula = celula
	sala.indice = salas.size()
	var lado = clampi(tamanho_sala, 19, 27)
	if lado % 2 == 0: lado += 1
	if tipo == "boss": lado = 29
	var centro = celula * 38
	sala.retangulo = Rect2i(centro - Vector2i.ONE * (lado / 2), Vector2i.ONE * lado)
	sala.y_sort_enabled = true
	$Salas.add_child(sala)
	salas.append(sala)
	sala.concluida.connect(_sala_concluida)

func _preencher(rect: Rect2i):
	areas.append(rect)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			piso[Vector2i(x,y)] = true

func ponto_personagem(c: Vector2i) -> Vector2:
	return chao.map_to_local(c) - Vector2(0, 12)

func _poligono(rect: Rect2i, deslocamento := Vector2.ZERO) -> PackedVector2Array:
	var origem = chao.map_to_local(Vector2i.ZERO)
	var eixo_x = chao.map_to_local(Vector2i.RIGHT) - origem
	var eixo_y = chao.map_to_local(Vector2i.DOWN) - origem
	var a = Vector2(rect.position) - Vector2.ONE * 0.5
	var b = Vector2(rect.end) - Vector2.ONE * 0.5
	var pontos = PackedVector2Array()
	for c in [a, Vector2(b.x,a.y), b, Vector2(a.x,b.y)]:
		pontos.append(origem + eixo_x * c.x + eixo_y * c.y + deslocamento)
	return pontos

func _criar_navegacao():
	var geometria = NavigationMeshSourceGeometryData2D.new()
	for rect in areas:
		geometria.add_traversable_outline(_poligono(rect, Vector2(0, -12)))
	for contorno in obstaculos_caixas: geometria.add_obstruction_outline(contorno)
	var poligono = NavigationPolygon.new()
	poligono.agent_radius = 9.0
	NavigationServer2D.bake_from_source_geometry_data(poligono, geometria)
	$Navegacao.navigation_polygon = poligono

func _montar_sala(sala):
	var centro = sala.retangulo.get_center()
	var pos = ponto_personagem(centro)
	# Cobre toda a sala: não permite contornar o encontro andando junto às paredes.
	# As barreiras ficam dois tiles no corredor, atrás de quem acabou de entrar.
	sala.configurar_area(_poligono(sala.retangulo))
	sala.rotulo = Label.new()
	sala.rotulo.text = NOMES[sala.tipo]
	sala.rotulo.position = pos + Vector2(-100, -56)
	sala.rotulo.size.x = 200
	sala.rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sala.rotulo.add_theme_font_size_override("font_size", 12)
	sala.rotulo.modulate = Color("cebafa")
	sala.add_child(sala.rotulo)
	sala.rotulo.hide()
	if sala.tipo in ["npc", "loja"]: sala.rotulo.position.y -= 100
	for offset in [Vector2i(-5, -5), Vector2i(5, 5), Vector2i(-5, 5), Vector2i(5, -5), Vector2i(0,-6), Vector2i(0,6), Vector2i(-6,0), Vector2i(6,0)]:
		sala.pontos.append(ponto_personagem(centro + offset))
	if sala.tipo == "combate" and not tipos_inimigos.is_empty():
		for i in range(rng.randi_range(clampi(inimigos_min, 1, 6), clampi(maxi(inimigos_min, inimigos_max), 1, 6))):
			sala.encontro.append(tipos_inimigos[rng.randi_range(0, tipos_inimigos.size()-1)])
	elif sala.tipo == "boss":
		if arena_final:
			sala.encontro.append(preload("res://scenes/inimigos/bonzi.tscn"))
		elif cena_boss:
			sala.encontro.append(cena_boss)
		else:
			sala.encontro.assign([preload("res://scenes/inimigos/inimigo.tscn"), preload("res://scenes/inimigos/virus.tscn")])
			sala.rotulo.text = "NÚCLEO • ENCONTRO FINAL"
	elif sala.tipo == "npc":
		for i in range(3):
			var ponto = _marcador(sala, "NPC%d" % (i+1), sala.pontos[i])
			if i < cenas_npcs.size() and cenas_npcs[i]: ponto.add_child(cenas_npcs[i].instantiate())
		if cenas_npcs.is_empty():
			for i in range(3):
				var npc = NPC.new()
				npc.papel = ["guia", "medica", "tecnico"][i]
				sala.get_node("NPC%d" % (i+1)).add_child(npc)
	elif sala.tipo == "loja":
		var vendedor = _marcador(sala, "Vendedor", pos)
		if cena_vendedor: vendedor.add_child(cena_vendedor.instantiate())
		else:
			var npc = NPC.new()
			npc.papel = "vendedor"
			vendedor.add_child(npc)
		for i in range(3): _marcador(sala, "Item%d" % (i+1), sala.pontos[i])
	elif sala.tipo == "portal":
		portal = Portal.new()
		portal.position = pos
		sala.add_child(portal)
		portal.utilizado.connect(_avancar)
		sala.rotulo.position.y -= 28
	_decorar_sala(sala)
	_marcar_luz(sala, pos)

func _marcador(sala, nome: String, pos: Vector2) -> Marker2D:
	var ponto = Marker2D.new()
	ponto.name = nome
	ponto.position = pos
	sala.add_child(ponto)
	return ponto

func _marcar_luz(sala, pos: Vector2):
	var luz = PointLight2D.new()
	luz.texture = preload("res://assets/luz/light.jpg")
	luz.position = pos
	luz.color = Color("8164d6") if sala.tipo not in ["boss", "loja"] else Color("d48394")
	luz.energy = 0.6
	luz.texture_scale = 1.6
	sala.add_child(luz)

func validar_conectividade() -> bool:
	if salas.is_empty() or piso.is_empty(): return false
	for i in range(salas.size()):
		for j in range(i+1, salas.size()):
			if salas[i].retangulo.intersects(salas[j].retangulo): return false
	var fila: Array[Vector2i] = [salas[0].retangulo.get_center()]
	var vistos = {fila[0]: true}
	var indice = 0
	while indice < fila.size():
		var atual = fila[indice]
		indice += 1
		for dir in DIRECOES:
			var proxima: Vector2i = atual + dir
			if piso.has(proxima) and not vistos.has(proxima):
				vistos[proxima] = true
				fila.append(proxima)
	return vistos.size() == piso.size() and salas.all(func(s): return vistos.has(s.retangulo.get_center()))

func _sala_concluida(_sala):
	_atualizar_objetivo()
	if arena_final:
		partida_concluida = true
		var pontuacao = floori(tempo_partida)
		resultado.text = "PARTIDA CONCLUÍDA\nTEMPO %s\nPONTUAÇÃO %d" % [_formatar_tempo(tempo_partida), pontuacao]
		resultado.show()
		get_tree().paused = true

func _atualizar_objetivo():
	var restantes = salas.filter(func(s): return s.tipo in ["combate", "boss"] and s.estado != Sala.Estado.CONCLUIDA).size()
	if is_instance_valid(portal): portal.ativo = restantes == 0 and not arena_final
	if is_instance_valid(portal): portal.ultima_etapa = etapa == 3 and restantes == 0
	objetivo.text = "Setor %d • %d encontros restantes • M: mapa" % [etapa, restantes] if restantes > 0 else "Setor %d concluído • Vá à SAÍDA e pressione E • M: mapa" % etapa

func reiniciar_encontros():
	if gerando: return
	# Salas já concluídas ficam livres. Somente os encontros interrompidos reiniciam.
	for sala in salas: sala.reiniciar_encontro()
	_atualizar_objetivo()

func _avancar():
	if gerando or arena_final: return
	if etapa == 3: arena_final = true
	else: etapa += 1
	gerar.call_deferred(seed_atual + 1)

func _criar_portas():
	var largura = (clampi(largura_corredor,5,9) / 2) * 2 + 1
	for par in ligacoes:
		for indices in [par, Vector2i(par.y,par.x)]:
			var sala = salas[indices.x]
			if sala.tipo not in ["combate", "boss"]: continue
			var direcao: Vector2i = salas[indices.y].celula - sala.celula
			var centro: Vector2i = sala.retangulo.get_center()
			var canto: Vector2i
			var tamanho: Vector2i
			if direcao.x != 0:
				canto = Vector2i(sala.retangulo.end.x+1 if direcao.x>0 else sala.retangulo.position.x-2,centro.y-largura/2-1)
				tamanho = Vector2i(1,largura+2)
			else:
				canto = Vector2i(centro.x-largura/2-1,sala.retangulo.end.y+1 if direcao.y>0 else sala.retangulo.position.y-2)
				tamanho = Vector2i(largura+2,1)
			sala.adicionar_porta(_poligono(Rect2i(canto,tamanho)))

func _decorar_sala(sala):
	if arena_final: return
	var ocupadas: Array[Vector2] = []
	var quantidade = rng.randi_range(2, 6)
	var centro = sala.retangulo.get_center()
	for tentativa in range(80):
		if ocupadas.size() >= quantidade: break
		var celula = Vector2i(rng.randi_range(sala.retangulo.position.x+2, sala.retangulo.end.x-3), rng.randi_range(sala.retangulo.position.y+2, sala.retangulo.end.y-3))
		# Mantém os corredores centrais, NPCs e pontos de chegada livres.
		if absi(celula.x-centro.x) <= 2 or absi(celula.y-centro.y) <= 2: continue
		var pos = chao.map_to_local(celula)
		if sala.pontos.any(func(p): return p.distance_to(pos) < 40): continue
		if ocupadas.any(func(p): return p.distance_to(pos) < 38): continue
		ocupadas.append(pos)
		zonas_caixas.append(Rect2(pos-Vector2(40,48), Vector2(80,80)))
		var caixa = StaticBody2D.new()
		caixa.name = "Caixa%d" % ocupadas.size()
		caixa.position = pos
		caixa.z_index = 1
		caixa.collision_layer = 1
		caixa.collision_mask = 0
		var arte = Sprite2D.new()
		arte.texture = load("res://assets/tiles_epa/%s.png" % ("caixas3" if rng.randf() < 0.3 else "caixasolo"))
		arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		arte.position.y = -16
		caixa.add_child(arte)
		var base = PackedVector2Array([Vector2(-15,-7),Vector2(0,-15),Vector2(15,-7),Vector2(0,1)])
		var forma = CollisionPolygon2D.new()
		forma.polygon = base
		caixa.add_child(forma)
		sala.add_child(caixa)
		var contorno = PackedVector2Array()
		for ponto in base: contorno.append(pos + ponto - Vector2(0,10))
		obstaculos_caixas.append(contorno)
	if sala.tipo in ["inicio", "loja", "npc"]:
		var logo = Sprite2D.new()
		logo.texture = preload("res://assets/tiles_epa/logoledempolium.png")
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		logo.z_index = 2
		logo.position = chao.map_to_local(sala.retangulo.get_center() + Vector2i(-5, -5)) - Vector2(0, 8)
		sala.add_child(logo)




func _criar_limites():
	# Fecha cada aresta externa do piso: movimento e dash não atravessam emendas.
	for celula in piso:
		var cantos = _poligono(Rect2i(celula, Vector2i.ONE))
		for i in range(DIRECOES.size()):
			if piso.has(celula + DIRECOES[i]): continue
			var a = cantos[(i+1)%4]
			var b = cantos[(i+2)%4]
			var borda = CapsuleShape2D.new()
			borda.radius = 4.0
			borda.height = a.distance_to(b) + 8.0
			var colisao = CollisionShape2D.new()
			colisao.shape = borda
			colisao.position = (a+b)*0.5
			colisao.rotation = (b-a).angle() - PI*0.5
			limites.add_child(colisao)

func _unhandled_key_input(event: InputEvent):
	if not event is InputEventKey or not event.pressed or event.echo: return
	if not event.ctrl_pressed or event.alt_pressed or event.shift_pressed: return
	if gerando or get_tree().paused or jogador.vida <= 0: return
	if event.physical_keycode == KEY_P:
		_avancar()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_K:
		if sala_atual >= 0 and sala_atual < salas.size():
			salas[sala_atual].limpar_por_atalho()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_X:
		jogador.invulnerabilidade = 0.0
		jogador.dano(jogador.vida)
		get_viewport().set_input_as_handled()

