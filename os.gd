extends Control

const BOOT_SCENE := preload("res://os/boot/boot.tscn")
const LOGIN_SCENE := preload("res://os/login/login.tscn")
const DESKTOP_SCENE := preload("res://os/desktop/desktop.tscn")

var current_screen: Control


func _ready() -> void:
    theme = _create_theme()
    show_boot()


func _create_theme() -> Theme:
    var ui := Theme.new()
    var pixel_font := SystemFont.new()
    pixel_font.font_names = PackedStringArray(["monospace"])
    pixel_font.allow_system_fallback = true
    pixel_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
    ui.default_font = pixel_font
    ui.default_font_size = 16
    ui.set_color("font_color", "Label", Color("#eaf3ff"))
    ui.set_color("font_color", "Button", Color("#eaf3ff"))
    ui.set_color("font_hover_color", "Button", Color("#ffffff"))
    ui.set_color("font_pressed_color", "Button", Color("#ffffff"))
    ui.set_color("font_color", "LineEdit", Color("#eaf3ff"))
    ui.set_color("font_placeholder_color", "LineEdit", Color("#90a8c4"))
    ui.set_color("font_color", "Tree", Color("#eaf3ff"))
    ui.set_color("font_selected_color", "Tree", Color("#ffffff"))
    ui.set_color("font_hovered_color", "Tree", Color("#ffffff"))
    ui.set_color("guide_color", "Tree", Color("#293650"))

    var normal := _button_style(Color("#151d30"), Color("#293650"))
    var hover := _button_style(Color("#1d2a40"), Color("#3edcf3"))
    var pressed := _button_style(Color("#25243d"), Color("#c45adf"))
    for type in ["Button", "OptionButton"]:
        ui.set_stylebox("normal", type, normal)
        ui.set_stylebox("hover", type, hover)
        ui.set_stylebox("pressed", type, pressed)
        ui.set_stylebox("focus", type, hover)
        ui.set_stylebox("disabled", type, normal)

    var field := _button_style(Color("#0d1425"), Color("#2d3a55"))
    var field_focus := _button_style(Color("#0d1425"), Color("#3edcf3"))
    ui.set_stylebox("normal", "LineEdit", field)
    ui.set_stylebox("focus", "LineEdit", field_focus)

    var tree_panel := _button_style(Color("#0d1425"), Color("#293650"))
    var tree_header := _button_style(Color("#151d30"), Color("#293650"))
    var tree_header_hover := _button_style(Color("#1d2a40"), Color("#3edcf3"))
    var tree_selected := _button_style(Color("#25243d"), Color("#c45adf"))
    var tree_hover := _button_style(Color("#1d2a40"), Color("#3edcf3"))
    for style in [tree_panel, tree_header, tree_header_hover, tree_selected, tree_hover]:
        style.content_margin_left = 5
        style.content_margin_right = 5
        style.content_margin_top = 2
        style.content_margin_bottom = 2
    ui.set_stylebox("panel", "Tree", tree_panel)
    ui.set_stylebox("title_button_normal", "Tree", tree_header)
    ui.set_stylebox("title_button_hover", "Tree", tree_header_hover)
    ui.set_stylebox("title_button_pressed", "Tree", tree_selected)
    ui.set_stylebox("selected", "Tree", tree_selected)
    ui.set_stylebox("selected_focus", "Tree", tree_selected)
    ui.set_stylebox("hovered", "Tree", tree_hover)
    ui.set_stylebox("cursor", "Tree", tree_hover)
    ui.set_stylebox("cursor_unfocused", "Tree", tree_hover)

    var scroll_track := _button_style(Color("#0b1120"), Color("#0b1120"))
    var scroll_grabber := _button_style(Color("#29415e"), Color("#3edcf3"))
    for style in [scroll_track, scroll_grabber]:
        style.content_margin_left = 8
        style.content_margin_right = 8
        style.content_margin_top = 8
        style.content_margin_bottom = 8
    ui.set_stylebox("scroll", "ScrollBar", scroll_track)
    ui.set_stylebox("scroll_focus", "ScrollBar", scroll_track)
    ui.set_stylebox("grabber", "ScrollBar", scroll_grabber)
    ui.set_stylebox("grabber_highlight", "ScrollBar", scroll_grabber)
    ui.set_stylebox("grabber_pressed", "ScrollBar", scroll_grabber)

    var slider_track := _button_style(Color("#24334e"), Color("#415a7b"))
    var slider_fill := _button_style(Color("#3edcf3"), Color("#3edcf3"))
    for style in [slider_track, slider_fill]:
        style.content_margin_left = 0
        style.content_margin_right = 0
        style.content_margin_top = 4
        style.content_margin_bottom = 4
    ui.set_stylebox("slider", "HSlider", slider_track)
    ui.set_stylebox("grabber_area", "HSlider", slider_fill)
    ui.set_stylebox("grabber_area_highlight", "HSlider", slider_fill)
    var slider_grabber: Texture2D = load("res://assets/pixel_grabber.svg")
    ui.set_icon("grabber", "HSlider", slider_grabber)
    ui.set_icon("grabber_highlight", "HSlider", slider_grabber)
    ui.set_icon("grabber_disabled", "HSlider", slider_grabber)

    var toggle_on: Texture2D = load("res://assets/toggle_on.svg")
    var toggle_off: Texture2D = load("res://assets/toggle_off.svg")
    for type in ["checked", "checked_disabled", "checked_mirrored", "checked_disabled_mirrored"]:
        ui.set_icon(type, "CheckButton", toggle_on)
    for type in ["unchecked", "unchecked_disabled", "unchecked_mirrored", "unchecked_disabled_mirrored"]:
        ui.set_icon(type, "CheckButton", toggle_off)
    return ui


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(2)
    style.set_corner_radius_all(0)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 4
    style.content_margin_bottom = 4
    return style


func clear_screen() -> void:
    if is_instance_valid(current_screen):
        current_screen.queue_free()
    current_screen = null


func show_boot() -> void:
    clear_screen()
    current_screen = BOOT_SCENE.instantiate()
    add_child(current_screen)
    current_screen.boot_finished.connect(show_login)


func show_login() -> void:
    clear_screen()
    current_screen = LOGIN_SCENE.instantiate()
    add_child(current_screen)
    current_screen.login_success.connect(show_desktop)


func show_desktop() -> void:
    clear_screen()
    current_screen = DESKTOP_SCENE.instantiate()
    add_child(current_screen)
