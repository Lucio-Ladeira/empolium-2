extends StaticBody2D

var poligono: PackedVector2Array
var fechada: bool = false

func configurar(pontos: PackedVector2Array):
	poligono = pontos
	collision_layer = 0
	collision_mask = 0
	z_index = 2
	var forma = CollisionPolygon2D.new()
	forma.polygon = poligono
	add_child(forma)
	visible = false

func definir_fechada(valor: bool):
	fechada = valor
	visible = valor
	set_deferred("collision_layer", 1 if valor else 0)
	queue_redraw()

func _draw():
	if poligono.is_empty(): return
	draw_colored_polygon(poligono, Color(0.75,0.15,0.4,0.6))
	var topo = PackedVector2Array()
	for p in poligono: topo.append(p - Vector2(0,24))
	draw_colored_polygon(topo, Color(1,0.2,0.4,0.25))
	for i in range(4):
		var a = poligono[i]
		var b = poligono[(i+1)%4]
		draw_line(a-Vector2(0,24),b-Vector2(0,24),Color("ff7395"),2)
		for passo in range(5):
			var ponto = a.lerp(b,passo/4.0)
			draw_line(ponto,ponto-Vector2(0,24),Color(1,0.3,0.5,0.5),1)
