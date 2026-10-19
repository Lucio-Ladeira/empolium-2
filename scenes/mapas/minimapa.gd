extends Control
var expandido: bool = false
@onready var mapa = get_parent().get_parent()
func _ready():
	anchor_left = 1.0
	anchor_right = 1.0
	alinhar()
func alinhar():
	var diametro = 270.0 if expandido else 135.0
	offset_left = -24.0 - diametro * scale.x
	offset_right = offset_left + diametro
	offset_top = 24.0
	offset_bottom = offset_top + diametro
func coordenada(celula: Vector2i) -> Vector2:
	return Vector2(celula.x - celula.y, (celula.x + celula.y) * 0.5)
func reveladas() -> Dictionary:
	var vistas = {}
	for sala in mapa.salas:
		if sala.visitada: vistas[sala.indice] = true
	for par in mapa.ligacoes:
		if mapa.salas[par.x].visitada: vistas[par.y] = true
		if mapa.salas[par.y].visitada: vistas[par.x] = true
	return vistas
func _process(_delta):
	queue_redraw()
func _unhandled_key_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		expandido = not expandido
		alinhar()
		get_viewport().set_input_as_handled()
func _draw():
	if not is_instance_valid(mapa) or mapa.salas.is_empty(): return
	var vistas = reveladas()
	if vistas.is_empty(): return
	var dimensao = Vector2(270, 270) if expandido else Vector2(135, 135)
	draw_circle(dimensao * 0.5, dimensao.x * 0.5, Color(0.035,0.025,0.065,0.85))
	draw_arc(dimensao * 0.5, dimensao.x * 0.5 - 1, 0, TAU, 96, Color("00ffff"), 1.5, true)
	var minimo = Vector2(INF,INF)
	var maximo = Vector2(-INF,-INF)
	for i in vistas:
		var c = coordenada(mapa.salas[i].celula)
		minimo = minimo.min(c)
		maximo = maximo.max(c)
	var escala = (dimensao.x - 32.0) / maxf(1.0, (maximo - minimo).length())
	var centro = (minimo + maximo) * 0.5
	var pontos = {}
	for i in vistas:
		pontos[i] = dimensao * 0.5 + (coordenada(mapa.salas[i].celula)-centro)*escala
	for par in mapa.ligacoes:
		if vistas.has(par.x) and vistas.has(par.y) and (mapa.salas[par.x].visitada or mapa.salas[par.y].visitada):
			draw_line(pontos[par.x], pontos[par.y], Color.WHITE, 2)
	for i in vistas:
		var sala = mapa.salas[i]
		var cor = Color("50485e")
		if sala.visitada:
			cor = Color("7b7097")
			if sala.estado == 2: cor = Color("78c4a0")
			if sala.estado == 1: cor = Color("ed797d")
			if sala.tipo == "boss": cor = Color("e9a57e")
			if sala.tipo == "portal": cor = Color("c8a3ff")
		draw_rect(Rect2(pontos[i]-Vector2(4,4),Vector2(8,8)), cor, sala.visitada)
	if pontos.has(mapa.sala_atual):
		draw_arc(pontos[mapa.sala_atual], 7, 0, TAU, 20, Color.WHITE, 1)

