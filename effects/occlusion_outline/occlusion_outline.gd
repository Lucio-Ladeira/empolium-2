extends Node


# Nó raiz do mundo que será copiado para as máscaras.
@export var world_path: NodePath

# Selecione aqui um ou vários Sprite2D que receberão outline.
@export var outline_sprite_paths: Array[NodePath] = []

# Objetos que bloqueiam a outline.
@export var occluder_paths: Array[NodePath] = []

@export var enabled: bool = true
@export var debug_shortcuts: bool = true
@export var outline_color := Color(0.1, 0.9, 1.0, 1.0)

@export_range(1, 4, 1)
var width_px: int = 2

@export_enum(
	"Outline",
	"Full mask",
	"Visible mask",
	"Hidden mask"
)
var debug_view: int = 0


const MASK_SHADER = preload(
	"res://effects/occlusion_outline/mask.gdshader"
)

const OUTLINE_SHADER = preload(
	"res://effects/occlusion_outline/outline.gdshader"
)


var world: Node2D
var outline_sprites: Array[Sprite2D] = []
var occluders: Array[Node2D] = []

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

	composite.set_shader_parameter(
		"full_mask",
		full_view.get_texture()
	)

	composite.set_shader_parameter(
		"visible_mask",
		visible_view.get_texture()
	)

	overlay.material = composite
	layer.add_child(overlay)

	rebuild_masks()

	if not RenderingServer.frame_pre_draw.is_connected(_sync):
		RenderingServer.frame_pre_draw.connect(_sync)


func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(_sync):
		RenderingServer.frame_pre_draw.disconnect(_sync)


func _resolve_sources() -> void:
	outline_sprites.clear()
	occluders.clear()

	var world_object = get_node_or_null(world_path)

	if not is_instance_valid(world_object):
		push_error("Defina um World Path válido no Inspector.")
		world = null
		return

	world = world_object as Node2D

	if world == null:
		push_error("O World Path precisa apontar para um Node2D.")
		return

	# Resolve todos os Sprite2D selecionados para outline.
	for path in outline_sprite_paths:
		var sprite_object = get_node_or_null(path)

		if not is_instance_valid(sprite_object):
			push_warning(
				"Sprite de outline inválido ou removido: "
				+ str(path)
			)
			continue

		var sprite := sprite_object as Sprite2D

		if sprite == null:
			push_warning(
				"O caminho de outline não aponta para um Sprite2D: "
				+ str(path)
			)
			continue

		outline_sprites.append(sprite)

	# Resolve os objetos que bloqueiam a outline.
	for path in occluder_paths:
		var occluder_object = get_node_or_null(path)

		if not is_instance_valid(occluder_object):
			push_warning(
				"Oclusor inválido ou removido: "
				+ str(path)
			)
			continue

		var occluder := occluder_object as Node2D

		if occluder == null:
			push_warning(
				"O oclusor precisa ser um Node2D: "
				+ str(path)
			)
			continue

		if not (
			occluder is Sprite2D
			or occluder is TileMapLayer
		):
			push_warning(
				"O oclusor deve ser Sprite2D ou TileMapLayer: "
				+ str(path)
			)
			continue

		if occluder is TileMapLayer:
			var tiles := occluder as TileMapLayer

			if tiles.tile_set != null:
				for i in tiles.tile_set.get_source_count():
					var source_id := tiles.tile_set.get_source_id(i)
					var tile_source := tiles.tile_set.get_source(source_id)

					if not tile_source is TileSetAtlasSource:
						push_error(
							"A máscara aceita somente "
							+ "TileSetAtlasSource. "
							+ "Scene Tiles não são copiados."
						)

		occluders.append(occluder)


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
	view.canvas_item_default_texture_filter = (
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	)

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


# Chame esta função com call_deferred() depois de:
# - adicionar um novo objeto;
# - remover um objeto;
# - alterar os caminhos;
# - alterar os oclusores;
# - reorganizar a árvore.
func rebuild_masks() -> void:
	_resolve_sources()

	pairs.clear()

	for root in mask_roots:
		if not is_instance_valid(root):
			continue

		var root_parent := root.get_parent()

		if is_instance_valid(root_parent):
			root_parent.remove_child(root)

		root.queue_free()

	mask_roots.clear()

	if not is_instance_valid(world):
		return

	for view in [full_view, visible_view]:
		if not is_instance_valid(view):
			continue

		var root := _copy_branch(
			world,
			view == visible_view
		)

		view.add_child(root)
		mask_roots.append(root)

	_sync()


func _copy_branch(
	source: Node2D,
	with_occluders: bool
) -> Node2D:
	var copy: Node2D

	if not is_instance_valid(source):
		return Node2D.new()

	var is_outline := (
		source is Sprite2D
		and source in outline_sprites
	)

	var is_occluder := (
		with_occluders
		and source in occluders
	)

	if source is Sprite2D and (is_outline or is_occluder):
		copy = Sprite2D.new()

		if is_outline:
			copy.material = white
		else:
			copy.material = black

	elif source is TileMapLayer and is_occluder:
		var original := source as TileMapLayer
		var tiles := TileMapLayer.new()

		tiles.tile_set = original.tile_set
		tiles.tile_map_data = original.tile_map_data
		tiles.collision_enabled = false
		tiles.navigation_enabled = false
		tiles.occlusion_enabled = false

		tiles.collision_visibility_mode = (
			TileMapLayer.DEBUG_VISIBILITY_MODE_FORCE_HIDE
		)

		tiles.navigation_visibility_mode = (
			TileMapLayer.DEBUG_VISIBILITY_MODE_FORCE_HIDE
		)

		tiles.material = black
		copy = tiles

	else:
		# Mantém a hierarquia sem copiar física ou lógica.
		copy = Node2D.new()

	copy.name = source.name

	pairs.append({
		"source": source,
		"copy": copy
	})

	for child in source.get_children():
		if child is Node2D:
			var child_copy := _copy_branch(
				child,
				with_occluders
			)

			copy.add_child(child_copy)

	return copy


func _sync() -> void:
	var main_view := get_viewport()

	if not is_instance_valid(main_view):
		return

	var raster_rect: Rect2 = (
		main_view.get_stretch_transform()
		* main_view.get_visible_rect()
	)

	var size := Vector2i(raster_rect.size.round())
	size = size.max(Vector2i(2, 2))

	for view in [full_view, visible_view]:
		if not is_instance_valid(view):
			continue

		if view.size != size:
			view.size = size

		view.canvas_transform = (
			main_view.get_stretch_transform()
			* main_view.global_canvas_transform
			* main_view.canvas_transform
		)

		view.global_canvas_transform = Transform2D.IDENTITY

		view.canvas_item_default_texture_filter = (
			main_view.canvas_item_default_texture_filter
		)

		view.canvas_item_default_texture_repeat = (
			main_view.canvas_item_default_texture_repeat
		)

		view.snap_2d_transforms_to_pixel = (
			main_view.snap_2d_transforms_to_pixel
		)

		view.snap_2d_vertices_to_pixel = (
			main_view.snap_2d_vertices_to_pixel
		)

		view.render_target_update_mode = (
			SubViewport.UPDATE_ALWAYS
			if enabled
			else SubViewport.UPDATE_DISABLED
		)

		view.canvas_cull_mask = main_view.canvas_cull_mask

	for background in backgrounds:
		if is_instance_valid(background):
			background.size = Vector2(size)

	if is_instance_valid(overlay):
		overlay.position = main_view.get_visible_rect().position
		overlay.size = main_view.get_visible_rect().size
		overlay.visible = enabled

	if is_instance_valid(composite):
		composite.set_shader_parameter(
			"outline_color",
			outline_color
		)

		composite.set_shader_parameter(
			"width_px",
			width_px
		)

		composite.set_shader_parameter(
			"debug_view",
			debug_view
		)

	# Percorre de trás para frente para poder remover pares inválidos.
	for i in range(pairs.size() - 1, -1, -1):
		var pair: Dictionary = pairs[i]

		# Obtém as referências sem fazer cast ainda.
		var source_object = pair.get("source")
		var copy_object = pair.get("copy")

		# Ignora objetos originais removidos com queue_free().
		if not is_instance_valid(source_object):
			if is_instance_valid(copy_object):
				copy_object.hide()

			pairs.remove_at(i)
			continue

		# Ignora cópias que tenham sido removidas.
		if not is_instance_valid(copy_object):
			pairs.remove_at(i)
			continue

		# O cast só acontece depois da validação.
		var source := source_object as Node2D
		var copy := copy_object as Node2D

		if source == null or copy == null:
			if is_instance_valid(copy):
				copy.hide()

			pairs.remove_at(i)
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

		copy.modulate = Color(
			1.0,
			1.0,
			1.0,
			source.modulate.a
		)

		copy.self_modulate = Color(
			1.0,
			1.0,
			1.0,
			source.self_modulate.a
		)

		if copy is Sprite2D and source is Sprite2D:
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
			mirror.region_filter_clip_enabled = (
				sprite.region_filter_clip_enabled
			)

		elif copy is TileMapLayer and source is TileMapLayer:
			var tiles := source as TileMapLayer
			var mirror := copy as TileMapLayer

			mirror.enabled = tiles.enabled
			mirror.y_sort_origin = tiles.y_sort_origin
			mirror.x_draw_order_reversed = (
				tiles.x_draw_order_reversed
			)
