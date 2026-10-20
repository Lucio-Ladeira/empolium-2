extends RefCounted

const ITENS = [
	{"nome": "Potência", "nivel": 1, "descricao": "+5% de dano\nEspada e tiros.", "cor": Color("4266bd")},
	{"nome": "Vitalidade", "nivel": 1, "descricao": "+1 PV máximo", "cor": Color("349447")},
	{"nome": "Agilidade", "nivel": 1, "descricao": "+5% de velocidade\nMovimento normal.", "cor": Color("a13abe")},
	{"nome": "Energia", "nivel": 2, "descricao": "+100 de estamina\n+1 dash", "cor": Color("c33535")},
	{"nome": "Processador", "nivel": 2, "descricao": "+15% de dano\nEspada e tiros.", "cor": Color("33528f")}
]
const TABELA = {"comum": [1, 0.20, 0.10], "trojan": [2, 0.50, 0.30], "virus": [2, 0.50, 0.75]}

static func sortear(tipo: String, rng: RandomNumberGenerator) -> Array:
	var regra = TABELA[tipo]
	var itens: Array = [{"tipo": "moeda", "quantidade": regra[0]}]
	if rng.randf() < regra[1]:
		itens.append({"tipo": "cura", "quantidade": 1})
	if rng.randf() < regra[2]:
		itens.append({"tipo": "chip", "quantidade": 1, "chip": rng.randi_range(0, 2)})
	return itens

static func icone(tipo: String, chip: int = 0) -> Texture2D:
	var img = Image.create(20, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	if tipo == "moeda":
		var moeda = preload("res://assets/moeda_1.png").get_image()
		moeda.resize(24, 24, Image.INTERPOLATE_NEAREST)
		return ImageTexture.create_from_image(moeda)
	elif tipo == "cura":
		img.fill_rect(Rect2i(0, 9, 6, 8), Color("abb9ba"))
		img.fill_rect(Rect2i(5, 6, 15, 14), Color("34344c"))
		img.fill_rect(Rect2i(7, 8, 11, 9), Color("7777a1"))
		img.fill_rect(Rect2i(9, 10, 7, 3), Color("ff2862"))
		img.fill_rect(Rect2i(11, 9, 3, 7), Color("ff2862"))
	else:
		var arquivos = [5,3,2,4,1]
		var textura = load("res://assets/chips/chips_%d.png" % arquivos[chip]) as Texture2D
		var desenho = textura.get_image()
		var recorte = desenho.get_used_rect()
		desenho = desenho.get_region(recorte)
		var fator = minf(20.0/desenho.get_width(),24.0/desenho.get_height())
		desenho.resize(maxi(1,roundi(desenho.get_width()*fator)),maxi(1,roundi(desenho.get_height()*fator)),Image.INTERPOLATE_NEAREST)
		img.blit_rect(desenho,Rect2i(Vector2i.ZERO,desenho.get_size()),(img.get_size()-desenho.get_size())/2)
	return ImageTexture.create_from_image(img)

