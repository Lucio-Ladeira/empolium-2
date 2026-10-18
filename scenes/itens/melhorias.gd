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
		img.fill_rect(Rect2i(3, 5, 14, 14), Color("454c50"))
		img.fill_rect(Rect2i(5, 7, 10, 10), Color("9baaa8"))
		for rect in [Rect2i(8, 2, 4, 5), Rect2i(8, 17, 4, 5), Rect2i(0, 10, 5, 4), Rect2i(15, 10, 5, 4)]:
			img.fill_rect(rect, Color("9baaa8"))
		img.fill_rect(Rect2i(8, 10, 4, 4), Color("30303e"))
	elif tipo == "cura":
		img.fill_rect(Rect2i(0, 9, 6, 8), Color("abb9ba"))
		img.fill_rect(Rect2i(5, 6, 15, 14), Color("34344c"))
		img.fill_rect(Rect2i(7, 8, 11, 9), Color("7777a1"))
		img.fill_rect(Rect2i(9, 10, 7, 3), Color("ff2862"))
		img.fill_rect(Rect2i(11, 9, 3, 7), Color("ff2862"))
	else:
		img.fill_rect(Rect2i(2, 1, 16, 22), Color("15203b"))
		img.fill_rect(Rect2i(4, 3, 12, 18), ITENS[chip].cor)
		for x in [5, 9, 13]:
			img.fill_rect(Rect2i(x, 4, 2, 4), Color("f5d72c"))
			img.fill_rect(Rect2i(x, 12, 2, 8), Color("e3c623"))
	return ImageTexture.create_from_image(img)
