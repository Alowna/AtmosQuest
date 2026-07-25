extends Node

# Autoload.
# Handles music playback and UI sound effects.

@onready var music_player := AudioStreamPlayer.new()


# Background music library.
var music = {
	"menu": preload("res://assets/Sounds/MainMenuSong.ogg"),
	"gameSong": preload("res://assets/Sounds/gameSong.ogg"),
}


# UI sound effects library.
var UIsounds = {
	"button": preload("res://assets/Sounds/ButtonPressed.ogg"),
	"UIClick1": preload("res://assets/Sounds/UIClick1.ogg"),
	"UIClick2": preload("res://assets/Sounds/UIClick2.ogg"),
	"UIClick3": preload("res://assets/Sounds/UIClick3.ogg")
}

var gameSounds = {
	"explosion": preload("res://assets/Sounds/explosion.ogg"),
	"openMetal": preload("res://assets/Sounds/OpenMetal.ogg"),
	"closeMetal": preload("res://assets/Sounds/CloseMetal.ogg"),
	"crash": preload("res://assets/Sounds/Crash.ogg")
}

var gameSoundVolumes = {
	"explosion": 10.5,
	"openMetal": -4.0,
	"closeMetal": -8.0
}

var gameSoundSpeeds = {
	"explosion": 1.0,
	"openMetal": 1,
	"closeMetal": 1,
	"crash": 3.5
}


func _ready() -> void:

	# Create the music player.
	add_child(music_player)
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	# Start the menu music.
	AudioManager.play_music("menu")


# ==================================================
# MUSIC
# Plays a background music track.
# ==================================================

func play_music(name: String):

	if !music.has(name):
		push_error("Música '%s' não encontrada." % name)
		return

	music_player.stream = music[name]
	music_player.play()


# ==================================================
# UI SOUNDS
# Plays a one-shot UI sound effect.
# ==================================================

func play_ui_sound(name: String):

	if !UIsounds.has(name):
		push_error("Som de UI '%s' não encontrado." % name)
		return

	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	player.stream = UIsounds[name]

	add_child(player)

	player.play()

	# Remove the temporary player after playback.
	player.finished.connect(func():
		player.queue_free()
	)

func play_game_sound(name: String):

	if !gameSounds.has(name):
		push_error("Som de game '%s' não encontrado." % name)
		return
	
	
	var player := AudioStreamPlayer.new()
	
	player.volume_db = gameSoundVolumes.get(name, 0.0)
	player.pitch_scale = gameSoundSpeeds.get(name, 1.0)
	
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	player.stream = gameSounds[name]

	add_child(player)

	player.play()

	# Remove the temporary player after playback.
	player.finished.connect(func():
		player.queue_free()
	)
	
	return player

# ==================================================
# MUSIC TOGGLE
# Starts or stops the current music.
# ==================================================

func toggle_music():

	if music_player.playing:
		music_player.stop()
	else:
		music_player.play()
