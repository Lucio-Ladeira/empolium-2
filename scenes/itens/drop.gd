extends Node2D

const Catalogo = preload("res://scenes/itens/melhorias.gd")
var dados: Dictionary
var atraso: float = 0.35
var coletado: bool = false
var tempo_restante: float = 30.0
var jogador: Node2D

func _ready():
	add_to_group("drops")
	z_index = 3
	jogador = get_tree().get_first_node_in_group("player")
	var sprite = Sprite2D.new()
	var icone = Catalogo.icone(dados.tipo, dados.get("chip", 0)).get_image()
	var imagem = Image.create(icone.get_width()+4, icone.get_height()+4, false, Image.FORMAT_RGBA8)
	imagem.blit_rect(icone, Rect2i(Vector2i.ZERO, icone.get_size()), Vector2i(2,2))
	sprite.texture = ImageTexture.create_from_image(imagem)
	var contorno = ShaderMaterial.new()
	contorno.shader = preload("res://scenes/itens/contorno_drop.gdshader")
	sprite.material = contorno
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * 0.65
	add_child(sprite)
	if dados.tipo == "moeda":
		var legenda = Label.new()
		legenda.text = "×%d" % dados.quantidade
		legenda.position = Vector2(-16, 10)
		legenda.size.x = 32
		legenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var fonte = SystemFont.new()
		fonte.font_names = PackedStringArray(["Consolas", "Courier New"])
		fonte.font_weight = 700
		legenda.add_theme_font_override("font", fonte)
		legenda.add_theme_font_size_override("font_size", 10)
		legenda.add_theme_color_override("font_color", Color("ffe49a"))
		legenda.add_theme_color_override("font_outline_color", Color("181225"))
		legenda.add_theme_constant_override("outline_size", 3)
		add_child(legenda)

func _physics_process(delta):
	tempo_restante -= delta
	if tempo_restante <= 0:
		queue_free()
		return
	modulate.a = clampf(tempo_restante / 2.0, 0.0, 1.0)
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
