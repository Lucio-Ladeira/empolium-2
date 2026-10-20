extends Node
var sons: Dictionary = {}
var passos: AudioStreamPlayer
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for nome in ["Shot","hit","dashslip","andando","portal","Comp-aberto","abriu-comp","comprou-comp"]:
		sons[nome] = load("res://assets/audio/efx/"+nome+".wav")
	passos = AudioStreamPlayer.new()
	passos.stream = sons["andando"].duplicate()
	passos.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	passos.stream.loop_end = int(passos.stream.get_length()*passos.stream.mix_rate)
	passos.volume_db = -23
	passos.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(passos)
func tocar(nome: String, volume: float = -12.0):
	if not sons.has(nome): sons[nome] = load("res://assets/audio/efx/"+nome+".wav")
	if not sons[nome]: return
	var audio = AudioStreamPlayer.new()
	audio.stream = sons[nome]
	audio.volume_db = volume
	audio.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()

func andar(ativo: bool):
	if not is_instance_valid(passos): return
	if ativo and not passos.playing: passos.play()
	elif not ativo: passos.stop()
