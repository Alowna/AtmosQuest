extends Node

# Autoload.
# Handles music playback and UI sound effects.

@onready var music_player := AudioStreamPlayer.new()

# Stores all currently active game sound players.
var current_game_sounds: Array[AudioStreamPlayer] = []


# Background music library.
var music = {
	"menu": preload("res://assets/Sounds/music/MainMenuSong.ogg"),
	"gameSong": preload("res://assets/Sounds/music/gameSong.ogg"),
	"sadEnding": preload("res://assets/Sounds/music/sadEnding.ogg"),
	"happyEnding": preload("res://assets/Sounds/music/happyEnding.ogg"),
}


# UI sound effects library.
var UIsounds = {
	"button": preload("res://assets/Sounds/UI/ButtonPressed.ogg"),
	"UIClick1": preload("res://assets/Sounds/UI/UIClick1.ogg"),
	"UIClick2": preload("res://assets/Sounds/UI/UIClick2.ogg"),
	"UIClick3": preload("res://assets/Sounds/UI/UIClick3.ogg")
}

# Game sound library.
var gameSounds = {

	# General game sounds.

	"openMetal": {
		"stream": preload("res://assets/Sounds/gameSounds/OpenMetal.ogg"),
		"volume": -4.0,
		"pitch": 1.0,
		"loop": false
	},

	"closeMetal": {
		"stream": preload("res://assets/Sounds/gameSounds/CloseMetal.ogg"),
		"volume": -8.0,
		"pitch": 1.0,
		"loop": false
	},

	"crash": {
		"stream": preload("res://assets/Sounds/gameSounds/Crash.ogg"),
		"volume": 0.0,
		"pitch": 3.5,
		"loop": false
	},

	# Ship sounds.

	"explosion": {
		"stream": preload("res://assets/Sounds/gameSounds/shipSounds/explosion.ogg"),
		"volume": 10.5,
		"pitch": 1.0,
		"loop": false
	},

	"Warning": {
		"stream": preload("res://assets/Sounds/gameSounds/shipSounds/Warning.ogg"),
		"volume": 5.0,
		"pitch": 1.0,
		"loop": false
	},

	"rocketLaunch": {
		"stream": preload("res://assets/Sounds/gameSounds/shipSounds/RocketLaunch.ogg"),
		"volume": 0.0,
		"pitch": 1.0,
		"loop": false
	},

	"fuelBurning": {
		"stream": preload("res://assets/Sounds/gameSounds/shipSounds/FuelBurning.ogg"),
		"volume": -25.0,
		"pitch": 1.0,
		"loop": true
	},

	"swoosh": {
		"stream": preload("res://assets/Sounds/gameSounds/shipSounds/Swoosh.ogg"),
		"volume": 0,
		"pitch": 1.0,
		"loop": false
	},
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
		push_error("Music '%s' not found." % name)
		return

	music_player.stream = music[name]
	music_player.stream.loop = true
	music_player.play()


# ==================================================
# UI SOUNDS
# Plays a one-shot UI sound effect.
# ==================================================

func play_ui_sound(name: String):

	if !UIsounds.has(name):
		push_error("UI sound '%s' not found." % name)
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


# ==================================================
# GAME SOUNDS
# Plays a game sound and keeps track of active players.
# ==================================================

func play_game_sound(name: String):

	if !gameSounds.has(name):
		push_error("Game sound '%s' not found." % name)
		return

	var data = gameSounds[name]

	var player := AudioStreamPlayer.new()

	player.volume_db = data.volume
	player.pitch_scale = data.pitch
	player.stream = data.stream

	# Enable looping if required.
	if data.loop:
		if player.stream is AudioStreamOggVorbis:
			player.stream.loop = true
		elif player.stream is AudioStreamWAV:
			player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	add_child(player)

	# Register the player as active.
	current_game_sounds.append(player)

	player.play()

	# Remove one-shot sounds after playback.
	if not data.loop:
		player.finished.connect(func():
			current_game_sounds.erase(player)
			player.queue_free()
		)

	return player


# ==================================================
# GAME SOUNDS
# Stops all active game sounds immediately.
# ==================================================

func stop_all_game_sounds():

	# Stop and remove every active sound player.
	for player in current_game_sounds:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()

	# Clear the active player list.
	current_game_sounds.clear()


# ==================================================
# GAME SOUNDS
# Removes invalid references from the active sound list.
# Useful if players are removed elsewhere.
# ==================================================

func cleanup_game_sounds():

	current_game_sounds = current_game_sounds.filter(func(player):
		return is_instance_valid(player)
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
