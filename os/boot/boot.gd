extends Control

signal boot_finished

@onready var status_label: Label = $Center/Content/Status
@onready var progress: ProgressBar = $Center/Content/Progress
@onready var detail_label: Label = $Center/Content/Detail
@onready var timer: Timer = $Timer

var messages: Array[String] = [
	"Carregando o ambiente de trabalho…",
	"Preparando suas preferências…",
	"Abrindo sua sessão…"
]
var index: int = 0

func _ready() -> void:
	$Center/Content.custom_minimum_size.x = minf(420.0, maxf(1.0, get_viewport_rect().size.x - 40.0))
	_show_message()
	timer.start()

func _show_message() -> void:
	status_label.text = messages[index]
	detail_label.text = "Etapa %d de %d" % [index + 1, messages.size()]
	progress.value = float(index + 1) / float(messages.size()) * 100.0

func _on_timer_timeout() -> void:
	index += 1
	if index >= messages.size():
		boot_finished.emit()
		return
	_show_message()
	timer.start()
