extends CanvasLayer

var jogador: Node
var animacao: AnimatedSprite2D


func _ready():
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("dialogo_npc")
	get_tree().paused = true
	var fundo = ColorRect.new()
	fundo.color = Color.BLACK
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	animacao = AnimatedSprite2D.new()
	animacao.centered = false
	animacao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animacao.sprite_frames = preload("res://assets/game_over/animacao.tres")
	add_child(animacao)
	animacao.animation_finished.connect(_reaparecer)
	get_viewport().size_changed.connect(_ajustar)
	_ajustar()
	animacao.play("morte")

func _ajustar():
	var tamanho = get_viewport().get_visible_rect().size
	var fator = minf(tamanho.x / 960.0, tamanho.y / 540.0)
	animacao.scale = Vector2.ONE * fator
	animacao.position = (tamanho - Vector2(960,540) * fator) * 0.5

func _reaparecer():

	if is_instance_valid(jogador): jogador.respawn()
	get_tree().paused = false
	queue_free()

