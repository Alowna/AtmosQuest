extends Node

# Stores the API base URL loaded from the config file
var api_base_url: String = ""

func _ready():
	var config = ConfigFile.new()
	
	# Attempt to load the configuration file
	# We use "res://env.cfg" to locate it in the project root
	var err = config.load("res://env.cfg")
	
	if err != OK:
		push_error("env.cfg file not found! Please copy env.example.cfg to env.cfg.")
		return
		
	# Read the base_url from the [api] section
	# If the key or section is missing, it defaults to an empty string
	api_base_url = config.get_value("api", "base_url", "")
