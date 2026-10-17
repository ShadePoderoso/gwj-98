extends TextureRect

@onready var breadboard: TextureRect = $"../BreadBoard"

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var is_plugged_in: bool = false

# How close (in pixels) the chip needs to be to snap to the breadboard center
var snap_distance_threshold: float = 80.0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drag()
		else:
			stop_drag()

func _input(event: InputEvent) -> void:
	# Safety check: if player releases mouse outside the chip boundary
	if event is InputEventMouseButton and not event.pressed and is_dragging:
		stop_drag()

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset

func start_drag() -> void:
	is_dragging = true
	is_plugged_in = false
	# Offset prevents the chip from jumping its top-left corner to the mouse
	drag_offset = global_position - get_global_mouse_position()
	# Bring chip visually in front of everything while carrying it
	z_index = 10

func stop_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false
	z_index = 0
	check_snap_to_breadboard()
	
func check_snap_to_breadboard() -> void:
	if breadboard == null:
		return

	# Calculate center point of the breadboard
	var breadboard_center: Vector2 = breadboard.global_position + (breadboard.size / 2.0)

	# Calculate center point of our chip
	var chip_center: Vector2 = global_position + (size / 2.0)

	# Are we close enough to the breadboard center?
	if chip_center.distance_to(breadboard_center) < snap_distance_threshold:
		# Snap the chip so its center matches the breadboard center!
		global_position = breadboard_center - (size / 2.0)
		is_plugged_in = true
		print("Chip plugged into breadboard!")
	else:
		is_plugged_in = false
		print("Chip placed on desk.")
