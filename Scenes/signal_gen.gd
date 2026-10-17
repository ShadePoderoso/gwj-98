extends Control

enum Waveform { SINE, SQUARE, TRIANGLE }
var current_waveform: Waveform = Waveform.SINE

@onready var line_2d: Line2D = $VBoxContainer/PanelContainer/Line2D
@onready var control = $"."
@onready var sine_button: Button = $VBoxContainer/HBoxContainer/SineButton
@onready var square_button: Button = $VBoxContainer/HBoxContainer/SquareButton
@onready var triangle_button: Button = $VBoxContainer/HBoxContainer/TriangleButton
@onready var audio_player: AudioStreamPlayer = $AudioPlayer

var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100.0
var audio_time: float = 0.0 # Dedicated time counter for audio samples
# Signal generator parameters
var frequency: float = 2.0    # 2 Hz (2 cycles per second)
var amplitude: float = 1.0    # 1.0 Volt peak
var offset: float = 0.0       # DC offset

# Oscilloscope screen settings
var num_points: int = 300     # Number of segments across screen
var time_window: float = 1.0  # Seconds of time visible on screen (horizontal zoom)
var volts_scale: float = 50.0 # Pixels per Volt (vertical zoom)

var current_time: float = 0.0 # Tracks time for animation

func _ready() -> void:
	sine_button.pressed.connect(func(): current_waveform = Waveform.SINE)
	square_button.pressed.connect(func(): current_waveform = Waveform.SQUARE)
	triangle_button.pressed.connect(func(): current_waveform = Waveform.TRIANGLE)
	# Start audio playback and grab the playback buffer handle
	audio_player.play()
	playback = audio_player.get_stream_playback()

	# Let's start with an audible frequency (e.g. 440 Hz) and zoomed-in scope!
	frequency = 440.0
	time_window = 0.005 # 5 milliseconds shows ~2.2 wave cycles clearly
	
	
func _process(delta: float) -> void:
	current_time += delta
	update_signal_line()

	# Fill available audio buffer space
	fill_audio_buffer()

func fill_audio_buffer() -> void:
	if playback == null:
		return

	# How many frames does the audio card need to stay full?
	var frames_available: int = playback.get_frames_available()

	for i in range(frames_available):
		# Sample our signal at audio_time
		var sample: float = calculate_voltage(audio_time)

		# Volume control: scale down so it doesn't blow out your ears/speakers!
		sample *= 0.2

		# Clamp to valid audio limits (-1.0 to 1.0)
		sample = clampf(sample, -1.0, 1.0)

		# AudioStreamGenerator expects stereo Vector2(left_channel, right_channel)
		playback.push_frame(Vector2(sample, sample))

		# Advance audio time by one single audio sample duration
		audio_time += 1.0 / sample_rate

func update_signal_line() -> void:
	var points: PackedVector2Array = []
	var center_y: float = control.size.y / 2.0

	for i in range(num_points):
		# 1. Normalized progress across screen (0.0 at left, 1.0 at right)
		var t_norm: float = float(i) / float(num_points - 1)

		# 2. Pixel X coordinate
		var px: float = t_norm * control.size.x

		# 3. Real simulated time (t) for this sample
		var t: float = current_time + (t_norm * time_window)

		# 4. Calculate signal voltage at time t
		var voltage: float = calculate_voltage(t)

		# 5. Pixel Y coordinate
		# Note the minus sign: in Godot, Y=0 is TOP, so positive voltage goes UP
		var py: float = center_y - (voltage * volts_scale)

		points.append(Vector2(px, py))

	# 6. Push all points to the Line2D in one go
	line_2d.points = points
	
func calculate_voltage(t: float) -> float:
	var base_wave: float = 0.0

	match current_waveform:
		Waveform.SINE:
			base_wave = sin(TAU * frequency * t)

		Waveform.SQUARE:
			var cycle: float = fposmod(t * frequency, 1.0)
			base_wave = 1.0 if cycle < 0.5 else -1.0

		Waveform.TRIANGLE:
			var cycle: float = fposmod(t * frequency, 1.0)
			base_wave = 4.0 * abs(cycle - 0.5) - 1.0

	# Noise tip: randf_range(-0.05, 0.05) centers noise around 0 without adding DC bias
	var noise: float = randf_range(-0.05, 0.05)

	return offset + (amplitude * base_wave) + noise
