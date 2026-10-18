extends Control

@onready var fullscreen: CheckButton = $Margin/Content/Fullscreen
@onready var volume: HSlider = $Margin/Content/Volume
@onready var language: OptionButton = $Margin/Content/Language
@onready var language_note: Label = $Margin/Content/LanguageNote

func _ready() -> void:
    fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
    var bus: int = AudioServer.get_bus_index("Master")
    if bus >= 0:
        var db: float = AudioServer.get_bus_volume_db(bus)
        volume.value = clampf(db + 50.0, 0.0, 100.0)
    language.clear()
    language.add_item("Português (Brasil)")
    language.add_item("Idioma do sistema")
    language.select(0)
    language_note.text = "Idioma atual: Português (Brasil)"

func _on_fullscreen_toggled(toggled_on: bool) -> void:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_volume_value_changed(value: float) -> void:
    var bus: int = AudioServer.get_bus_index("Master")
    if bus >= 0:
        AudioServer.set_bus_volume_db(bus, value - 50.0)

func _on_language_item_selected(index: int) -> void:
    if index == 0:
        language_note.text = "Idioma atual: Português (Brasil)"
    else:
        var locale: String = TranslationServer.get_locale()
        language_note.text = "Idioma do sistema detectado: " + locale
