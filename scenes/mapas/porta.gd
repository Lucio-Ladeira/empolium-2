extends StaticBody2D

var poligono: PackedVector2Array
var fechada: bool = false

func configurar(pontos: PackedVector2Array):
	poligono = pontos
	collision_layer = 0
	collision_mask = 0
	z_index = 1
	y_sort_enabled = true
	var forma = CollisionPolygon2D.new()
	forma.polygon = poligono
	add_child(forma)
	visible = false
	_criar_campo()

func definir_fechada(valor: bool):
	fechada = valor
	visible = valor
	set_deferred("collision_layer", 1 if valor else 0)

func _criar_campo():
	if poligono.size() < 4: return
	var horizontal = poligono[0].distance_to(poligono[1]) > poligono[1].distance_to(poligono[2])
	var a = (poligono[0] + poligono[3]) * 0.5 if horizontal else (poligono[0] + poligono[1]) * 0.5
	var b = (poligono[1] + poligono[2]) * 0.5 if horizontal else (poligono[3] + poligono[2]) * 0.5
	# A colisão entra nas paredes; o desenho termina na abertura do corredor.
	var margem = a.direction_to(b) * Vector2(16, 8).length()
	a += margem + Vector2(0, 8)
	b += -margem + Vector2(0, 8)
	var quantidade = maxi(1, ceili(a.distance_to(b) / 8.0))
	for i in range(quantidade):
		var inicio = a.lerp(b, float(i) / quantidade)
		var fim = a.lerp(b, float(i+1) / quantidade)
		var trecho = Node2D.new()
		# O sprite do player usa o pé (y = 13) como origem na mesma camada 1.
		trecho.position = (inicio + fim) * 0.5
		add_child(trecho)
		var esquerda = inicio - trecho.position
		var direita = fim - trecho.position
		var altura = Vector2(0, 40)
		var superficie = Polygon2D.new()
		superficie.polygon = PackedVector2Array([esquerda, direita, direita-altura, esquerda-altura])
		superficie.color = Color(0.12, 0.5, 1, 0.28)
		trecho.add_child(superficie)
		for y in range(0, 41, 4):
			_linha(trecho, esquerda-Vector2(0,y), direita-Vector2(0,y), y == 0 or y == 40)
		if i == 0: _linha(trecho, esquerda, esquerda-altura, true)
		if i == quantidade-1: _linha(trecho, direita, direita-altura, true)

func _linha(pai: Node2D, a: Vector2, b: Vector2, borda: bool):
	var linha = Line2D.new()
	linha.points = PackedVector2Array([a,b])
	linha.default_color = Color(0.35,0.8,1,0.8) if borda else Color(0.3,0.75,1,0.3)
	linha.width = 1.2 if borda else 0.7
	linha.antialiased = true
	pai.add_child(linha)

