extends Node2D

const Catalogo = preload("res://scenes/itens/melhorias.gd")
var dados: Dictionary
var atraso: float = 0.35
var coletado: bool = false
var jogador: Node2D

func _ready():
	add_to_group("drops")
	z_index = 3
	jogador = get_tree().get_first_node_in_group("player")
	var sprite = Sprite2D.new()
	sprite.texture = Catalogo.icone(dados.tipo, dados.get("chip", 0))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * 0.65
	add_child(sprite)
	var legenda = Label.new()
	legenda.text = "x%d" % dados.quantidade if dados.tipo == "moeda" else "+1 PV" if dados.tipo == "cura" else "Chip"
	legenda.position = Vector2(-12, 8)
	legenda.add_theme_font_size_override("font_size", 8)
	add_child(legenda)

func _physics_process(delta):
	atraso -= delta
	if coletado or atraso > 0 or not is_instance_valid(jogador) or jogador.vida <= 0:
		return
	if global_position.distance_to(jogador.global_position) > 22:
		return
	var raio = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, 10), jogador.global_position + Vector2(0, 10), 1)
	if not get_world_2d().direct_space_state.intersect_ray(raio).is_empty():
		return
	if jogador.coletar_drop(dados):
		coletado = true
		queue_free()
