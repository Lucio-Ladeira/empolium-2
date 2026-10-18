extends Node
# Entry point. The OS controller owns the complete boot/login/desktop flow.
func _ready() -> void:
    $OS.show_boot()
