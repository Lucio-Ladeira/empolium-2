extends Node2D
var segmentos: Array[PackedVector2Array] = []
func _draw():
	for segmento in segmentos:
		draw_line(segmento[0], segmento[1], Color("681bc0"), 2.0)
		draw_line(segmento[0], segmento[1], Color("e28aff"), 0.8)
