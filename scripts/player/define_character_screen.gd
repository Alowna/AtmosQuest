extends Control

@onready var OkGoButton = $OkGoButton
var target_scene = "res://scenes/game.tscn"
# Called when the node enters the scene tree for the first time.

@onready var Username: LineEdit = $UsernameEditField/LineEdit



func _ready() -> void:
	OkGoButton.pressed.connect(_on_player_ready)
	visible = false
	
	_update_username()
	_random_placeholder()
	


func _process(delta: float) -> void:
	_update_username()
	

func _on_player_ready():
	visible = false
	get_tree().change_scene_to_file(target_scene)
	
func _update_username() -> void:
	if Username.text == "":
		PlayerConfig.username = Username.placeholder_text
	else:
		PlayerConfig.username = Username.text
		


func _random_placeholder():
	var random_name = names.pick_random()	
	Username.placeholder_text = random_name
	
var names: Array[String] = [
	"Sapo",
	"Ave",
	"Fogo",
	"Vapo",
	"Simus",
	"Lumi",
	"Nino",
	"Kiko",
	"Lulu",
	"Mimi",
	"Pipo",
	"Tico",
	"Tutu",
	"Bibi",
	"Zuzu",
	"Fifi",
	"Juju",
	"Yumi",
	"Kuma",
	"Neko",
	"Momo",
	"Puki",
	"Yuki",
	"Ruru",
	"Lilo",
	"Tobi",
	"Zico",
	"Balu",
	"Fofa",
	"Amora",
	"Mel",
	"Lua",
	"Sol",
	"Neo",
	"Zeno",
	"Filo",
	"Fuzu",
	"Pika",
	"Riko",
	"Miko",
	"Kiki",
	"Zaza",
	"Coco",
	"Nana",
	"Vivi",
	"Lupi",
	"Foxy",
	"Chibi",
	"Mini",
	"Pixel"
]
	
