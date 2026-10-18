extends Control

const SETTINGS_APP := preload("res://os/apps/settings/settings.tscn")
const FILES_APP := preload("res://os/apps/files/files.tscn")
const ABOUT_APP := preload("res://os/apps/about/about.tscn")
const EXTRAS_APP := preload("res://os/apps/extras/extras.tscn")
const TASKBAR_HEIGHT: float = 52.0
const CUSTOM_ART_PATH := "res://assets/custom"
const APP_TITLE_BY_ID := {
    "game": "Empolium 2",
    "settings": "Configurações",
    "files": "Arquivos",
    "extras": "Extras",
    "about": "Sobre o sistema",
}
const APP_ID_BY_TITLE := {
    "Empolium 2": "game",
    "Configurações": "settings",
    "Arquivos": "files",
    "Extras": "extras",
    "Sobre": "about",
    "Sobre o sistema": "about",
}

@export_file("*.tscn") var game_scene_path := "res://scenes/mapas/mapa.tscn"

@onready var window_manager: OSWindowManager = $WindowManager
@onready var window_buttons: HBoxContainer = $Taskbar/WindowButtons
@onready var start_menu: Panel = $StartMenu
@onready var start_button: Button = $Taskbar/StartButton
@onready var system_tray: Label = $Taskbar/SystemTray
@onready var menu_search: LineEdit = $StartMenu/Menu/MainContent/Search
@onready var application_list: GridContainer = $StartMenu/Menu/MainContent/AppScroll/ApplicationGrid
@onready var sidebar_panel: PanelContainer = $StartMenu/Menu/SidebarPanel
@onready var sidebar: VBoxContainer = $StartMenu/Menu/SidebarPanel/Sidebar
@onready var power_button: Button = $StartMenu/Menu/SidebarPanel/Sidebar/Power
@onready var power_menu: PopupMenu = $PowerMenu
@onready var context_menu: PopupMenu = $ContextMenu
@onready var clock: Label = $Taskbar/Clock
@onready var desktop_status: Label = $DesktopStatus
@onready var selection_overlay: Control = $SelectionOverlay
@onready var icon_container: Control = $Icons
@onready var wallpaper: TextureRect = $Wallpaper

var selecting: bool = false
var context_target := ""
var context_app_id := ""
var context_app_title := ""

func _ready() -> void:
    start_menu.hide()
    _apply_custom_art()
    _configure_launcher_icons()
    power_menu.add_item("Reiniciar", 0)
    power_menu.add_item("Desligar", 1)
    power_menu.id_pressed.connect(_on_power_menu_action)
    power_button.pressed.connect(_show_power_menu)
    context_menu.id_pressed.connect(_on_context_menu_action)
    sidebar.get_node("Home").pressed.connect(_show_all_apps)
    sidebar.get_node("Files").pressed.connect(_open_files)
    sidebar.get_node("Settings").pressed.connect(_open_settings)
    sidebar.get_node("About").pressed.connect(_open_about)
    for icon in icon_container.get_children():
        if icon is DesktopIcon:
            icon.gui_input.connect(_on_desktop_icon_gui_input.bind(icon))
    for button in application_list.get_children():
        if button is Button:
            button.gui_input.connect(_on_launcher_gui_input.bind(button))
    resized.connect(_layout_start_menu)
    resized.connect(_layout_taskbar)
    _layout_start_menu()
    _layout_taskbar()
    window_manager.window_opened.connect(_on_window_opened)
    window_manager.window_closed.connect(_on_window_closed)
    window_manager.window_minimized.connect(_on_window_minimized)
    window_manager.window_focused.connect(_on_window_focused)
    _update_clock()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT] and start_menu.visible:
        var point: Vector2 = event.position
        if not start_menu.get_global_rect().has_point(point) and not start_button.get_global_rect().has_point(point):
            start_menu.hide()
    if not selecting:
        return
    if event is InputEventMouseMotion:
        var motion := make_input_local(event) as InputEventMouseMotion
        selection_overlay.update_point(motion.position)
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
        selecting = false
        var release := make_input_local(event) as InputEventMouseButton
        selection_overlay.update_point(release.position)
        _select_icons(selection_overlay.selection_rect())
        selection_overlay.finish()
        get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
    if get_viewport().gui_get_hovered_control() != self:
        return
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            _show_desktop_context(event.global_position)
            get_viewport().set_input_as_handled()
        elif event.button_index == MOUSE_BUTTON_LEFT:
            selecting = true
            selection_overlay.begin(event.position)
            _clear_icon_selection()
            get_viewport().set_input_as_handled()

func _update_clock() -> void:
    var now: Dictionary = Time.get_datetime_dict_from_system()
    var months := ["jan.", "fev.", "mar.", "abr.", "mai.", "jun.", "jul.", "ago.", "set.", "out.", "nov.", "dez."]
    clock.text = "%02d:%02d\n%d %s" % [now.hour, now.minute, now.day, months[now.month - 1]]

func _toggle_start_menu() -> void:
    start_menu.visible = not start_menu.visible
    if start_menu.visible:
        menu_search.clear()
        menu_search.grab_focus()
        _filter_start_menu("")

func _layout_start_menu() -> void:
    var available: Vector2 = size
    var menu_size := Vector2(minf(680.0, maxf(1.0, available.x - 24.0)), minf(560.0, maxf(1.0, available.y - TASKBAR_HEIGHT - 24.0)))
    start_menu.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    start_menu.size = menu_size
    start_menu.position = Vector2(12.0, maxf(12.0, available.y - TASKBAR_HEIGHT - menu_size.y - 12.0))
    sidebar_panel.custom_minimum_size.x = 180.0 if available.x >= 560.0 else 58.0
    sidebar.get_node("Profile/UserInfo").visible = available.x >= 560.0
    application_list.columns = 2 if available.x >= 500.0 else 1
    for node in sidebar.get_children():
        if node is Button:
            var button := node as Button
            var full_text := str(button.get_meta("full_text", button.text))
            button.set_meta("full_text", full_text)
            button.text = full_text if available.x >= 560.0 else full_text.get_slice("  ", 0)
            button.tooltip_text = full_text

func _layout_taskbar() -> void:
    var width: float = size.x
    var start_width: float = 158.0 if width >= 900.0 else (112.0 if width >= 560.0 else minf(64.0, maxf(24.0, width - 16.0)))
    start_button.custom_minimum_size.x = start_width
    start_button.size.x = start_width
    start_button.offset_right = 8.0 + start_width
    start_button.text = "◆  Iniciar" if width >= 560.0 else "◆"
    start_button.tooltip_text = "Menu iniciar"
    system_tray.visible = width >= 1000.0
    clock.visible = width >= 480.0
    var right_reserve: float = (176.0 if system_tray.visible else 0.0) + (94.0 if clock.visible else 0.0)
    window_buttons.offset_left = 16.0 + start_width
    window_buttons.offset_right = -right_reserve - 8.0
    _fit_taskbar_buttons()

func _fit_taskbar_buttons() -> void:
    var buttons: Array[Node] = window_buttons.get_children()
    if buttons.is_empty():
        return
    var lane_width: float = maxf(0.0, get_viewport_rect().size.x + window_buttons.offset_right - window_buttons.offset_left)
    var button_width: float = maxf(1.0, minf(220.0, (lane_width - 4.0 * (buttons.size() - 1)) / buttons.size()))
    for node in buttons:
        var button := node as Button
        if button == null:
            continue
        button.custom_minimum_size.x = button_width
        button.size_flags_horizontal = Control.SIZE_FILL
        button.clip_text = true
        var title := str(button.get_meta("full_title", button.text))
        var has_icon: bool = button.get_meta("has_custom_icon", false)
        if button_width < 72.0:
            button.text = "" if has_icon else _task_icon(title)
        else:
            button.text = title if button_width >= 112.0 else _short_task_title(title)

func _task_icon(title: String) -> String:
    match title:
        "Configurações": return "⚙"
        "Arquivos": return "▤"
        "Extras": return "✦"
        "Sobre": return "i"
        "Sobre o sistema": return "i"
        "Empolium 2": return "E"
        _: return title.left(1)

func _short_task_title(title: String) -> String:
    match title:
        "Configurações": return "Config."
        "Arquivos": return "Arq."
        "Extras": return "Extras"
        "Sobre o sistema": return "Sobre"
        "Empolium 2": return "Empolium"
        _: return title.left(8)

func _filter_start_menu(query: String) -> void:
    var needle := query.strip_edges().to_lower()
    for child in application_list.get_children():
        if child is Button:
            var title := str(child.get_meta("app_title", child.text))
            child.visible = needle.is_empty() or needle in title.to_lower()

func _launch_game() -> void:
    start_menu.hide()
    var scene_path := game_scene_path.strip_edges()
    if ResourceLoader.exists(scene_path):
        OSVisualFX.change_scene_with_transition(scene_path)
    else:
        desktop_status.text = "Ainda não encontrei o jogo nesta instalação."

func _open_settings() -> void:
    start_menu.hide()
    window_manager.open_app(SETTINGS_APP, "Configurações", Vector2(780.0, 600.0), _custom_app_icon("settings"))

func _open_files() -> void:
    start_menu.hide()
    window_manager.open_app(FILES_APP, "Arquivos", Vector2(1040.0, 680.0), _custom_app_icon("files"))

func _open_extras() -> void:
    start_menu.hide()
    window_manager.open_app(EXTRAS_APP, "Extras", Vector2.ZERO, _custom_app_icon("extras"))

func _open_about() -> void:
    start_menu.hide()
    window_manager.open_app(ABOUT_APP, "Sobre o sistema", Vector2.ZERO, _custom_app_icon("about"))

func _show_desktop_context(global_position: Vector2) -> void:
    context_target = "desktop"
    context_menu.clear()
    context_menu.add_item("Atualizar", 2)
    context_menu.add_separator()
    context_menu.add_item("Abrir menu Iniciar", 3)
    context_menu.add_item("Configurações", 4)
    context_menu.add_item("Sobre o sistema", 5)
    context_menu.popup(Rect2(global_position, Vector2.ZERO))

func _show_app_context(app_id: String, global_position: Vector2) -> void:
    context_target = "app"
    context_app_id = app_id
    context_app_title = str(APP_TITLE_BY_ID.get(app_id, app_id.capitalize()))
    context_menu.clear()
    context_menu.add_item("Abrir", 0)
    context_menu.add_separator()
    context_menu.add_item("Propriedades", 1)
    context_menu.popup(Rect2(global_position, Vector2.ZERO))

func _on_desktop_icon_gui_input(event: InputEvent, icon: DesktopIcon) -> void:
    if event is not InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_RIGHT:
        return
    if not icon.selected:
        _clear_icon_selection()
        icon.set_selected(true)
    _show_app_context(icon.icon_kind, event.global_position)
    get_viewport().set_input_as_handled()

func _on_launcher_gui_input(event: InputEvent, button: Button) -> void:
    if event is not InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_RIGHT:
        return
    _show_app_context(button.name.to_lower(), event.global_position)
    get_viewport().set_input_as_handled()

func _on_context_menu_action(id: int) -> void:
    if context_target == "app":
        if id == 0:
            _open_context_app(context_app_id)
        elif id == 1:
            desktop_status.text = "%s  ·  Atalho do Empolium OS" % context_app_title
        return
    match id:
        2:
            _clear_icon_selection()
            _apply_custom_art()
            _update_clock()
            desktop_status.text = "Área de trabalho atualizada."
        3:
            start_menu.show()
            menu_search.clear()
            _filter_start_menu("")
            menu_search.grab_focus()
        4:
            _open_settings()
        5:
            _open_about()

func _open_context_app(app_id: String) -> void:
    match app_id:
        "game": _launch_game()
        "settings": _open_settings()
        "files": _open_files()
        "extras": _open_extras()
        "about": _open_about()

func _clear_icon_selection() -> void:
    for child in icon_container.get_children():
        if child is DesktopIcon:
            var icon: DesktopIcon = child
            icon.set_selected(false)

func _select_icons(area: Rect2) -> void:
    for child in icon_container.get_children():
        if child is DesktopIcon:
            var icon: DesktopIcon = child
            var icon_rect: Rect2 = icon.get_global_rect()
            icon.set_selected(area.intersects(icon_rect))

func _on_window_opened(window: Control, title: String) -> void:
    var button: Button = Button.new()
    button.text = title
    button.icon = _custom_app_icon(str(APP_ID_BY_TITLE.get(title, "")))
    button.expand_icon = true
    button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.custom_minimum_size = Vector2(1, 34)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.clip_text = true
    button.toggle_mode = true
    button.button_pressed = true
    button.tooltip_text = "Restaurar " + title
    button.set_meta("full_title", title)
    button.set_meta("has_custom_icon", button.icon != null)
    button.pressed.connect(_toggle_taskbar_window.bind(window))
    window_buttons.add_child(button)
    window.set_meta("taskbar_button", button)
    button.set_meta("window", window)
    call_deferred("_layout_taskbar")

func _on_window_closed(window: Control, _title: String) -> void:
    var button: Variant = window.get_meta("taskbar_button", null)
    if is_instance_valid(button):
        button.queue_free()
        call_deferred("_layout_taskbar")

func _on_window_minimized(window: Control, _title: String) -> void:
    var button: Variant = window.get_meta("taskbar_button", null)
    if is_instance_valid(button):
        button.button_pressed = false

func _on_window_focused(window: Control) -> void:
    for button in window_buttons.get_children():
        var taskbar_window: Variant = button.get_meta("window", null)
        button.button_pressed = taskbar_window == window

func _toggle_taskbar_window(window: Control) -> void:
    var button: Variant = window.get_meta("taskbar_button", null)
    if window.visible and is_instance_valid(button) and not button.button_pressed:
        window_manager.minimize_window(window)
    else:
        window_manager.restore_window(window)

func _restart_system() -> void:
    get_tree().reload_current_scene()

func _shutdown_system() -> void:
    get_tree().quit()

func _apply_custom_art() -> void:
    var custom_wallpaper := _load_art_texture(CUSTOM_ART_PATH + "/wallpaper")
    if custom_wallpaper != null:
        wallpaper.texture = custom_wallpaper
    for child in icon_container.get_children():
        if child is DesktopIcon:
            var icon := child as DesktopIcon
            icon.set_custom_icon(_custom_app_icon(icon.icon_kind))

func _configure_launcher_icons() -> void:
    for child in application_list.get_children():
        if child is Button:
            var button := child as Button
            var app_id := button.name.to_lower()
            var title := str(APP_TITLE_BY_ID.get(app_id, button.text))
            var texture := _custom_app_icon(app_id)
            button.set_meta("app_title", title)
            button.icon = texture
            button.expand_icon = true
            button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
            button.tooltip_text = title
            button.text = title if texture != null else _task_icon(title) + "  " + title

func _custom_app_icon(app_id: String) -> Texture2D:
    var texture := _load_art_texture(CUSTOM_ART_PATH + "/icons/" + app_id)
    if texture == null:
        return null
    var original_size := texture.get_size()
    var scale := minf(1.0, 32.0 / maxf(original_size.x, original_size.y))
    if scale >= 1.0:
        return texture
    var image := texture.get_image()
    image.resize(maxi(1, roundi(original_size.x * scale)), maxi(1, roundi(original_size.y * scale)), Image.INTERPOLATE_NEAREST)
    return ImageTexture.create_from_image(image)

func _load_art_texture(path_without_extension: String) -> Texture2D:
    for extension: String in [".png", ".svg"]:
        var path: String = path_without_extension + extension
        if ResourceLoader.exists(path):
            return load(path) as Texture2D
    return null

func _show_all_apps() -> void:
    menu_search.clear()
    _filter_start_menu("")

func _show_power_menu() -> void:
    power_menu.popup(power_button.get_global_rect())

func _on_power_menu_action(id: int) -> void:
    start_menu.hide()
    if id == 0:
        _restart_system()
    else:
        _shutdown_system()
