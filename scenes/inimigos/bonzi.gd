extends CharacterBody2D
signal derrotado

enum Acao { ESPERA, CIPO, QUEDA, PAUSA, COCOS, ARREMESSO, SURF, ROUBO, FURIA, CAIDO, MORTO }
var vida_maxima: float = 60.0
var vida: float = 60.0
var fase: int = 1
var acao = Acao.ESPERA
var tempo: float = 1.6
var centro: Vector2
var limites: PackedVector2Array
var jogador: Node2D
var sprite: AnimatedSprite2D
var alvo_queda: Vector2
var alvo_surf: Vector2
var quedas: int = 0
var ciclo: int = 0
var altura: float = 0.0
var lancados: int = 0
var cocos: Array[Dictionary] = []
var popup_tempo: float = 4.0
var interface: CanvasLayer
var raiz_ui: Control
var barra: ProgressBar
var titulo: Label
var popups: Array[Control] = []
var rng = RandomNumberGenerator.new()
var concluido: bool = false
var bananas: Array[Dictionary] = []
var item_roubado: Dictionary = {}
var textura_item_roubado: Texture2D
var item_solto: bool = false
var drop_roubado: Node2D
var banana_surf: float = 0.0
const PRANCHA = preload("res://assets/boss/prancha.svg")
var surf_acertou: bool = false
var apresentacao: float = 3.0
var efeitos: Control
var tremor: float = 0.0
var camera: Camera2D
var camera_offset: Vector2
const BANANA = preload("res://assets/boss/banana.png")
const COCO = preload("res://assets/boss/coco.png")
var flash_restante: float = 0.0
const Catalogo = preload("res://scenes/itens/melhorias.gd")

func configurar_arena(pos: Vector2, contorno: PackedVector2Array):
	centro = pos
	limites = contorno
	global_position = pos

func _ready():
	add_to_group("inimigos")
	z_index = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 1
	rng.randomize()
	jogador = get_tree().get_first_node_in_group("player")
	centro = global_position
	var colisao = CollisionShape2D.new()
	colisao.name = "Corpo"
	var forma = CircleShape2D.new()
	forma.radius = 15
	colisao.shape = forma
	colisao.position.y = 10
	add_child(colisao)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteFrames.new()
	for nome in ["Stand", "Atack", "Dead"]:
		sprite.sprite_frames.add_animation(nome)
		sprite.sprite_frames.add_frame(nome, preload("res://assets/boss/bonzi.png"))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * 0.75
	sprite.offset = Vector2(0,-60)
	sprite.position.y = 10
	sprite.modulate = Color(1.0,0.65,1.0)
	var material_bonzi = ShaderMaterial.new()
	material_bonzi.shader = preload("res://assets/boss/bonzi.gdshader")
	sprite.material = material_bonzi
	add_child(sprite)
	sprite.play("Stand")
	_criar_interface()
	camera = jogador.get_node_or_null("Camera2D")
	if camera: camera_offset = camera.offset
	jogador.controle_bloqueado = true
	jogador.velocity = Vector2.ZERO

func _physics_process(delta):
	if is_instance_valid(camera) and tremor > 0:
		tremor = maxf(0, tremor-delta)
		camera.offset = camera_offset + Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1))*4*tremor/0.35
	if apresentacao > 0:
		apresentacao = maxf(0, apresentacao-delta)
		efeitos.intro = apresentacao
		if apresentacao == 0: _liberar_jogador()
		return
	if acao == Acao.MORTO:
		flash_restante = maxf(0.0, flash_restante - delta)
		_atualizar_cor_sprite()
		return
	flash_restante = maxf(0.0, flash_restante - delta)
	if not is_instance_valid(jogador) or jogador.vida <= 0:
		_liberar_jogador()
		_atualizar_cor_sprite()
		return
	tempo -= delta
	popup_tempo -= delta
	if popup_tempo <= 0:
		_popup()
		popup_tempo = (7.0 / 1.5) if fase == 1 else 4.5
	_atualizar_cocos(delta)
	_atualizar_bananas(delta)
	match acao:
		Acao.ESPERA:
			if tempo <= 0:
				if fase == 2 and ciclo % 3 == 2:
					acao = Acao.FURIA
					tempo = 1.4
					_espalhar_bananas()
				elif ciclo % 2 == 0:
					quedas = 0
					_subir()
				else:
					acao = Acao.COCOS
					tempo = 1.6
					sprite.play("Atack")
		Acao.CIPO:
			altura = move_toward(altura, 280.0, delta*550.0)
			if tempo > 0.35:
				alvo_queda = _dentro_arena(alvo_queda.lerp(jogador.global_position, minf(1,delta*4)))
			if tempo <= 0:
				global_position = alvo_queda
				acao = Acao.QUEDA
				tempo = 0.25
		Acao.QUEDA:
			altura = 280.0 * maxf(0,tempo) / 0.25
			if tempo <= 0:
				altura = 0
				tremor = 0.35
				_explosao_queda()
				var casca = -1
				for i in range(bananas.size()):
					if global_position.distance_to(bananas[i].pos) < 24:
						casca = i
						break
				if casca >= 0:
					bananas.remove_at(casca)
					acao = Acao.CAIDO
					tempo = 5.0
					sprite.rotation = -PI*0.5
					$Corpo.set_deferred("disabled",false)
					_soltar_item()
					queue_redraw()
					return
				$Corpo.set_deferred("disabled",false)
				if jogador.global_position.distance_to(global_position) < (38 if fase == 1 else 46):
					jogador.dano(2, global_position.direction_to(jogador.global_position))
				quedas += 1
				acao = Acao.PAUSA
				tempo = 0.65 if fase == 1 else 0.45
		Acao.PAUSA:
			if tempo <= 0:
				if quedas < 3: _subir()
				else: _descansar()
		Acao.COCOS:
			if tempo <= 0:
				acao = Acao.ARREMESSO
				lancados = 0
				tempo = 0
		Acao.ARREMESSO:
			if tempo <= 0:
				var pos = global_position + Vector2(0,-18)
				var direcao = pos.direction_to(jogador.global_position)
				cocos.append({"pos":pos,"dir":direcao,"vida":4.0})
				lancados += 1
				tempo = 0.34 if fase == 1 else 0.23
				if lancados >= (3 if fase == 1 else 5): _descansar()
		Acao.SURF:
			if tempo > 1.6:
				global_position = centro
			else:
				_liberar_jogador()
				var progresso = clampf(1.0-tempo/1.6,0,1)
				var anterior = global_position
				global_position = alvo_surf + Vector2(lerpf(-480,480,progresso),0)
				banana_surf -= delta
				var pos_banana = global_position + Vector2(-32,10)
				if banana_surf <= 0:
					banana_surf = 0.13
					if Geometry2D.is_point_in_polygon(pos_banana,limites):
						bananas.append({"pos":pos_banana,"aviso":0.5,"vida":35.0,"queda":true})
						while bananas.size() > 18: bananas.pop_front()
				if progresso > 0.02 and not surf_acertou:
					var perto = Geometry2D.get_closest_point_to_segment(jogador.global_position,anterior,global_position)
					if perto.distance_to(jogador.global_position) < 24:
						jogador.dano(2,Vector2.RIGHT)
						surf_acertou = true
			if tempo <= 0:
				fase = 2
				global_position = centro
				_liberar_jogador()
				_roubar_item()
				acao = Acao.ROUBO
				tempo = 2.0
				$Corpo.set_deferred("disabled",false)
		Acao.ROUBO:
			sprite.position.x = sin(tempo*20)*3
			if tempo <= 0:
				sprite.position.x = 0
				_descansar()
		Acao.FURIA:
			sprite.position.x = sin(tempo*30)*3
			if tempo <= 0:
				sprite.position.x = 0
				_descansar()
		Acao.CAIDO:
			if tempo <= 0:
				sprite.rotation = 0
				_descansar()
	sprite.position.y = 10-altura
	sprite.visible = altura < 220
	if acao != Acao.SURF: sprite.flip_h = jogador.global_position.x < global_position.x
	barra.value = vida
	titulo.text = "BONZIBUDDY • FASE %d" % fase
	if acao == Acao.SURF: titulo.text = "CUIDADO • INVESTIDA DE SURF"
	elif acao == Acao.ROUBO: titulo.text = "HA HA HA! • " + ("ITEM ROUBADO" if not item_roubado.is_empty() else "NADA PARA ROUBAR")
	elif acao == Acao.CAIDO: titulo.text = "BONZIBUDDY CAÍDO • DANO ×1,5"
	elif acao == Acao.FURIA: titulo.text = "CUIDADO COM AS BANANAS!"
	_atualizar_cor_sprite()
	queue_redraw()

func _subir():
	acao = Acao.CIPO
	tempo = 1.35 if fase == 1 else 1.0
	alvo_queda = _dentro_arena(jogador.global_position)
	$Corpo.set_deferred("disabled",true)

func _descansar():
	global_position = centro
	altura = 0
	acao = Acao.ESPERA
	tempo = 1.5 if fase == 1 else 0.9
	ciclo += 1
	$Corpo.set_deferred("disabled",false)
	sprite.show()
	sprite.play("Stand")

func _dentro_arena(pos: Vector2) -> Vector2:
	if limites.is_empty() or Geometry2D.is_point_in_polygon(pos,limites): return pos
	var perto = centro
	var distancia = INF
	for i in range(limites.size()):
		var candidato = Geometry2D.get_closest_point_to_segment(pos,limites[i],limites[(i+1)%limites.size()])
		if candidato.distance_squared_to(pos) < distancia:
			distancia = candidato.distance_squared_to(pos)
			perto = candidato
	return perto.lerp(centro,0.08)

func dano(valor: float, _direcao: Vector2 = Vector2.ZERO, _knockback: bool = true):
	if acao == Acao.MORTO or valor <= 0: return
	# O atalho de emergência continua podendo encerrar o encontro.
	if (apresentacao > 0 or acao in [Acao.CIPO,Acao.QUEDA,Acao.SURF]) and valor < vida: return
	flash_restante = 0.16
	_atualizar_cor_sprite()
	vida = maxf(0,vida-valor*(1.5 if acao == Acao.CAIDO else 1.0))
	if vida <= 0:
		apresentacao = 0
		efeitos.intro = 0
		acao = Acao.MORTO
		concluido = true
		_soltar_item()
		bananas.clear()
		sprite.rotation = 0
		_liberar_jogador()
		cocos.clear()
		for janela in popups:
			if is_instance_valid(janela): janela.queue_free()
		$Corpo.set_deferred("disabled",true)
		sprite.show()
		sprite.play("Dead")
		titulo.text = "BONZIBUDDY DERROTADO"
		barra.value = 0
		derrotado.emit()
		queue_redraw()
		return
	if fase == 1 and vida <= vida_maxima*0.5:
		acao = Acao.SURF
		tempo = 2.4
		altura = 0
		cocos.clear()
		$Corpo.set_deferred("disabled",true)
		alvo_surf = jogador.global_position
		surf_acertou = false
		banana_surf = 0
		jogador.controle_bloqueado = true
		jogador.velocity = Vector2.ZERO

		sprite.show()

func _atualizar_cor_sprite():
	var cor_normal = Color(1.0,0.85,0.95) if fase == 2 else Color.WHITE
	sprite.modulate = Color(1.5,0.6,0.6) if flash_restante > 0.0 else cor_normal

func _atualizar_cocos(delta):
	for i in range(cocos.size()-1,-1,-1):
		var coco = cocos[i]
		var destino: Vector2 = coco.pos + coco.dir * (135 if fase == 1 else 175) * delta
		coco.vida -= delta
		var raio = PhysicsRayQueryParameters2D.create(coco.pos+Vector2(0,10),destino+Vector2(0,10),1)
		if coco.vida <= 0 or not get_world_2d().direct_space_state.intersect_ray(raio).is_empty():
			cocos.remove_at(i)
			continue
		coco.pos = destino
		if destino.distance_to(jogador.global_position) < 14:
			jogador.dano(1,coco.dir)
			cocos.remove_at(i)

func _draw():
	if acao == Acao.MORTO: return
	for casca in bananas:
		var pos = to_local(casca.pos)
		if casca.get("queda",false): pos.y -= 42.0 * clampf(casca.aviso/0.5,0,1)
		draw_texture_rect(BANANA,Rect2(pos-Vector2(10,10),Vector2(20,20)),false,Color(1,1,1,0.5 if casca.aviso > 0 else 1))
	if acao == Acao.ROUBO and textura_item_roubado:
		draw_texture_rect(textura_item_roubado,Rect2(-12,-80,24,28),false)
	for coco in cocos: _desenhar_coco(to_local(coco.pos))
	if acao == Acao.COCOS:
		for i in range(3):
			var angulo = tempo*5 + i*TAU/3
			_desenhar_coco(Vector2(cos(angulo)*28,-45+sin(angulo)*14))
	if acao in [Acao.CIPO,Acao.QUEDA]:
		var ponto = to_local(alvo_queda) + Vector2(0,10)
		var distancia_chao = clampf(altura / 280.0,0,1)
		var raio_impacto = 38.0 if fase == 1 else 46.0
		var raio_sombra = lerpf(19.0,43.0,distancia_chao)
		var opacidade = lerpf(0.16,0.055,distancia_chao)
		draw_set_transform(ponto,0,Vector2(1,0.5))
		# Camadas translúcidas deixam a borda suave e o centro mais denso.
		for camada in range(5):
			draw_circle(Vector2.ZERO,raio_sombra*(1.0-camada*0.14),Color(0.025,0.015,0.06,opacidade),true,-1,true)
		var raio_aviso = lerpf(raio_impacto,raio_impacto+26.0,distancia_chao)
		var cor = Color(0.45,0.65,1.0,lerpf(0.9,0.45,distancia_chao))
		draw_arc(Vector2.ZERO,raio_aviso,0,TAU,72,Color(cor,0.12),5.0,true)
		draw_arc(Vector2.ZERO,raio_aviso,0,TAU,72,cor,1.2,true)
		for i in range(4):
			var angulo = i*PI*0.5
			draw_arc(Vector2.ZERO,raio_impacto,angulo-0.12,angulo+0.12,8,Color(0.7,0.85,1,0.65),1.5,true)
		draw_set_transform(Vector2.ZERO)
		if altura < 220: draw_line(Vector2(0,-300),Vector2(0,-35-altura),Color("6ea953"),3)
	if acao == Acao.SURF:
		draw_texture_rect(PRANCHA,Rect2(-42,4,84,20),false)

func _desenhar_coco(pos: Vector2):
	draw_texture_rect(COCO,Rect2(pos-Vector2(8,8),Vector2(16,16)),false)

func _criar_interface():
	interface = CanvasLayer.new()
	interface.layer = 15
	add_child(interface)
	raiz_ui = Control.new()
	raiz_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface.add_child(raiz_ui)
	titulo = Label.new()
	titulo.text = "BONZIBUDDY"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	titulo.offset_left = -260
	titulo.offset_right = 260
	titulo.offset_top = 132
	titulo.add_theme_font_size_override("font_size",24)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz_ui.add_child(titulo)
	barra = ProgressBar.new()
	barra.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	barra.offset_left = -356
	barra.offset_right = 356
	barra.offset_top = 74
	barra.offset_bottom = 121
	barra.max_value = vida_maxima
	barra.value = vida
	barra.show_percentage = false
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fundo = StyleBoxFlat.new()
	fundo.bg_color = Color(0.06,0.02,0.09,0.85)
	var preenchimento = StyleBoxFlat.new()
	preenchimento.bg_color = Color("a948d3")
	barra.add_theme_stylebox_override("background",fundo)
	barra.add_theme_stylebox_override("fill",preenchimento)
	raiz_ui.add_child(barra)
	var moldura = TextureRect.new()
	moldura.texture = preload("res://assets/boss/bossbar.png")
	moldura.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	moldura.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	moldura.offset_left = -360
	moldura.offset_right = 360
	moldura.offset_top = 36
	moldura.offset_bottom = 126
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz_ui.add_child(moldura)
	efeitos = preload("res://scenes/inimigos/efeitos_bonzi.gd").new()
	efeitos.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	efeitos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz_ui.add_child(efeitos)

func _popup():
	popups = popups.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
	if popups.size() >= 9: return
	var tamanho = get_viewport_rect().size
	var janela = PanelContainer.new()
	janela.custom_minimum_size = Vector2(380,230)
	janela.position = Vector2(rng.randf_range(tamanho.x*0.16,maxf(tamanho.x*0.16,tamanho.x-420)),rng.randf_range(110,maxf(110,tamanho.y-290)))
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color("050d19")
	estilo.border_color = Color("39baff")
	estilo.set_border_width_all(2)
	estilo.shadow_color = Color(0,0.5,1,0.24)
	estilo.shadow_size = 10
	estilo.content_margin_left = 12
	estilo.content_margin_right = 12
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	janela.add_theme_stylebox_override("panel",estilo)
	var mono = SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas","Courier New"])
	janela.add_theme_font_override("font",mono)
	janela.add_theme_color_override("font_color",Color("6acaff"))
	var coluna = VBoxContainer.new()
	janela.add_child(coluna)
	var cabecalho = HBoxContainer.new()
	coluna.add_child(cabecalho)
	var nome = Label.new()
	nome.text = "[ROOT] BONZI://INJECT.exe"
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecalho.add_child(nome)
	var fechar = Button.new()
	fechar.text = "X"
	fechar.custom_minimum_size = Vector2(38,32)
	cabecalho.add_child(fechar)
	fechar.pressed.connect(janela.queue_free)
	var texto = Label.new()
	texto.text = ["> INVASÃO DETECTADA\n> injetando bonzi.dll... [OK]\n> acesso ao sistema: ROOT","> FIREWALL COMPROMETIDO\n> interceptando controles...\n> processo hostil: ATIVO","> CONEXÃO NÃO AUTORIZADA\n> copiando dados do jogador...\n> permissões: SOBRESCRITAS"][rng.randi_range(0,2)]
	texto.add_theme_font_size_override("font_size",18)
	coluna.add_child(texto)
	var dados = Label.new()
	dados.text = "01001000 01000001 01000011 01001011\n0x%04X  //  SESSION HIJACKED" % rng.randi_range(0,65535)
	dados.add_theme_font_size_override("font_size",14)
	dados.add_theme_color_override("font_color",Color("237cbd"))
	coluna.add_child(dados)
	var carga = ProgressBar.new()
	carga.custom_minimum_size.y = 8
	carga.show_percentage = false
	carga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var verde = StyleBoxFlat.new()
	verde.bg_color = Color("30b6ff")
	carga.add_theme_stylebox_override("fill",verde)
	coluna.add_child(carga)
	var aviso = Label.new()
	aviso.text = "[!] SISTEMA SOB CONTROLE DO BONZI_"
	aviso.add_theme_font_size_override("font_size",14)
	coluna.add_child(aviso)
	raiz_ui.add_child(janela)
	var animacao = janela.create_tween()
	animacao.tween_property(carga,"value",100.0,1.2)
	var piscar = aviso.create_tween().set_loops()
	piscar.tween_property(aviso,"modulate:a",0.35,0.45)
	piscar.tween_property(aviso,"modulate:a",1.0,0.45)
	popups.append(janela)
	efeitos.glitch = 0.35

func _liberar_jogador():
	if is_instance_valid(jogador): jogador.controle_bloqueado = false

func _exit_tree():
	if is_instance_valid(camera): camera.offset = camera_offset
	_liberar_jogador()
	if not item_roubado.is_empty() and is_instance_valid(jogador):
		jogador.coletar_drop(item_roubado)
		if is_instance_valid(drop_roubado): drop_roubado.queue_free()
		item_roubado.clear()

func _notification(aviso):
	if not is_instance_valid(raiz_ui): return
	if aviso == NOTIFICATION_PAUSED: raiz_ui.hide()
	elif aviso == NOTIFICATION_UNPAUSED: raiz_ui.show()


func _roubar_item():
	var chip = -1
	if not jogador.equipados.is_empty():
		chip = jogador.equipados[0]
		jogador.equipados.remove_at(0)
	else:
		for i in range(jogador.inventario.size()):
			if jogador.inventario[i] > 0:
				chip = i
				break
	if chip >= 0:
		jogador.inventario[chip] -= 1
		jogador.recalcular_melhorias()
		item_roubado = {"tipo":"chip","chip":chip,"quantidade":1}
	elif jogador.moedas > 0:
		jogador.moedas -= 1
		jogador.moedas_label.text = str(jogador.moedas)
		item_roubado = {"tipo":"moeda","quantidade":1}

	if not item_roubado.is_empty():
		textura_item_roubado = Catalogo.icone(item_roubado.tipo,item_roubado.get("chip",0))

func _soltar_item():
	if item_roubado.is_empty() or item_solto: return
	item_solto = true
	drop_roubado = preload("res://scenes/itens/drop.gd").new()
	drop_roubado.dados = item_roubado.duplicate()
	# O item do jogador permanece recuperável até o fim da tentativa.
	drop_roubado.tempo_restante = INF
	drop_roubado.position = get_parent().to_local(global_position+Vector2(0,25))
	drop_roubado.recolhido.connect(func(): item_roubado.clear())
	get_parent().add_child.call_deferred(drop_roubado)

func _espalhar_bananas():
	if jogador.global_position.distance_to(global_position) < 140:
		jogador.direcao_recuo = global_position.direction_to(jogador.global_position)
		jogador.recuo_restante = 0.35
		jogador.current_state = jogador.PlayerState.HURT
		jogador.get_node("dano/CollisionShape2D").set_deferred("disabled",true)
	for i in range(7):
		var angulo = i*TAU/7 + rng.randf_range(-0.2,0.2)
		var pos = _dentro_arena(centro+Vector2(cos(angulo)*rng.randf_range(50,140),sin(angulo)*rng.randf_range(35,90)))
		bananas.append({"pos":pos,"aviso":0.9,"vida":35.0})
	while bananas.size() > 18: bananas.pop_front()

func _atualizar_bananas(delta):
	for i in range(bananas.size()-1,-1,-1):
		var casca = bananas[i]
		casca.aviso -= delta
		casca.vida -= delta
		if casca.vida <= 0:
			bananas.remove_at(i)
		elif casca.aviso <= 0 and jogador.tempo_escorregao <= 0 and not jogador.controle_bloqueado and jogador.global_position.distance_to(casca.pos) < 12:
			jogador.escorregar()
			bananas.remove_at(i)

func _explosao_queda():
	var efeito = AnimatedSprite2D.new()
	efeito.sprite_frames = preload("res://assets/explosao_boss/animacoes.tres")
	efeito.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	efeito.z_index = 2
	efeito.position = get_parent().to_local(global_position + Vector2(0,-8))
	efeito.animation_finished.connect(efeito.queue_free)
	get_parent().add_child(efeito)
	efeito.play("default")
