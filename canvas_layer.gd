extends CanvasLayer


# ==================================================
# CONFIGURAÇÕES
# ==================================================

@export var velocidade_subida: float = 0.3
@export var velocidade_descida: float = 0.5


# ==================================================
# VARIÁVEIS
# ==================================================

var abrindo_pause: bool = false


# ==================================================
# REFERÊNCIAS
# ==================================================

@onready var menu: Control = $TextureRect/visor/Menu

@onready var melhorias: Button = $TextureRect/visor/Menu/VBoxContainer/melhorias
@onready var armas: Button = $TextureRect/visor/Menu/VBoxContainer/armas

@onready var vhs: ColorRect = $vhs

@onready var visor: AnimatedSprite2D = $TextureRect/visor/AnimatedSprite2D
@onready var mao: TextureRect = $TextureRect


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Menu começa escondido
	menu.visible = false
	
	# Permite que os botões recebam foco
	melhorias.focus_mode = Control.FOCUS_ALL
	armas.focus_mode = Control.FOCUS_ALL


# ==================================================
# INPUT DO PAUSE
# ==================================================

func _input(event):
	if event.is_action_pressed("pause"):
		
		# Se o jogo NÃO está pausado, abre o pause
		if not get_tree().paused:
			abrir_pause()
		
		# Se o jogo JÁ está pausado, fecha o pause
		else:
			fechar_pause()


# ==================================================
# ABRIR PAUSE
# ==================================================

func abrir_pause():
	# Impede abrir novamente enquanto já está abrindo
	if abrindo_pause:
		return
	
	abrindo_pause = true
	
	# Pausa o jogo
	get_tree().paused = true
	
	# Mostra o efeito VHS
	vhs.visible = true
	
	# Esconde o menu enquanto o visor liga
	menu.visible = false
	
	# Coloca a mão embaixo da tela
	mao.position.y = 900
	
	# Cria o Tween da subida
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	tween.tween_property(
		mao,
		"position:y",
		53.0,
		velocidade_subida
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Espera a mão chegar na posição
	await tween.finished
	
	# Liga o visor
	visor.play("ligando")


# ==================================================
# FECHAR PAUSE
# ==================================================

func fechar_pause():
	# Impede fechar novamente enquanto está abrindo
	if not abrindo_pause:
		return
	
	# Diz que estamos fechando
	abrindo_pause = false
	
	# Esconde o menu imediatamente
	menu.visible = false
	
	# Tira o foco dos botões
	melhorias.release_focus()
	armas.release_focus()
	
	# Desliga o visor usando a animação ao contrário
	visor.play_backwards("ligando")
	
	# Espera o visor terminar de desligar
	await visor.animation_finished
	
	# Cria o Tween da descida
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	tween.tween_property(
		mao,
		"position:y",
		900.0,
		velocidade_descida
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Espera a mão terminar de descer
	await tween.finished
	
	# Esconde o efeito VHS
	vhs.visible = false
	
	# Finalmente tira o jogo do pause
	get_tree().paused = false


# ==================================================
# ANIMAÇÃO DO VISOR TERMINOU
# ==================================================

func _on_animated_sprite_2d_animation_finished():
	# Se estamos fechando, não mostra o menu
	if not abrindo_pause:
		return
	
	# Mostra o menu
	menu.visible = true
	
	# Coloca o foco no botão Melhorias
	melhorias.grab_focus()
