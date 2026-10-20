extends Node
var tela: CanvasLayer
var reiniciando: bool = false
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and not event.alt_pressed and event.physical_keycode == KEY_R:
		get_viewport().set_input_as_handled()
		_reiniciar.call_deferred()
func _reiniciar():
	if reiniciando: return
	reiniciando = true
	if is_instance_valid(tela):
		tela.queue_free()
		tela = null
	for filho in get_tree().root.get_children():
		if filho.get_script() == preload("res://scenes/menus/tela_morte.gd"): filho.queue_free()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")
	reiniciando = false
func mostrar_creditos(tempo: String, pontuacao: int):
	if is_instance_valid(tela): return
	tela = CanvasLayer.new()
	tela.layer = 110
	add_child(tela)
	var fundo = ColorRect.new()
	fundo.color = Color("1683d4")
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela.add_child(fundo)
	var arte = TextureRect.new()
	arte.texture = preload("res://assets/interface_equipe/creditos.png")
	arte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arte.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.add_child(arte)
	var dados = Label.new()
	dados.text = "TEMPO %s\nPONTUAÇÃO %d" % [tempo, pontuacao]
	dados.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	dados.offset_left = -330.0
	dados.offset_top = -78.0
	dados.offset_right = -24.0
	dados.offset_bottom = -20.0
	dados.add_theme_color_override("font_color", Color("ebdcff"))
	dados.add_theme_color_override("font_outline_color", Color("14121f"))
	dados.add_theme_constant_override("outline_size", 5)
	dados.add_theme_font_size_override("font_size", 18)
	dados.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dados.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	dados.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_child(dados)
