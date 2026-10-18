extends CanvasLayer

const Catalogo = preload("res://scenes/itens/melhorias.gd")
var fonte: Node2D
var aberto: bool = false
var modo_venda: bool = false
var fundo: Control
var titulo: Label
var descricao: Label
var saldo: Label
var retorno: Label
var lista: VBoxContainer
var abas: HBoxContainer

func _ready():
	add_to_group("interacao_npc")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	fundo = Control.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var escuro = ColorRect.new()
	escuro.color = Color(0.02,0.01,0.05,0.78)
	escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.add_child(escuro)
	var painel = PanelContainer.new()
	painel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	painel.offset_left = -235
	painel.offset_top = -144
	painel.offset_right = 235
	painel.offset_bottom = 144
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color("28243e")
	estilo.border_color = Color("a895d0")
	estilo.set_border_width_all(2)
	estilo.content_margin_left = 14
	estilo.content_margin_right = 14
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	painel.add_theme_stylebox_override("panel",estilo)
	fundo.add_child(painel)
	var coluna = VBoxContainer.new()
	coluna.add_theme_constant_override("separation",4)
	painel.add_child(coluna)
	titulo = _texto(coluna,18)
	descricao = _texto(coluna,12)
	descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	saldo = _texto(coluna,12)
	saldo.modulate = Color("f2d282")
	abas = HBoxContainer.new()
	coluna.add_child(abas)
	_botao(abas,"Comprar",_mudar_modo.bind(false))
	_botao(abas,"Vender",_mudar_modo.bind(true))
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 85
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(scroll)
	lista = VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lista)
	retorno = _texto(coluna,11)
	retorno.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	retorno.custom_minimum_size.y = 28
	_botao(coluna,"Fechar • Esc / E",fechar)
	fundo.hide()

func _texto(pai: Node, tamanho: int) -> Label:
	var label = Label.new()
	label.add_theme_font_size_override("font_size",tamanho)
	pai.add_child(label)
	return label

func _botao(pai: Node, texto: String, acao: Callable) -> Button:
	var botao = Button.new()
	botao.text = texto
	botao.add_theme_font_size_override("font_size",12)
	botao.pressed.connect(acao)
	pai.add_child(botao)
	return botao

func abrir(npc: Node2D):
	if aberto or get_tree().paused or not npc.perto(): return
	fonte = npc
	aberto = true
	modo_venda = false
	add_to_group("dialogo_npc")
	get_tree().paused = true
	retorno.text = ""
	fundo.show()
	atualizar()

func fechar():
	if not aberto: return
	aberto = false
	remove_from_group("dialogo_npc")
	fundo.hide()
	fonte = null
	get_tree().paused = false

func _input(event: InputEvent):
	if not aberto: return
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E):
		get_viewport().set_input_as_handled()
		fechar()

func atualizar():
	if not aberto or not is_instance_valid(fonte): return
	for filho in lista.get_children():
		lista.remove_child(filho)
		filho.queue_free()
	titulo.text = fonte.NOMES[fonte.papel]
	var p = fonte.jogador
	saldo.text = "Engrenagens: %d   |   Vida: %d/%d   |   Estamina: %d/%d" % [p.moedas,p.vida,p.vida_maxima,p.estamina,p.estamina_maxima]
	abas.visible = fonte.papel == "vendedor"
	match fonte.papel:
		"vendedor":
			descricao.text = "Compro chips livres pela metade do preço." if modo_venda else "Estoque por setor. Equipe os chips pelo pause > Melhorias."
			for i in range(5):
				var item = Catalogo.ITENS[i]
				var quantidade = p.inventario[i] - p.equipados.count(i) if modo_venda else fonte.estoque[i]
				var preco = maxi(1,fonte.precos[i]/2) if modo_venda else fonte.precos[i]
				var texto = "%s Nv.%d • %s • %d engr. • %s %d" % [item.nome,item.nivel,item.descricao.split("\n")[0],preco,"livres:" if modo_venda else "estoque:",quantidade]
				var botao = _botao(lista,texto,_negociar.bind(i))
				botao.icon = Catalogo.icone("chip",i)
				botao.add_theme_constant_override("icon_max_width",14)
				botao.disabled = quantidade <= 0 or (not modo_venda and p.moedas < preco)
			if not modo_venda:
				var cura = _botao(lista,"Reparo • +1 PV • %d engr. • estoque: %d" % [fonte.preco_cura,fonte.curas],_negociar.bind(-1))
				cura.disabled = fonte.curas <= 0 or p.moedas < fonte.preco_cura or p.vida >= p.vida_maxima
		"guia":
			descricao.text = "Sou Atlas. Vou te ajudar a atravessar este setor."
			var dica = _texto(lista,13)
			dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			dica.text = "• As barreiras fecham ao entrar em combate. Derrote todos para sair.\n• M amplia o mapa. Apoio e loja ficam nos caminhos laterais.\n• Colete engrenagens e equipe chips pelo pause.\n• Limpe os combates e o núcleo, depois use E no portal."
		"medica", "tecnico":
			descricao.text = "Posso recuperar toda a sua vida, uma vez por setor." if fonte.papel == "medica" else "Posso recarregar toda a sua estamina, uma vez por setor."
			var botao = _botao(lista,"Recuperar gratuitamente",_servico)
			botao.disabled = fonte.servico_usado or (p.vida >= p.vida_maxima if fonte.papel == "medica" else p.estamina >= p.estamina_maxima)
			if fonte.servico_usado: _texto(lista,12).text = "Atendimento já utilizado neste setor."

func _negociar(indice: int):
	if not aberto or not is_instance_valid(fonte): return
	retorno.text = fonte.vender(indice) if modo_venda else fonte.comprar(indice)
	atualizar()

func _mudar_modo(venda: bool):
	modo_venda = venda
	atualizar()

func _servico():
	if not aberto or not is_instance_valid(fonte): return
	retorno.text = fonte.atender()
	atualizar()
