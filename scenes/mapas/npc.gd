extends Node2D

const Catalogo = preload("res://scenes/itens/melhorias.gd")
const NOMES = {"guia":"Atlas • Guia", "medica":"Íris • Médica", "tecnico":"Byte • Técnico", "vendedor":"Comércio"}
@export_enum("guia", "medica", "tecnico", "vendedor") var papel: String = "guia"
@export var precos: Array[int] = [20, 25, 20, 50, 60]
@export var preco_cura: int = 10
var estoque: Array[int] = [0,0,0,0,0]
var ofertas: Array[int] = []
var curas: int = 3
var servico_usado: bool = false
var jogador: Node2D
var legenda: Label
var conversa: CanvasLayer

func _ready():
	add_to_group("npcs")
	var mapa = get_tree().get_first_node_in_group("mapas")
	var etapa = clampi(mapa.etapa if mapa else 1,1,3)
	var comuns = [0,1,2]
	var raros = [3,4]
	comuns.shuffle()
	raros.shuffle()
	for i in range(4-etapa): ofertas.append(comuns[i])
	for i in range(etapa-1): ofertas.append(raros[i])
	for i in ofertas: estoque[i] = 1
	jogador = get_tree().get_first_node_in_group("player")
	conversa = get_tree().get_first_node_in_group("interacao_npc")
	legenda = Label.new()
	legenda.position = Vector2(-75,-50)
	legenda.size.x = 150
	legenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legenda.add_theme_font_size_override("font_size",9)
	add_child(legenda)
	var arte = AnimatedSprite2D.new()
	arte.sprite_frames = preload("res://assets/mercador/animacoes.tres")
	arte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arte.scale = Vector2.ONE * 0.75
	arte.position = Vector2(0,-12)
	add_child(arte)
	arte.play("default")
	queue_redraw()

func perto() -> bool:
	if not is_instance_valid(jogador) or jogador.vida <= 0: return false
	if jogador.global_position.distance_to(global_position) > 48: return false
	var raio = PhysicsRayQueryParameters2D.create(global_position+Vector2(0,12),jogador.global_position+Vector2(0,12),1)
	return get_world_2d().direct_space_state.intersect_ray(raio).is_empty()

func _process(_delta):
	legenda.text = "[E] Negociar" if perto() else ""

func _unhandled_key_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E and perto():
		# Se dois NPCs estiverem próximos, somente o mais próximo responde.
		for outro in get_tree().get_nodes_in_group("npcs"):
			if outro != self and outro.global_position.distance_squared_to(jogador.global_position) < global_position.distance_squared_to(jogador.global_position): return
		if is_instance_valid(conversa):
			conversa.abrir(self)
			get_viewport().set_input_as_handled()

func comprar(indice: int) -> String:
	if papel != "vendedor" or not perto(): return "Aproxime-se do comerciante."
	if indice < -1 or indice >= estoque.size(): return "Item inválido."
	var custo = preco_cura if indice == -1 else precos[indice]
	if custo < 0: return "Preço indisponível."
	if (curas if indice == -1 else estoque[indice]) <= 0: return "Esgotado neste setor."
	if jogador.moedas < custo: return "Engrenagens insuficientes."
	var dados = {"tipo":"cura","quantidade":1} if indice == -1 else {"tipo":"chip","quantidade":1,"chip":indice}
	if not jogador.coletar_drop(dados): return "Sua vida já está cheia."
	# Débito somente depois que o item foi entregue. Sem await entre as operações.
	Sons.tocar("comprou-comp")
	jogador.moedas -= custo
	jogador.moedas_label.text = str(jogador.moedas)
	if indice == -1: curas -= 1
	else: estoque[indice] -= 1
	jogador.melhorias_alteradas.emit()
	return "Cura aplicada: +1 PV." if indice == -1 else "Chip comprado! Equipe no pause > Melhorias."

func vender(indice: int) -> String:
	if papel != "vendedor" or not perto(): return "Aproxime-se do comerciante."
	if indice < 0 or indice >= estoque.size(): return "Item inválido."
	if jogador.inventario[indice] <= jogador.equipados.count(indice): return "Sem chip livre. Remova-o dos equipamentos antes de vender."
	jogador.inventario[indice] -= 1
	jogador.coletar_drop({"tipo":"moeda","quantidade":maxi(1,precos[indice]/2)})
	return "Chip vendido."

func atender() -> String:
	if not perto(): return "Aproxime-se para conversar."
	if servico_usado: return "Já te ajudei neste setor. Encontre-me no próximo!"
	if papel == "medica":
		if jogador.vida >= jogador.vida_maxima: return "Você já está com a vida cheia."
		jogador.vida = jogador.vida_maxima
	elif papel == "tecnico":
		if jogador.estamina >= jogador.estamina_maxima: return "Sua estamina já está completa."
		jogador.estamina = jogador.estamina_maxima
	else: return "Boa exploração!"
	servico_usado = true
	jogador.melhorias_alteradas.emit()
	return "Pronto! Recuperação completa, sem custo."

func _draw():
	draw_set_transform(Vector2(0,12),0,Vector2(1,0.4))
	draw_circle(Vector2.ZERO,12,Color(0,0,0,0.35))
