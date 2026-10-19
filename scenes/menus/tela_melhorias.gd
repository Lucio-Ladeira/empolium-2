extends Control

const Catalogo = preload("res://scenes/itens/melhorias.gd")
var pagina: int = 0
var slot_selecionado: int = 0
var jogador: Node
var equipamentos: Array[Button] = []
var descricao: Label
var equipar: Button
var mensagem: String = ""
@onready var controles: Control = $ControlesBraco
@onready var arte: TextureRect = $Arte
@onready var mao: TextureRect = $"../TextureRect"
@onready var slots: Array[Button] = [$ControlesBraco/Slot1, $ControlesBraco/Slot2, $ControlesBraco/Slot3]

func _ready():
	jogador = get_tree().get_first_node_in_group("player")
	for i in range(slots.size()):
		slots[i].pressed.connect(selecionar_slot.bind(i))
		slots[i].add_theme_font_size_override("font_size", 11)
		slots[i].expand_icon = true
		slots[i].add_theme_constant_override("icon_max_width", 22)
	$ControlesBraco/Anterior.pressed.connect(mudar_pagina.bind(-1))
	$ControlesBraco/Proximo.pressed.connect(mudar_pagina.bind(1))
	for i in range(6):
		var botao = criar_botao(Vector2(327 + (i % 2) * 63, 51 + (i / 2) * 63), Vector2(50, 50))
		botao.pressed.connect(remover.bind(i))
		equipamentos.append(botao)
	equipar = criar_botao(Vector2(352, 430), Vector2(97, 28))
	equipar.tooltip_text = "Equipar o chip selecionado"
	equipar.pressed.connect(equipar_selecionado)
	var info = criar_botao(Vector2(456, 430), Vector2(95, 28))
	info.tooltip_text = "Informações da melhoria"
	info.pressed.connect(atualizar_slots)
	descricao = Label.new()
	descricao.position = Vector2(474, 48)
	descricao.size = Vector2(158, 184)
	descricao.add_theme_font_size_override("font_size", 12)
	descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descricao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controles.add_child(descricao)
	if is_instance_valid(jogador):
		jogador.melhorias_alteradas.connect(atualizar_slots)
	visibility_changed.connect(atualizar_slots)
	visibility_changed.connect(ajustar_controles)
	resized.connect(ajustar_controles)
	ajustar_controles()
	atualizar_slots()

func criar_botao(pos: Vector2, tamanho: Vector2) -> Button:
	var botao = Button.new()
	botao.position = pos
	botao.size = tamanho
	botao.expand_icon = true
	botao.add_theme_constant_override("icon_max_width", 28)
	botao.add_theme_font_size_override("font_size", 12)
	for estilo in ["normal", "disabled"]:
		botao.add_theme_stylebox_override(estilo, slots[0].get_theme_stylebox("normal"))
	botao.add_theme_stylebox_override("hover", slots[0].get_theme_stylebox("hover"))
	controles.add_child(botao)
	return botao

func ajustar_controles():
	var fator = mao.size.x * mao.scale.x / 960.0
	var tamanho = Vector2(960, 540) * fator
	var posicao = Vector2((size.x - tamanho.x) / 2.0, size.y - tamanho.y)
	arte.scale = Vector2.ONE * fator
	arte.position = posicao
	controles.scale = Vector2.ONE * fator
	controles.position = posicao

func mudar_pagina(direcao: int):
	pagina = posmod(pagina + direcao, 2)
	slot_selecionado = pagina * 3
	mensagem = ""
	atualizar_slots()

func selecionar_slot(indice: int):
	slot_selecionado = pagina * 3 + indice
	mensagem = ""
	atualizar_slots()

func equipar_selecionado():
	if is_instance_valid(jogador):
		mensagem = "Equipado!" if jogador.equipar_chip(slot_selecionado) else "Sem chip livre ou slots cheios."
		atualizar_slots()

func remover(indice: int):
	if is_instance_valid(jogador):
		mensagem = ""
		jogador.remover_chip(indice)

func atualizar_slots():
	if not is_instance_valid(descricao):
		return
	for i in range(3):
		var indice = pagina * 3 + i
		slots[i].disabled = indice >= Catalogo.ITENS.size()
		slots[i].icon = Catalogo.icone("chip", indice) if indice < Catalogo.ITENS.size() else null
		var quantidade = jogador.inventario[indice] - jogador.equipados.count(indice) if is_instance_valid(jogador) and indice < 5 else 0
		slots[i].text = "x%d" % quantidade if indice < 5 else "—"
		slots[i].tooltip_text = Catalogo.ITENS[indice].nome if indice < 5 else "Vazio"
		slots[i].set_pressed_no_signal(indice == slot_selecionado)
	for i in range(6):
		var ocupado = is_instance_valid(jogador) and i < jogador.equipados.size()
		equipamentos[i].icon = Catalogo.icone("chip", jogador.equipados[i]) if ocupado else null
		equipamentos[i].text = "" if ocupado else "·"
		equipamentos[i].tooltip_text = "Remover: " + Catalogo.ITENS[jogador.equipados[i]].nome if ocupado else "Espaço de equipamento"
	var item = Catalogo.ITENS[slot_selecionado]
	var livres = jogador.inventario[slot_selecionado] - jogador.equipados.count(slot_selecionado) if is_instance_valid(jogador) else 0
	equipar.disabled = livres <= 0 or jogador.equipados.size() >= 6 if is_instance_valid(jogador) else true
	descricao.text = "%s • Nv. %d\n\n%s\n\n" % [item.nome, item.nivel, item.descricao]
	descricao.text += "Disponíveis: %d\nToque EQUIP para usar.\nToque no chip acima para remover." % livres if item.nivel == 1 else "Disponível na loja.\nSem drop de inimigos.\nDisponíveis: %d\nUse EQUIP para equipar." % livres
	if not mensagem.is_empty():
		descricao.text += "\n" + mensagem
