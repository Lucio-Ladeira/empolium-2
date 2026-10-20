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
func mostrar_creditos():
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
