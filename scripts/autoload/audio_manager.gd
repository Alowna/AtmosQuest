extends Node

@onready var music_player := AudioStreamPlayer.new()

var music = {
	"menu": preload("res://assets/HUD/MainMenu/Sounds/MainMenuSong.wav"),
	"gameSong": preload("res://assets/enviroment/sounds/gameSong.wav"),
}

var UIsounds = {
	"button": preload("res://assets/HUD/MainMenu/Sounds/ButtonPressed.wav")
}


func _ready() -> void:
	add_child(music_player)
	AudioManager.play_music("menu")


func play_music(name: String):
	if !music.has(name):
		push_error("Música '%s' não encontrada." % name)
		return

	music_player.stream = music[name]
	music_player.play()


func play_ui_sound(name: String):
	if !UIsounds.has(name):
		push_error("Som de UI '%s' não encontrado." % name)
		return

	var player := AudioStreamPlayer.new()
	player.stream = UIsounds[name]

	add_child(player)
	player.play()

	player.finished.connect(func():
		player.queue_free()
	)

func toggle_music():
	if music_player.playing:
		music_player.stop()
	else:
		music_player.play()
