extends CanvasLayer

const CRT_SHADER := preload("res://os/effects/crt_vhs.gdshader")
const TRANSITION_SECONDS := 0.38

var _crt_material: ShaderMaterial
var _changing_scene := false

func _ready() -> void:
	layer = 100
	var overlay := ColorRect.new()
	overlay.name = "CRTOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crt_material = ShaderMaterial.new()
	_crt_material.shader = CRT_SHADER
	overlay.material = _crt_material
	add_child(overlay)

func change_scene_with_transition(scene_path: String) -> void:
	if _changing_scene or not ResourceLoader.exists(scene_path):
		return
	_changing_scene = true
	await _animate_transition(0.0, 1.0)
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Não foi possível abrir a cena do jogo: %s" % scene_path)
		await _animate_transition(1.0, 0.0)
		_changing_scene = false
		return
	await get_tree().scene_changed
	await _animate_transition(1.0, 0.0)
	_changing_scene = false

func _animate_transition(from: float, to: float) -> void:
	var tween := create_tween()
	tween.tween_method(_set_transition_amount, from, to, TRANSITION_SECONDS)
	await tween.finished

func _set_transition_amount(value: float) -> void:
	_crt_material.set_shader_parameter("transition_amount", value)
