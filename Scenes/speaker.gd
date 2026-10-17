class_name LabSpeaker
extends PanelContainer

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var socket: PinSocket = $VBoxContainer/PostContainer/AudioPost/PinSocket

const NOTE_C5 = 523.25
const NOTE_D5 = 587.33
const NOTE_E5 = 659.25
const NOTE_G5 = 783.99
const NOTE_A5 = 880.0
const NOTE_REST = 0.0 # Silence

# Simple retro melody (e.g. 8-bit arpeggio / tune)
var melody: Array = [
	{"freq": NOTE_C5, "duration": 0.2},
	{"freq": NOTE_E5, "duration": 0.2},
	{"freq": NOTE_G5, "duration": 0.2},
	{"freq": NOTE_A5, "duration": 0.4},
	{"freq": NOTE_REST, "duration": 0.1},
	{"freq": NOTE_G5, "duration": 0.2},
	{"freq": NOTE_E5, "duration": 0.2},
	{"freq": NOTE_C5, "duration": 0.4},
	{"freq": NOTE_REST, "duration": 0.2},
]

var melody_step: int = 0
var step_timer: float = 0.0

var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100.0
var audio_time: float = 0.0

var is_playing: bool = false
var tone_frequency: float = 440.0 # Standard A4 tone (or puzzle melody frequency)

func _ready() -> void:
	audio_player.play()
	playback = audio_player.get_stream_playback()

func _process(delta: float) -> void:
	# Advance through the melody if active
	if is_playing:
		step_timer += delta
		if step_timer >= melody[melody_step]["duration"]:
			step_timer = 0.0
			melody_step = (melody_step + 1) % melody.size()
			tone_frequency = melody[melody_step]["freq"]

	# Audio buffer feeding
	if playback == null:
		return

	var frames_available = playback.get_frames_available()
	for i in range(frames_available):
		var sample: float = 0.0

		# Only synthesize sound if playing and not on a rest note
		if is_playing and tone_frequency > 0.0:
			var cycle = fposmod(audio_time * tone_frequency, 1.0)
			# Square wave with 50% duty cycle
			sample = 0.15 if cycle < 0.5 else -0.15
			audio_time += 1.0 / sample_rate

		playback.push_frame(Vector2(sample, sample))

func start_audio(freq: float = 440.0) -> void:
	tone_frequency = freq
	is_playing = true

func stop_audio() -> void:
	is_playing = false
