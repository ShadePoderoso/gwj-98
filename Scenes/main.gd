extends Control

@onready var wires_layer: Control = $WiresLayer
@onready var speaker: LabSpeaker = $MainLayout/TopRack/Speaker

var active_source_socket: PinSocket = null
var preview_wire: Line2D = null

# List of permanent wires: [{ "from": "PWR_5V", "to": "PIN_1", "line": Line2D }, ...]
var connected_wires: Array = []

func _process(_delta: float) -> void:
	# If currently pulling a wire, stretch it to the mouse position
	if preview_wire != null and active_source_socket != null:
		preview_wire.set_point_position(1, get_global_mouse_position())

func on_socket_clicked(socket: PinSocket) -> void:
	# 1. Starting a new wire
	if active_source_socket == null:
		# If this socket already has a wire plugged in, unplug it!
		if socket.connected_wire != null:
			remove_wire_from_socket(socket)
			return

		active_source_socket = socket
		start_preview_wire(socket)

	# 2. Finishing the wire at another socket
	elif active_source_socket != socket:
		create_permanent_wire(active_source_socket, socket)
		cancel_preview_wire()
		evaluate_circuit()

	# 3. Clicked the same socket -> cancel
	else:
		cancel_preview_wire()

func _unhandled_input(event: InputEvent) -> void:
	# Right-click cancels stretching a wire
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		cancel_preview_wire()
		
func start_preview_wire(socket: PinSocket) -> void:
	preview_wire = Line2D.new()
	preview_wire.width = 4.0
	preview_wire.default_color = get_wire_color(socket.socket_id)
	preview_wire.add_point(socket.global_position + socket.size / 2.0)
	preview_wire.add_point(get_global_mouse_position())
	wires_layer.add_child(preview_wire)

func create_permanent_wire(from_sock: PinSocket, to_sock: PinSocket) -> void:
	var wire_line = Line2D.new()
	wire_line.width = 4.0
	wire_line.default_color = get_wire_color(from_sock.socket_id)
	wire_line.joint_mode = Line2D.LINE_JOINT_ROUND
	wire_line.antialiased = true

	var pos_a = from_sock.global_position + from_sock.size / 2.0
	var pos_b = to_sock.global_position + to_sock.size / 2.0

	# Optional: 3 points with a slight sag for a drooping cable
	var mid_point = (pos_a + pos_b) / 2.0 + Vector2(0, 25.0)
	wire_line.points = PackedVector2Array([pos_a, mid_point, pos_b])

	wires_layer.add_child(wire_line)

	# Store connection
	var connection = { "from": from_sock, "to": to_sock, "line": wire_line }
	connected_wires.append(connection)
	from_sock.connected_wire = connection
	to_sock.connected_wire = connection

func cancel_preview_wire() -> void:
	if preview_wire != null:
		preview_wire.queue_free()
		preview_wire = null
	active_source_socket = null

func get_wire_color(id: String) -> Color:
	if "PWR" in id or "VCC" in id:
		return Color(0.9, 0.2, 0.2) # Red for power
	elif "GND" in id:
		return Color(0.15, 0.15, 0.15) # Black for ground
	else:
		return Color(0.9, 0.8, 0.1) # Yellow for signals

func are_pins_connected(id_a: String, id_b: String) -> bool:
	for wire in connected_wires:
		var a = wire["from"].socket_id
		var b = wire["to"].socket_id
		if (a == id_a and b == id_b) or (a == id_b and b == id_a):
			return true
	return false

func evaluate_circuit() -> void:
	# Phase 1: Pin 1 = VCC, Pin 8 = GND, Pin 3 = Audio Output
	var has_power = are_pins_connected("PWR_5V", "PIN_1")
	var has_ground = are_pins_connected("GND", "PIN_8")
	var has_audio = are_pins_connected("SPK_IN", "PIN_3")

	if has_power and has_ground and has_audio:
		print("CIRCUIT COMPLETE -> SPEAKER ON")
		speaker.start_audio(587.33) # 587.33 Hz is note D5!
	else:
		speaker.stop_audio()
		
func remove_wire_from_socket(socket: PinSocket) -> void:
	var wire = socket.connected_wire
	if wire == null:
		return

	# 1. Disconnect both endpoints
	wire["from"].connected_wire = null
	wire["to"].connected_wire = null

	# 2. Delete the visual Line2D cable
	if is_instance_valid(wire["line"]):
		wire["line"].queue_free()

	# 3. Remove from our list of connections
	connected_wires.erase(wire)

	# 4. Re-evaluate circuit (cutting power/audio if disconnected)
	evaluate_circuit()
