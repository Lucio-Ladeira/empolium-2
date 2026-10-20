extends CanvasLayer

const Catalogo = preload("res://scenes/itens/melhorias.gd")
var fonte: Node2D
var aberto: bool = false
var entrada: float = 1.0
var animacao_compra: Tween
var modo_venda: bool = false
var fundo: Control
var titulo: Label
var descricao: Label
var saldo: Label
var retorno: Label
var lista: VBoxContainer
var painel: PanelContainer
var compra: Control
var slots: Array[Button] = []
var saldo_compra: Label
var aviso_compra: Label
var abas: HBoxContainer

func _ready():
	add_to_group("interacao_npc")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	fundo = Control.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var tema = Theme.new()
	var fonte_quadrada = SystemFont.new()
	fonte_quadrada.font_names = PackedStringArray(["Consolas","Courier New"])
	fonte_quadrada.font_weight = 700
	fonte_quadrada.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	tema.default_font = fonte_quadrada
	tema.set_color("font_color","Label",Color("55356f"))
	tema.set_color("font_color","Button",Color("e3d7f4"))
	for estado in ["normal","hover","pressed","focus","disabled"]:
		var estilo_botao = StyleBoxFlat.new()
		estilo_botao.bg_color = Color("645184") if estado != "hover" else Color("8872ad")
		estilo_botao.border_color = Color("b7a6cb")
		estilo_botao.set_border_width_all(2)
		estilo_botao.content_margin_left = 10
		estilo_botao.content_margin_right = 10
		estilo_botao.content_margin_top = 5
		estilo_botao.content_margin_bottom = 5
		tema.set_stylebox(estado,"Button",estilo_botao)
	fundo.theme = tema
	var escuro = ColorRect.new()
	escuro.color = Color(0.02,0.01,0.05,0.78)
	escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.add_child(escuro)
	painel = PanelContainer.new()
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
	_criar_compra()
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
	Sons.tocar("abriu-comp")
	fonte = npc
	aberto = true
	modo_venda = false
	add_to_group("dialogo_npc")
	get_tree().paused = true
	retorno.text = ""
	fundo.show()
	atualizar()
	_animar_compra()

func fechar():
	if not aberto: return
	aberto = false
	if animacao_compra: animacao_compra.kill()
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
	painel.visible = modo_venda
	compra.visible = not modo_venda
	_atualizar_compra()
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
	var abrir_compra = modo_venda and not venda
	if abrir_compra: Sons.tocar("abriu-comp")
	modo_venda = venda
	atualizar()
	if abrir_compra: _animar_compra()

func _servico():
	if not aberto or not is_instance_valid(fonte): return
	retorno.text = fonte.atender()
	atualizar()

func _criar_compra():
	compra = Control.new()
	compra.size = Vector2(960,540)
	fundo.add_child(compra)
	var arte = TextureRect.new()
	arte.texture = preload("res://assets/interface_equipe/loja.png")
	arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	compra.add_child(arte)
	var posicoes = [Vector2(308,94),Vector2(484,94),Vector2(396,272)]
	for i in range(3):
		var slot = Button.new()
		slot.position = posicoes[i]
		slot.size = Vector2(170,170)
		slot.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
		slot.add_theme_stylebox_override("disabled",StyleBoxEmpty.new())
		var destaque = StyleBoxFlat.new()
		destaque.bg_color = Color(0.5,0.7,1,0.16)
		slot.add_theme_stylebox_override("hover",destaque)
		slot.add_theme_stylebox_override("pressed",destaque)
		slot.pressed.connect(_comprar_slot.bind(i))
		compra.add_child(slot)
		var icone = TextureRect.new()
		icone.name = "Icone"
		icone.position = Vector2(55,18)
		icone.size = Vector2(60,72)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icone)
		var nome = Label.new()
		nome.name = "Nome"
		nome.position = Vector2(0,92)
		nome.size = Vector2(170,32)
		nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nome.add_theme_font_size_override("font_size",13)
		nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(nome)
		var preco = Label.new()
		preco.name = "Preco"
		preco.position = Vector2(10,133)
		preco.size = Vector2(150,26)
		preco.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preco.add_theme_font_size_override("font_size",14)
		preco.add_theme_color_override("font_color",Color("55356f"))
		preco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(preco)
		slots.append(slot)
	var contador = HBoxContainer.new()
	contador.position = Vector2(320,25)
	contador.scale = Vector2(1.5,1.5)
	contador.add_theme_constant_override("separation",4)
	compra.add_child(contador)
	var engrenagem = TextureRect.new()
	var imagem = preload("res://assets/moeda_1.png").get_image()
	imagem.resize(48,48,Image.INTERPOLATE_NEAREST)
	engrenagem.texture = ImageTexture.create_from_image(imagem)
	engrenagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	engrenagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	engrenagem.custom_minimum_size = Vector2(24,24)
	engrenagem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var contorno = ShaderMaterial.new()
	contorno.shader = preload("res://scenes/itens/contorno_drop.gdshader")
	engrenagem.material = contorno
	contador.add_child(engrenagem)
	saldo_compra = _texto(contador,8)
	saldo_compra.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	saldo_compra.add_theme_font_override("font",preload("res://assets/interface_equipe/numeros_hud.fnt"))
	saldo_compra.add_theme_color_override("font_color",Color.WHITE)
	aviso_compra = _texto(compra,15)
	aviso_compra.position = Vector2(310,450)
	aviso_compra.size = Vector2(420,44)
	aviso_compra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var vender = _botao(compra,"Vender chips",_mudar_modo.bind(true))
	vender.position = Vector2(320,505)
	var sair = _botao(compra,"Fechar • Esc / E",fechar)
	sair.position = Vector2(510,505)

func _process(_delta):
	if not aberto: return
	var tela = get_viewport().get_visible_rect().size
	var escala = minf(tela.x/960.0,tela.y/540.0)
	compra.scale = Vector2.ONE*escala
	compra.position = (tela-Vector2(960,540)*escala)*0.5 + Vector2(0,(1.0-entrada)*tela.y*0.65)
	compra.modulate.a = lerpf(0.35,1.0,entrada)

func _atualizar_compra():
	saldo_compra.text = str(fonte.jogador.moedas)
	aviso_compra.text = retorno.text
	for slot in range(3):
		var indice = fonte.ofertas[slot]
		var item = Catalogo.ITENS[indice]
		var botao = slots[slot]
		botao.get_node("Icone").texture = Catalogo.icone("chip",indice)
		botao.get_node("Nome").text = "%s • Nv.%d" % [item.nome,item.nivel]
		botao.get_node("Preco").text = "%d engrenagens" % fonte.precos[indice] if fonte.estoque[indice] > 0 else "ESGOTADO"
		botao.tooltip_text = item.descricao
		botao.disabled = fonte.estoque[indice] <= 0 or fonte.jogador.moedas < fonte.precos[indice]

func _comprar_slot(slot: int):
	_negociar(fonte.ofertas[slot])

func _animar_compra():
	if animacao_compra: animacao_compra.kill()
	entrada = 0.0
	_process(0)
	animacao_compra = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	animacao_compra.tween_property(self,"entrada",1.0,0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
