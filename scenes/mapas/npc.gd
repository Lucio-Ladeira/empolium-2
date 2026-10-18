extends Node2D

const Catalogo = preload("res://scenes/itens/melhorias.gd")
const NOMES = {"guia":"Atlas • Guia", "medica":"Íris • Médica", "tecnico":"Byte • Técnico", "vendedor":"Nox • Comerciante"}
@export_enum("guia", "medica", "tecnico", "vendedor") var papel: String = "guia"
@export var precos: Array[int] = [4, 5, 4, 10, 12]
@export var preco_cura: int = 2
var estoque: Array[int] = [1,1,1,1,1]
var curas: int = 3
var servico_usado: bool = false
var jogador: Node2D
var legenda: Label
var conversa: CanvasLayer

func _ready():
	add_to_group("npcs")
	jogador = get_tree().get_first_node_in_group("player")
	conversa = get_tree().get_first_node_in_group("interacao_npc")
	legenda = Label.new()
	legenda.position = Vector2(-75,-50)
	legenda.size.x = 150
	legenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legenda.add_theme_font_size_override("font_size",9)
	add_child(legenda)
	queue_redraw()

func perto() -> bool:
	if not is_instance_valid(jogador) or jogador.vida <= 0: return false
	if jogador.global_position.distance_to(global_position) > 48: return false
	var raio = PhysicsRayQueryParameters2D.create(global_position+Vector2(0,12),jogador.global_position+Vector2(0,12),1)
	return get_world_2d().direct_space_state.intersect_ray(raio).is_empty()

func _process(_delta):
	legenda.text = NOMES[papel] + ("\n[E] Conversar" if perto() else "")

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
	jogador.moedas -= custo
	jogador.moedas_label.text = "Engrenagens: %d" % jogador.moedas
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
	var cor = {"guia":Color("7c83d8"),"medica":Color("62ba8c"),"tecnico":Color("d7a45d"),"vendedor":Color("a36ac2")}[papel]
	draw_set_transform(Vector2(0,12),0,Vector2(1,0.4))
	draw_circle(Vector2.ZERO,12,Color(0,0,0,0.35))
	draw_set_transform(Vector2.ZERO)
	# Robôs em pixel art, construídos com formas nativas na escala dos personagens.
	draw_rect(Rect2(-8,-11,16,21),Color("262b43"))
	draw_rect(Rect2(-7,-10,14,17),cor)
	draw_rect(Rect2(-9,-28,18,17),Color("262b43"))
	draw_rect(Rect2(-7,-26,14,13),cor.lightened(0.2))
	draw_rect(Rect2(-6,-23,12,6),Color("20263d"))
	for x in [-4,2]: draw_rect(Rect2(x,-21,2,2),Color("a3fbef"))
	for x in [-7,3]: draw_rect(Rect2(x,7,4,7),Color("343851"))
	for x in [-11,8]: draw_rect(Rect2(x,-9,3,13),cor.darkened(0.3))
	if papel == "medica":
		draw_rect(Rect2(-4,-4,8,3),Color.WHITE)
		draw_rect(Rect2(-1,-7,3,9),Color.WHITE)
	elif papel == "vendedor":
		draw_circle(Vector2(0,-2),4,Color("ecd37b"))
	else:
		draw_rect(Rect2(-4,-5,8,4),Color("a3fbef"))
