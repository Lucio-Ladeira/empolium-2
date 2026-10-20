extends Control
var intro: float = 3.0
var glitch: float = 0.0
var codigo: Array[String] = []
var atualizar: float = 0.0
var fonte = ThemeDB.fallback_font

func _process(delta):
	size = get_viewport_rect().size
	glitch = maxf(0,glitch-delta)
	atualizar -= delta
	if glitch > 0 and atualizar <= 0:
		atualizar = 0.07
		codigo.clear()
		for y in range(int(size.y / 28)+1):
			var linha = ""
			for x in range(int(ceil((size.x+40) / maxf(1,fonte.get_string_size("0",HORIZONTAL_ALIGNMENT_LEFT,-1,20).x)))+2): linha += "0" if randf() < 0.5 else "1"
			codigo.append(linha)
	queue_redraw()

func _draw():
	if glitch > 0:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0,0.035,0.005,0.3))
		for i in range(codigo.size()):
			draw_string(fonte,Vector2((i%3-1)*10,i*28+22),codigo[i],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color(0.15,1,0.3,0.65))
		for i in range(4):
			draw_rect(Rect2(0,fmod(glitch*1500+i*197,size.y),size.x,3),Color(0.2,1,0.35,0.3))
	if intro > 0:
		var entrada = clampf((3.0-intro)*3,0,1)
		var opacidade = minf(entrada,intro*2)
		draw_rect(Rect2(0,0,size.x,110*entrada),Color(0,0,0,opacidade))
		draw_rect(Rect2(0,size.y-110*entrada,size.x,110*entrada),Color(0,0,0,opacidade))
		draw_rect(Rect2(0,size.y*0.43,size.x,130),Color(0.08,0.01,0.12,0.8*opacidade))
		var nome = "BONZIBUDDY"
		var largura = fonte.get_string_size(nome,HORIZONTAL_ALIGNMENT_LEFT,-1,62).x
		draw_string(fonte,Vector2((size.x-largura)/2+(1-entrada)*180,size.y*0.43+70),nome,HORIZONTAL_ALIGNMENT_LEFT,-1,62,Color(0.85,0.55,1,opacidade))
		var subtitulo = "SEU NOVO MELHOR INIMIGO"
		largura = fonte.get_string_size(subtitulo,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x
		draw_string(fonte,Vector2((size.x-largura)/2,size.y*0.43+107),subtitulo,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color(1,1,1,opacidade))
