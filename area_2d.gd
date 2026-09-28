extends Area2D

@export var vlr_dano := 1

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("dash"):
		print("Inimigo viu player dar dash")

func _on_body_entered(body: Node2D) -> void:
	print("entrou")
	if body.has_method("dano"):
		body.dano(vlr_dano)
