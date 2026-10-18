extends Control
var expandido: bool = false
@onready var mapa = get_parent().get_parent()
func coordenada(celula: Vector2i) -> Vector2:
	return Vector2(celula.x - celula.y, (celula.x + celula.y) * 0.5)
func _process(_delta):
	queue_redraw()
func _unhandled_key_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		expandido = not expandido
		get_viewport().set_input_as_handled()
func _draw():
	if not is_instance_valid(mapa) or mapa.salas.is_empty(): return
	var dimensao = Vector2(270, 190) if expandido else Vector2(135, 94)
	draw_rect(Rect2(Vector2.ZERO, dimensao), Color(0.035,0.025,0.065,0.85))
	var minimo = Vector2(INF,INF)
	var maximo = Vector2(-INF,-INF)
	for sala in mapa.salas:
		var c = coordenada(sala.celula)
		minimo = minimo.min(c)
		maximo = maximo.max(c)
	var escala = minf((dimensao.x-28) / maxf(1,maximo.x-minimo.x), (dimensao.y-28) / maxf(1,maximo.y-minimo.y))
	var pontos: Array[Vector2] = []
	for sala in mapa.salas: pontos.append(Vector2(14,14) + (coordenada(sala.celula)-minimo)*escala)
	for par in mapa.ligacoes: draw_line(pontos[par.x], pontos[par.y], Color("655479"), 2)
	var proximo = 0
	var distancia = INF
	for i in range(mapa.salas.size()):
		var sala = mapa.salas[i]
		var d = mapa.ponto_personagem(sala.retangulo.get_center()).distance_squared_to(mapa.jogador.global_position)
		if d < distancia:
			distancia = d
			proximo = i
		var cor = Color("7b7097")
		if sala.estado == 2: cor = Color("78c4a0")
		if sala.estado == 1: cor = Color("ed797d")
		if sala.tipo == "boss": cor = Color("e9a57e")
		if sala.tipo == "portal": cor = Color("c8a3ff")
		draw_rect(Rect2(pontos[i]-Vector2(4,4),Vector2(8,8)), cor)
		if expandido:
			var nomes = {"inicio":"I", "combate":"C", "npc":"N", "loja":"L", "boss":"B", "portal":"P"}
			draw_string(ThemeDB.fallback_font, pontos[i]+Vector2(5,-5), nomes[sala.tipo], HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	draw_arc(pontos[proximo], 7, 0, TAU, 20, Color.WHITE, 1)
	if expandido:
		draw_string(ThemeDB.fallback_font, Vector2(4,dimensao.y+13), "I início · C combate · N apoio · L loja · B núcleo · P portal", HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
