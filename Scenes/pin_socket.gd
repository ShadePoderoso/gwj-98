class_name PinSocket
extends Control

@export var socket_id: String = "" # e.g. "PIN_1", "PWR_5V", "GND", "SPK_IN"
var connected_wire = null

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Find the root controller with on_socket_clicked
		var target = owner
		if target == null or not target.has_method("on_socket_clicked"):
			target = get_tree().current_scene

		if target != null and target.has_method("on_socket_clicked"):
			target.on_socket_clicked(self)
