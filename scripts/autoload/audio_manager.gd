extends Node

# Autoload.
# Handles music playback and UI sound effects.

@onready var music_player := AudioStreamPlayer.new()


# Background music library.
var music = {
	"menu": preload("res://assets/HUD/MainMenu/Sounds/MainMenuSong.wav"),
	"gameSong": preload("res://assets/enviroment/sounds/gameSong.wav"),
}


# UI sound effects library.
var UIsounds = {
	"button": preload("res://assets/HUD/MainMenu/Sounds/ButtonPressed.wav")
}


func _ready() -> void:

	# Create the music player.
	add_child(music_player)

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

	player.stream = UIsounds[name]

	add_child(player)

	player.play()

	# Remove the temporary player after playback.
	player.finished.connect(func():
		player.queue_free()
	)


# ==================================================
# MUSIC TOGGLE
# Starts or stops the current music.
# ==================================================

func toggle_music():

	if music_player.playing:
		music_player.stop()
	else:
		music_player.play()
