extends Sprite2D

@export var animacoes: SpriteFrames
@export var protagonista: bool = false
@export var olha_esquerda: bool = false
@export var ancora: Vector2 = Vector2(32,62)
@export var escala_arte: float = 0.6
var atual: StringName = &""
var tempo: float = 0.0
var duracao_estado: float = 0.0
var morto: bool = false
@onready var corpo = get_parent()

func _ready():
	process_priority = 100
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame = 0
	hframes = 1
	vframes = 1
	scale = Vector2.ONE * escala_arte
	self_modulate = Color.WHITE
	if protagonista:
		# Preserva AnimationTree, tempos e hitboxes; substitui apenas os quadros visuais.
		var animador: AnimationPlayer = corpo.get_node("anim")
		for nome in animador.get_animation_list():
			var animacao = animador.get_animation(nome)
			for trilha in range(animacao.get_track_count()):
				if str(animacao.track_get_path(trilha)) == "sprites:frame":
					animacao.track_set_enabled(trilha,false)
	_atualizar(0)

func morrer():
	morto = true
	atual = &""
	tempo = 0
	var nome = corpo.get_node_or_null("Nome")
	if nome: nome.hide()
	_atualizar(0)

func reiniciar():
	morto = false
	atual = &""
	tempo = 0
	self_modulate = Color.WHITE
	var nome = corpo.get_node_or_null("Nome")
	if nome: nome.hide()
	show()
	_atualizar(0)

func _process(delta):
	_atualizar(delta)

func _atualizar(delta: float):
	if not animacoes: return
	var desejada: StringName = &"Stand"
	var direcao = corpo.last_direction if protagonista else corpo.velocity
	var sincronizar = false
	if protagonista:
		match corpo.current_state:
			corpo.PlayerState.DEATH, corpo.PlayerState.HURT: desejada = &"Damage"
			corpo.PlayerState.ATTACK: desejada = &"Attack"
			corpo.PlayerState.DASH: desejada = &"Walk"
			_:
				if corpo.velocity.length_squared()>1: desejada = &"Walk"
		if desejada == &"Walk" and corpo.current_state == corpo.PlayerState.MOVE and corpo.tiro_restante > 0 and animacoes.has_animation("Walk-fire"):
			desejada = &"Walk-fire"
		self_modulate.a = 0.5 if corpo.current_state==corpo.PlayerState.DEATH else 1.0
	elif "armado" in corpo and corpo.armado:
		desejada = &"Pre-explosion"
	elif morto:
		desejada = &"Dead"
	elif corpo.recuo_restante>0 and animacoes.has_animation("Damage"):
		desejada = &"Damage"
		sincronizar = true
	else:
		match corpo.estado:
			corpo.Estado.PREPARAR:
				desejada = &"Pre-atack"
				direcao = corpo.direcao
				sincronizar = true
			corpo.Estado.ATACAR:
				desejada = &"Dash-atack" if animacoes.has_animation("Dash-atack") and corpo.golpes%3==2 else &"Atack"
				direcao = corpo.direcao
				sincronizar = true
			corpo.Estado.RECUPERAR:
				desejada = &"Finish atack"
				sincronizar = true
			_:
				if corpo.velocity.length_squared()>1: desejada = &"Walk"
	if not animacoes.has_animation(desejada): desejada = &"Stand"
	if desejada != atual:
		atual = desejada
		tempo = 0
		duracao_estado = 0
		if sincronizar:
			if corpo.recuo_restante>0: duracao_estado=corpo.recuo_restante
			elif corpo.estado==corpo.Estado.ATACAR and "ataque_restante" in corpo: duracao_estado=corpo.ataque_restante
			else: duracao_estado=maxf(0.01,corpo.tempo)
	else:
		tempo += delta
	var total = 0.0
	for i in range(animacoes.get_frame_count(atual)): total += animacoes.get_frame_duration(atual,i)
	var fps = animacoes.get_animation_speed(atual)
	var cursor = tempo*fps
	if protagonista and atual == &"Attack": cursor = tempo / 0.25 * total
	if sincronizar and duracao_estado>0: cursor=tempo/duracao_estado*total
	if animacoes.get_animation_loop(atual) and not sincronizar: cursor=fmod(cursor,total)
	if morto and cursor>=total:
		corpo.hide()
		return
	var indice = animacoes.get_frame_count(atual)-1
	for i in range(animacoes.get_frame_count(atual)):
		cursor -= animacoes.get_frame_duration(atual,i)
		if cursor<0:
			indice=i
			break
	texture = animacoes.get_frame_texture(atual,indice)
	position = Vector2(0,13 if protagonista else 10)
	# O pivot acompanha o pé, inclusive quando o sprite é espelhado.
	if absf(direcao.x)>0.01: flip_h = direcao.x>0 if olha_esquerda else direcao.x<0
	offset = Vector2(ancora.x-32 if flip_h else 32-ancora.x,32-ancora.y)

