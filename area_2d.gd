extends Area2D

@export var vlr_dano := 1


func _on_body_entered(body: Node2D) -> void:
	print("entrou")
	if body.has_method("dano"):
		body.dano(vlr_dano)
