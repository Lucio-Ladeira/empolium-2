extends Control

const HOME_PATH := "/home/empolium"
# shortcut: sample entries are read-only; add persistent storage when players can manage save files.
const ENTRIES := {
	"/home/empolium": [
		{"name": "Área de trabalho", "kind": "Pasta", "path": "/home/empolium/Área de trabalho", "size": "—"},
		{"name": "Documentos", "kind": "Pasta", "path": "/home/empolium/Documentos", "size": "—"},
		{"name": "Imagens", "kind": "Pasta", "path": "/home/empolium/Imagens", "size": "—"},
		{"name": "Jogos", "kind": "Pasta", "path": "/home/empolium/Jogos", "size": "—"},
		{"name": "Música", "kind": "Pasta", "path": "/home/empolium/Música", "size": "—"},
		{"name": "Sistema", "kind": "Pasta", "path": "/home/empolium/Sistema", "size": "—"},
		{"name": "Vídeos", "kind": "Pasta", "path": "/home/empolium/Vídeos", "size": "—"},
	],
	"/home/empolium/Área de trabalho": [
		{"name": "Atalhos", "kind": "Pasta", "path": "/home/empolium/Área de trabalho/Atalhos", "size": "—"},
		{"name": "Leia-me.txt", "kind": "Texto simples", "size": "2 KB"},
	],
	"/home/empolium/Área de trabalho/Atalhos": [
		{"name": "Empolium 2", "kind": "Aplicativo", "size": "—"},
		{"name": "Configurações", "kind": "Atalho", "size": "—"},
	],
	"/home/empolium/Documentos": [
		{"name": "Diário de missão.txt", "kind": "Texto simples", "size": "14 KB"},
		{"name": "Mapa de Neo-Empolium.pdf", "kind": "Documento PDF", "size": "3,2 MB"},
		{"name": "Lista de missões.csv", "kind": "Planilha CSV", "size": "8 KB"},
	],
	"/home/empolium/Imagens": [
		{"name": "Emblema de Empolium.png", "kind": "Imagem PNG", "size": "640 KB"},
		{"name": "Mapa setorial.png", "kind": "Imagem PNG", "size": "2,1 MB"},
	],
	"/home/empolium/Jogos": [
		{"name": "Empolium 2", "kind": "Pasta", "path": "/home/empolium/Jogos/Empolium 2", "size": "—"},
		{"name": "Pacotes instalados", "kind": "Pasta", "path": "/home/empolium/Jogos/Pacotes instalados", "size": "—"},
	],
	"/home/empolium/Jogos/Empolium 2": [
		{"name": "Capturas", "kind": "Pasta", "path": "/home/empolium/Jogos/Empolium 2/Capturas", "size": "—"},
		{"name": "Partidas", "kind": "Pasta", "path": "/home/empolium/Jogos/Empolium 2/Partidas", "size": "—"},
		{"name": "preferências.cfg", "kind": "Configuração", "size": "1 KB"},
		{"name": "Sobre o jogo.txt", "kind": "Texto simples", "size": "3 KB"},
	],
	"/home/empolium/Jogos/Empolium 2/Capturas": [],
	"/home/empolium/Jogos/Empolium 2/Partidas": [
		{"name": "slot-01.sav", "kind": "Partida salva", "size": "128 KB"},
	],
	"/home/empolium/Jogos/Pacotes instalados": [],
	"/home/empolium/Música": [],
	"/home/empolium/Sistema": [
		{"name": "Configurações", "kind": "Aplicativo", "size": "—"},
		{"name": "Informações do sistema", "kind": "Atalho", "size": "—"},
		{"name": "Registros", "kind": "Pasta", "path": "/home/empolium/Sistema/Registros", "size": "—"},
	],
	"/home/empolium/Sistema/Registros": [
		{"name": "sessão-atual.log", "kind": "Registro", "size": "6 KB"},
	],
	"/home/empolium/Vídeos": [],
}

@onready var back_button: Button = $Margin/Content/Toolbar/Back
@onready var up_button: Button = $Margin/Content/Toolbar/Up
@onready var address: LineEdit = $Margin/Content/Toolbar/Address
@onready var search: LineEdit = $Margin/Content/Toolbar/Search
@onready var tree: Tree = $Margin/Content/Body/Listing/Tree
@onready var status: Label = $Margin/Content/Status
@onready var context_menu: PopupMenu = $ContextMenu

var current_path := HOME_PATH
var history: Array[String] = []
var sort_column := 0
var sort_ascending := true
var context_entry: Dictionary = {}

func _ready() -> void:
	tree.set_column_title(0, "Nome")
	tree.set_column_title(1, "Tipo")
	tree.set_column_title(2, "Tamanho")
	tree.set_column_title(3, "Localização")
	tree.set_column_expand(0, true)
	tree.set_column_expand(1, false)
	tree.set_column_expand(2, false)
	tree.set_column_expand(3, false)
	tree.set_column_custom_minimum_width(1, 86)
	tree.set_column_custom_minimum_width(2, 104)
	tree.set_column_custom_minimum_width(3, 170)
	$Margin/Content/Toolbar/Back.pressed.connect(_go_back)
	$Margin/Content/Toolbar/Up.pressed.connect(_go_up)
	address.text_submitted.connect(_navigate)
	search.text_changed.connect(_render_location)
	tree.column_title_clicked.connect(_on_column_title_clicked)
	tree.item_activated.connect(_open_selected)
	tree.cell_selected.connect(_update_selected_status)
	tree.gui_input.connect(_on_tree_gui_input)
	context_menu.id_pressed.connect(_on_context_menu_action)
	$Margin/Content/Body/Sidebar/Home.pressed.connect(_navigate.bind(HOME_PATH))
	$Margin/Content/Body/Sidebar/Documents.pressed.connect(_navigate.bind("/home/empolium/Documentos"))
	$Margin/Content/Body/Sidebar/Pictures.pressed.connect(_navigate.bind("/home/empolium/Imagens"))
	$Margin/Content/Body/Sidebar/Games.pressed.connect(_navigate.bind("/home/empolium/Jogos"))
	$Margin/Content/Body/Sidebar/System.pressed.connect(_navigate.bind("/home/empolium/Sistema"))
	_update_sort_titles()
	_render_location()

func _navigate(path: String) -> void:
	var destination := path.strip_edges().trim_suffix("/")
	if destination.is_empty():
		destination = "/"
	if not ENTRIES.has(destination):
		status.text = "Essa pasta não existe."
		address.text = current_path
		return
	if destination != current_path:
		history.append(current_path)
		current_path = destination
	if not search.text.is_empty():
		search.clear()
	_render_location()

func _go_back() -> void:
	if history.is_empty():
		return
	current_path = history.pop_back()
	search.clear()
	_render_location()

func _go_up() -> void:
	if current_path == HOME_PATH:
		return
	var parent := current_path.get_base_dir()
	_navigate(parent if ENTRIES.has(parent) else HOME_PATH)

func _render_location(_query: String = "") -> void:
	address.text = current_path
	back_button.disabled = history.is_empty()
	up_button.disabled = current_path == HOME_PATH
	tree.clear()
	var root := tree.create_item()
	var needle := search.text.strip_edges().to_lower()
	var visible_entries: Array[Dictionary] = []
	var folder_count := 0
	var file_count := 0
	if needle.is_empty():
		for entry: Dictionary in ENTRIES.get(current_path, []):
			var visible_entry: Dictionary = entry.duplicate()
			visible_entry["_parent_path"] = current_path
			visible_entries.append(visible_entry)
	else:
		for parent_variant in ENTRIES:
			var parent_path := str(parent_variant)
			for entry: Dictionary in ENTRIES[parent_path]:
				var searchable := "%s %s %s %s" % [entry.name, entry.kind, entry.get("size", ""), parent_path]
				if needle not in searchable.to_lower():
					continue
				var visible_entry: Dictionary = entry.duplicate()
				visible_entry["_parent_path"] = parent_path
				visible_entries.append(visible_entry)
	visible_entries.sort_custom(_entry_before)
	for entry: Dictionary in visible_entries:
		var item := tree.create_item(root)
		var is_folder: bool = entry.kind == "Pasta"
		item.set_text(0, ("▣  " if is_folder else "▤  ") + str(entry.name))
		item.set_text(1, str(entry.kind))
		item.set_text(2, str(entry.size))
		item.set_text(3, _location_label(str(entry._parent_path)))
		item.set_metadata(0, entry)
		item.set_tooltip_text(0, str(entry._parent_path))
		if is_folder:
			folder_count += 1
		else:
			file_count += 1
	if not needle.is_empty():
		status.text = "Nenhum resultado em %s." % HOME_PATH if visible_entries.is_empty() else "%d resultados em %s" % [visible_entries.size(), HOME_PATH]
	elif visible_entries.is_empty():
		status.text = "Esta pasta está vazia."
	else:
		status.text = "%d itens  ·  %d pastas  ·  %d arquivos" % [folder_count + file_count, folder_count, file_count]

func _on_column_title_clicked(column: int, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	if sort_column == column:
		sort_ascending = not sort_ascending
	else:
		sort_column = column
		sort_ascending = true
	_update_sort_titles()
	_sort_existing_rows()

func _update_sort_titles() -> void:
	var titles := ["Nome", "Tipo", "Tamanho", "Localização"]
	for column in range(titles.size()):
		var arrow := " ↑" if sort_ascending else " ↓"
		tree.set_column_title(column, str(titles[column]) + (arrow if column == sort_column else ""))

func _entry_before(a: Dictionary, b: Dictionary) -> bool:
	if sort_column == 2:
		var size_a := _size_in_kilobytes(str(a.get("size", "—")))
		var size_b := _size_in_kilobytes(str(b.get("size", "—")))
		if size_a < 0.0 or size_b < 0.0:
			if size_a < 0.0 and size_b >= 0.0:
				return false
			if size_b < 0.0 and size_a >= 0.0:
				return true
			var folder_order := str(a.name).naturalnocasecmp_to(str(b.name))
			return folder_order < 0 if sort_ascending else folder_order > 0
		if not is_equal_approx(size_a, size_b):
			return size_a < size_b if sort_ascending else size_a > size_b
		var size_tie_order := str(a.name).naturalnocasecmp_to(str(b.name))
		return size_tie_order < 0 if sort_ascending else size_tie_order > 0
	var key_a := str(a.name)
	var key_b := str(b.name)
	match sort_column:
		1:
			key_a = str(a.kind)
			key_b = str(b.kind)
		3:
			key_a = str(a._parent_path)
			key_b = str(b._parent_path)
	var order := key_a.naturalnocasecmp_to(key_b)
	if order == 0:
		order = str(a.name).naturalnocasecmp_to(str(b.name))
	return order < 0 if sort_ascending else order > 0

func _size_in_kilobytes(label: String) -> float:
	var parts := label.strip_edges().split(" ", false, 1)
	if parts.is_empty() or parts[0] == "—":
		return -1.0
	var amount := parts[0].replace(",", ".").to_float()
	if parts.size() < 2:
		return amount
	match parts[1].to_upper():
		"MB": return amount * 1024.0
		"GB": return amount * 1048576.0
		_: return amount

func _sort_existing_rows() -> void:
	var root := tree.get_root()
	if root == null:
		return
	var rows: Array[TreeItem] = []
	var row := root.get_first_child()
	while row != null:
		rows.append(row)
		row = row.get_next()
	rows.sort_custom(_tree_item_before)
	for index in range(rows.size()):
		var current := root.get_child(index)
		if current != rows[index]:
			rows[index].move_before(current)

func _tree_item_before(a: TreeItem, b: TreeItem) -> bool:
	return _entry_before(a.get_metadata(0), b.get_metadata(0))

func _location_label(path: String) -> String:
	return "Pasta pessoal" if path == HOME_PATH else path.trim_prefix(HOME_PATH + "/")

func _open_selected() -> void:
	var selected := tree.get_selected()
	if selected == null:
		return
	_open_entry(selected.get_metadata(0))

func _update_selected_status() -> void:
	var selected := tree.get_selected()
	if selected == null:
		return
	var entry: Dictionary = selected.get_metadata(0)
	status.text = "%s  ·  %s  ·  %s  ·  %s" % [entry.name, entry.kind, entry.size, entry._parent_path]

func _on_tree_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_RIGHT:
		return
	var item: TreeItem = tree.get_item_at_position(event.position)
	if item == null:
		context_entry = {}
		context_menu.clear()
		context_menu.add_item("Atualizar", 3)
		context_menu.add_separator()
		context_menu.add_item("Propriedades da pasta", 2)
	else:
		item.select(0)
		context_entry = item.get_metadata(0)
		context_menu.clear()
		context_menu.add_item("Abrir", 0)
		context_menu.add_separator()
		context_menu.add_item("Copiar caminho", 1)
		context_menu.add_item("Propriedades", 2)
	context_menu.popup(Rect2(event.global_position, Vector2.ZERO))
	get_viewport().set_input_as_handled()

func _on_context_menu_action(id: int) -> void:
	match id:
		0:
			_open_entry(context_entry)
		1:
			var path := _entry_full_path(context_entry)
			DisplayServer.clipboard_set(path)
			status.text = "Caminho copiado: %s" % path
		2:
			if context_entry.is_empty():
				status.text = "%s  ·  Pasta  ·  %s" % ["Pessoal" if current_path == HOME_PATH else current_path.get_file(), current_path]
			else:
				var path := _entry_full_path(context_entry)
				status.text = "%s  ·  %s  ·  %s  ·  %s" % [context_entry.name, context_entry.kind, context_entry.size, path]
		3:
			_render_location()

func _entry_full_path(entry: Dictionary) -> String:
	return str(entry.get("path", "%s/%s" % [entry.get("_parent_path", current_path), entry.get("name", "")]))

func _open_entry(entry: Dictionary) -> void:
	if entry.is_empty():
		return
	if entry.get("kind") == "Pasta":
		_navigate(str(entry.get("path", "")))
	else:
		status.text = "%s  ·  %s  ·  %s  ·  %s" % [entry.name, entry.kind, entry.size, _entry_full_path(entry)]
