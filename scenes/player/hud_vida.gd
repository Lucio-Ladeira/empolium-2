extends Control

const BARRAS = [preload("res://assets/interface_equipe/vida25.png"), preload("res://assets/interface_equipe/vida50.png"), preload("res://assets/interface_equipe/vida75.png"), preload("res://assets/interface_equipe/vida100.png")]
var jogador: Node
var barra: TextureRect

func _ready():
	jogador = get_parent().get_parent()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	offset_left = 24
	offset_top = 24
	offset_right = 486
	offset_bottom = 330
	scale = Vector2(3, 3)
	barra = TextureRect.new()
	var material_percentual = ShaderMaterial.new()
	material_percentual.shader = preload("res://scenes/player/percentual_branco.gdshader")
	barra.material = material_percentual
	barra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	barra.size = Vector2(154, 77)
	barra.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(barra)

func _process(_delta):
	var proporcao = float(jogador.vida) / maxi(1, jogador.vida_maxima)
	barra.texture = BARRAS[clampi(ceili(proporcao * 4.0) - 1, 0, 3)]
	barra.visible = jogador.vida > 0


