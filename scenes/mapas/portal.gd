extends Node2D

signal utilizado
var ativo: bool = false
var usando: bool = false
var fase: float = 0.0
var jogador: Node2D
var legenda: Label

func _ready():
	name = "Portal"
	jogador = get_tree().get_first_node_in_group("player")
	legenda = Label.new()
	legenda.position = Vector2(-74, -52)
	legenda.size.x = 148
	legenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legenda.add_theme_font_size_override("font_size", 10)
	add_child(legenda)

func _process(delta):
	fase += delta
	legenda.text = "E • PRÓXIMO SETOR" if ativo else "Conclua os combates\ne o encontro final"
	queue_redraw()

func _unhandled_key_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		if tentar_usar():
			get_viewport().set_input_as_handled()

func tentar_usar() -> bool:
	if not ativo or usando or not is_instance_valid(jogador) or jogador.vida <= 0 or get_tree().paused:
		return false
	if jogador.global_position.distance_to(global_position) > 45:
		return false
	usando = true
	utilizado.emit()
	return true

func _draw():
	var cor = Color("a281ff") if ativo else Color("535568")
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.55))
	draw_circle(Vector2.ZERO, 26, Color(cor, 0.18))
	draw_arc(Vector2.ZERO, 26, 0, TAU, 48, cor, 3)
	draw_arc(Vector2.ZERO, 18, fase, fase + TAU * 0.75, 32, cor, 2)
	draw_set_transform(Vector2.ZERO)
	for i in range(6):
		var angulo = i * TAU / 6 + fase * 0.4
		var ponto = Vector2(cos(angulo) * 20, sin(angulo) * 9 - 10 - sin(fase * 2 + i) * 5)
		draw_rect(Rect2(ponto, Vector2(3, 5)), cor)
