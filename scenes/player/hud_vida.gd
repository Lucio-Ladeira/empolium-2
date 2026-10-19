extends Control

const BARRAS = [preload("res://assets/hud_vida_estamina/19.png"), preload("res://assets/hud_vida_estamina/14.png"), preload("res://assets/hud_vida_estamina/6.png"), preload("res://assets/hud_vida_estamina/1.png")]
const ESTAMINA = [[preload("res://assets/hud_vida_estamina/23.png"), preload("res://assets/hud_vida_estamina/22.png"), preload("res://assets/hud_vida_estamina/21.png"), preload("res://assets/hud_vida_estamina/20.png")],
[preload("res://assets/hud_vida_estamina/18.png"), preload("res://assets/hud_vida_estamina/17.png"), preload("res://assets/hud_vida_estamina/16.png"), preload("res://assets/hud_vida_estamina/15.png")],
[preload("res://assets/hud_vida_estamina/10.png"), preload("res://assets/hud_vida_estamina/13.png"), preload("res://assets/hud_vida_estamina/12.png"), preload("res://assets/hud_vida_estamina/11.png")],
[preload("res://assets/hud_vida_estamina/5.png"), preload("res://assets/hud_vida_estamina/4.png"), preload("res://assets/hud_vida_estamina/3.png"), preload("res://assets/hud_vida_estamina/2.png")]]
var jogador: Node
var barra: TextureRect
var energia: TextureRect

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
	barra.size = Vector2(154, 154)
	barra.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(barra)
	energia = TextureRect.new()
	energia.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	energia.size = barra.size
	energia.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	energia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(energia)

func _process(_delta):
	var proporcao = float(jogador.vida) / maxi(1, jogador.vida_maxima)
	var nivel_vida = clampi(ceili(proporcao * 4.0)-1,0,3)
	barra.texture = BARRAS[nivel_vida]
	var nivel_energia = clampi(ceili(float(jogador.estamina)/maxi(1,jogador.estamina_maxima)*3.0),0,3)
	energia.texture = ESTAMINA[nivel_vida][nivel_energia]
	energia.visible = jogador.vida > 0
	barra.visible = jogador.vida > 0


