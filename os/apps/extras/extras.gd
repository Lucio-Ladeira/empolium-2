extends Control

@onready var details: Label = $Content/Details

func _on_diagnostics_pressed() -> void:
	var window_size: Vector2i = DisplayServer.window_get_size()
	var audio_status := "disponível" if AudioServer.get_bus_index("Master") >= 0 else "indisponível"
	var engine_version: Dictionary = Engine.get_version_info()
	details.text = "PLATAFORMA   %s\nTELA   %d × %d\nÁUDIO   %s\nMOTOR   %s" % [OS.get_name(), window_size.x, window_size.y, audio_status, engine_version.get("string", "desconhecido")]

func _on_archive_pressed() -> void:
	details.text = "EMPOLIUM 2\nArquivo local de demonstração\n\nA pasta do jogo fica em Pessoal › Jogos › Empolium 2. Lá você encontra as preferências e as partidas salvas deste perfil."
