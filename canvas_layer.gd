extends CanvasLayer

@export var velocidade_subida: float = 0.3
@export var velocidade_descida: float = 0.5
var abrindo_pause = false
var transicao = false
@onready var tela_melhorias: Control = $TelaMelhorias
@onready var menu: Control = $TextureRect/visor/Menu
@onready var melhorias: Button = $TextureRect/visor/Menu/VBoxContainer/melhorias
@onready var vhs: ColorRect = $vhs
@onready var mao: TextureRect = $TextureRect
var visor: AnimatedSprite2D

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_parent().mouse_filter = Control.MOUSE_FILTER_IGNORE
	vhs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$TextureRect/visor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$TextureRect/visor/AnimatedSprite2D.hide()
	menu.reparent(mao)
	menu.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	menu.position = Vector2.ZERO
	menu.size = Vector2(960, 540)
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	melhorias.reparent(menu)
	menu.get_node("VBoxContainer/armas").queue_free()
	melhorias.focus_neighbor_top = NodePath()
	melhorias.focus_neighbor_bottom = NodePath()
	melhorias.position = Vector2(357, 373)
	melhorias.size = Vector2(191, 30)
	melhorias.text = ""
	for estado in ["normal", "hover", "pressed", "focus"]:
		var estilo = StyleBoxTexture.new()
		estilo.texture = preload("res://assets/interface_equipe/melhorias.png")
		if estado == "normal": estilo.modulate_color = Color(0.75, 0.65, 0.85)
		melhorias.add_theme_stylebox_override(estado, estilo)
	mao.texture = preload("res://assets/interface_equipe/pause.png")
	mao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mao.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	mao.size = Vector2(960, 540)
	visor = AnimatedSprite2D.new()
	visor.sprite_frames = preload("res://assets/interface_equipe/ligando.tres")
	visor.centered = false
	mao.add_child(visor)
	mao.move_child(visor, 0)
	visor.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	melhorias.pressed.connect(abrir_melhorias)
	get_viewport().size_changed.connect(ajustar)
	ajustar()
	menu.hide()
	mao.hide()

func ajustar():
	var tamanho = get_viewport().get_visible_rect().size
	mao.scale = Vector2.ONE * minf(tamanho.x / 960.0, tamanho.y / 540.0)
	mao.position = (tamanho - Vector2(960, 540) * mao.scale) / 2.0

func _input(event):
	if get_tree().has_group("dialogo_npc") or transicao: return
	if event.is_action_pressed("pause") and not event.is_echo():
		if tela_melhorias.visible: voltar_ao_menu()
		elif get_tree().paused: fechar_pause()
		else: abrir_pause()
		get_viewport().set_input_as_handled()

func abrir_pause():
	if abrindo_pause: return
	abrindo_pause = true
	transicao = true
	get_tree().paused = true
	vhs.show()
	menu.hide()
	mao.show()
	visor.show()
	visor.play("ligando")

func fechar_pause():
	if not abrindo_pause: return
	abrindo_pause = false
	transicao = true
	tela_melhorias.hide()
	mao.show()
	menu.hide()
	visor.show()
	visor.play_backwards("ligando")

func _on_animated_sprite_2d_animation_finished():
	transicao = false
	if abrindo_pause:
		visor.hide()
		menu.show()
		melhorias.grab_focus()
	else:
		mao.hide()
		vhs.hide()
		get_tree().paused = false

func abrir_melhorias():
	menu.hide()
	mao.hide()
	tela_melhorias.show()
	melhorias.release_focus()

func voltar_ao_menu():
	tela_melhorias.hide()
	mao.show()
	menu.show()
	melhorias.grab_focus()
