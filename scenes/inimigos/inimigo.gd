extends CharacterBody2D

@export var vida: int = 3
@export var dano_por_area: int = 1

@onready var area_deteccao: Area2D = $Area2D



func _ready() -> void:
	# Detecta apenas objetos que estejam na camada "danos".
	#
	# Se "danos" for a camada 2:
	# 1 << 1
	#
	# Troque o número caso a camada "danos" esteja em outra posição.
	area_deteccao.collision_mask = 1 << 1

	area_deteccao.area_entered.connect(_on_area_deteccao_area_entered)


func _physics_process(_delta: float) -> void:
	# O inimigo permanece parado.
	velocity = Vector2.ZERO


func _on_area_deteccao_area_entered(area: Area2D) -> void:
	# Garante que somente áreas da camada "danos" causem dano.
	if not area.get_collision_layer_value(2):
		return

	receber_dano(dano_por_area)


func receber_dano(valor: int) -> void:
	vida -= valor

	print("Inimigo recebeu dano. Vida restante: ", vida)

	if vida <= 0:
		morrer()


func morrer() -> void:
	print("Inimigo morreu")

	queue_free()
