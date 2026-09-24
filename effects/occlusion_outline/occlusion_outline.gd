extends Node

# Caminhos relativos ao nó do efeito, sem modificar cenas ou grupos existentes.
@export var world_path: NodePath
@export var player_sprite_path: NodePath
@export var occluder_paths: Array[NodePath] = []
@export var enabled: bool = true
@export var debug_shortcuts: bool = true

var world: Node2D
var player_sprite: Sprite2D
var occluders: Array[Node2D] = []
@export var outline_color := Color(0.1, 0.9, 1.0, 1.0)
@export_range(1, 4, 1) var width_px: int = 2
@export_enum("Outline", "Full mask", "Visible mask", "Hidden mask") var debug_view: int = 0

const MASK_SHADER = preload("res://effects/occlusion_outline/mask.gdshader")
const OUTLINE_SHADER = preload("res://effects/occlusion_outline/outline.gdshader")

var full_view: SubViewport
var visible_view: SubViewport
var overlay: ColorRect
var composite: ShaderMaterial
var white: ShaderMaterial
var black: ShaderMaterial
var pairs: Array[Dictionary] = []
var backgrounds: Array[ColorRect] = []
var mask_roots: Array[Node2D] = []

func _ready() -> void:
	white = _mask_material(1.0)
	black = _mask_material(0.0)
	full_view = _make_view("FullMask")
	visible_view = _make_view("VisibleMask")

	var layer := CanvasLayer.new()
	layer.name = "OutlineOverlay"
	layer.layer = 10
	add_child(layer)
	overlay = ColorRect.new()
	overlay.name = "Composite"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	composite = ShaderMaterial.new()
	composite.shader = OUTLINE_SHADER
	composite.set_shader_parameter("full_mask", full_view.get_texture())
	composite.set_shader_parameter("visible_mask", visible_view.get_texture())
	overlay.material = composite
	layer.add_child(overlay)
	rebuild_masks()
	RenderingServer.frame_pre_draw.connect(_sync)

func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(_sync):
		RenderingServer.frame_pre_draw.disconnect(_sync)

func _resolve_sources() -> void:
	occluders.clear()
	world = get_node_or_null(world_path) as Node2D
	player_sprite = get_node_or_null(player_sprite_path) as Sprite2D
	for path in occluder_paths:
		var occluder := get_node_or_null(path) as Node2D
		assert(is_instance_valid(occluder), "Oclusor inválido: %s" % path)
		assert(occluder is Sprite2D or occluder is TileMapLayer,
			"O oclusor deve ser Sprite2D ou TileMapLayer.")
		if occluder is TileMapLayer:
			var tiles := occluder as TileMapLayer
			if tiles.tile_set != null:
				for i in tiles.tile_set.get_source_count():
					assert(tiles.tile_set.get_source(tiles.tile_set.get_source_id(i)) is TileSetAtlasSource,
						"A máscara aceita somente TileSetAtlasSource; Scene Tiles não são copiados.")
		occluders.append(occluder)
	assert(is_instance_valid(world), "Defina World Path no Inspector.")
	assert(is_instance_valid(player_sprite), "Defina Player Sprite Path no Inspector.")
	assert(world.is_ancestor_of(player_sprite), "O Sprite2D deve estar dentro de World.")

func _mask_material(value: float) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = MASK_SHADER
	result.set_shader_parameter("mask_value", value)
	return result

func _make_view(node_name: String) -> SubViewport:
	var view := SubViewport.new()
	view.name = node_name
	view.size = Vector2i(2, 2)
	view.world_2d = World2D.new()
	view.disable_3d = true
	view.transparent_bg = false
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(view)
	var background_layer := CanvasLayer.new()
	background_layer.layer = -100
	view.add_child(background_layer)
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(background)
	backgrounds.append(background)
	return view

# Chame de forma deferred depois de editar celulas, adicionar/remover
# objetos, mudar as referências ou reordenar a arvore durante o jogo.
func rebuild_masks() -> void:
	_resolve_sources()
	pairs.clear()
	for root in mask_roots:
		root.get_parent().remove_child(root)
		root.queue_free()
	mask_roots.clear()
	for view in [full_view, visible_view]:
		var root := _copy_branch(world, view == visible_view)
		view.add_child(root)
		mask_roots.append(root)
	_sync()

func _copy_branch(source: Node2D, with_occluders: bool) -> Node2D:
	var copy: Node2D
	var is_player := source == player_sprite
	var is_occluder := with_occluders and source in occluders
	if source is Sprite2D and (is_player or is_occluder):
		copy = Sprite2D.new()
		copy.material = white if is_player else black
	elif source is TileMapLayer and is_occluder:
		var original := source as TileMapLayer
		var tiles := TileMapLayer.new()
		tiles.tile_set = original.tile_set
		tiles.tile_map_data = original.tile_map_data
		tiles.collision_enabled = false
		tiles.navigation_enabled = false
		tiles.occlusion_enabled = false
		tiles.collision_visibility_mode = TileMapLayer.DEBUG_VISIBILITY_MODE_FORCE_HIDE
		tiles.navigation_visibility_mode = TileMapLayer.DEBUG_VISIBILITY_MODE_FORCE_HIDE
		tiles.material = black
		copy = tiles
	else:
		# Preserva a hierarquia de ordenacao, sem duplicar logica ou fisica.
		copy = Node2D.new()
	copy.name = source.name
	pairs.append({"source": source, "copy": copy})
	for child in source.get_children():
		if child is Node2D:
			copy.add_child(_copy_branch(child, with_occluders))
	return copy

func _sync() -> void:
	var main_view := get_viewport()
	# Converte a área lógica para a resolução real de renderização.
	# Em Godot 4.7, ViewportTexture.get_size() de uma Window pode aplicar
	# o stretch novamente; isso encolhe e desloca a máscara na composição.
	# O retângulo transformado também respeita as barras de aspect ratio.
	var raster_rect: Rect2 = main_view.get_stretch_transform() * main_view.get_visible_rect()
	var size := Vector2i(raster_rect.size.round())
	size = size.max(Vector2i(2, 2))
	for view in [full_view, visible_view]:
		if view.size != size:
			view.size = size
		view.canvas_transform = (
			main_view.get_stretch_transform()
			* main_view.global_canvas_transform
			* main_view.canvas_transform
		)
		# A transformação afeta o mundo, mas não o CanvasLayer do fundo.
		view.global_canvas_transform = Transform2D.IDENTITY
		view.canvas_item_default_texture_filter = main_view.canvas_item_default_texture_filter
		view.canvas_item_default_texture_repeat = main_view.canvas_item_default_texture_repeat
		view.snap_2d_transforms_to_pixel = main_view.snap_2d_transforms_to_pixel
		view.snap_2d_vertices_to_pixel = main_view.snap_2d_vertices_to_pixel
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_DISABLED
		view.canvas_cull_mask = main_view.canvas_cull_mask
	for background in backgrounds:
		background.size = Vector2(size)
	overlay.position = main_view.get_visible_rect().position
	overlay.size = main_view.get_visible_rect().size
	overlay.visible = enabled
	composite.set_shader_parameter("outline_color", outline_color)
	composite.set_shader_parameter("width_px", width_px)
	composite.set_shader_parameter("debug_view", debug_view)

	for pair in pairs:
		var source := pair["source"] as Node2D
		var copy := pair["copy"] as Node2D
		if not is_instance_valid(source):
			copy.hide()
			continue
		copy.transform = source.transform
		copy.visible = source.visible
		copy.z_index = source.z_index
		copy.z_as_relative = source.z_as_relative
		copy.y_sort_enabled = source.y_sort_enabled
		copy.show_behind_parent = source.show_behind_parent
		copy.visibility_layer = source.visibility_layer
		copy.texture_filter = source.texture_filter
		copy.texture_repeat = source.texture_repeat
		copy.modulate = Color(1.0, 1.0, 1.0, source.modulate.a)
		copy.self_modulate = Color(1.0, 1.0, 1.0, source.self_modulate.a)
		if copy is Sprite2D:
			var sprite := source as Sprite2D
			var mirror := copy as Sprite2D
			mirror.texture = sprite.texture
			mirror.hframes = sprite.hframes
			mirror.vframes = sprite.vframes
			mirror.frame = sprite.frame
			mirror.centered = sprite.centered
			mirror.offset = sprite.offset
			mirror.flip_h = sprite.flip_h
			mirror.flip_v = sprite.flip_v
			mirror.region_enabled = sprite.region_enabled
			mirror.region_rect = sprite.region_rect
			mirror.region_filter_clip_enabled = sprite.region_filter_clip_enabled
		elif copy is TileMapLayer:
			var tiles := source as TileMapLayer
			var mirror := copy as TileMapLayer
			mirror.enabled = tiles.enabled
			mirror.y_sort_origin = tiles.y_sort_origin
			mirror.x_draw_order_reversed = tiles.x_draw_order_reversed

# Atalhos exclusivos da cena de teste; não alteram o Input Map do projeto.
func _unhandled_key_input(event: InputEvent) -> void:
	if not debug_shortcuts or not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_F1:
		enabled = not enabled
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F2:
		debug_view = (debug_view + 1) % 4
		get_viewport().set_input_as_handled()
