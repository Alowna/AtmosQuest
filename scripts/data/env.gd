extends Node

# Stores the API base URL loaded from the config file
var api_base_url: String = ""

func _ready():
	var config = ConfigFile.new()
	
	# Attempt to load the configuration file from the project root
	var err = config.load("res://env.cfg")
	
	# Check if the file loaded successfully
	if err != OK:
		push_error("Could not load env.cfg. Error code: " + str(err))
		return
	
	# Verify that the 'api' section exists before attempting to read values
	if config.has_section("api"):
		# Retrieve the base_url from the 'api' section
		# Defaults to an empty string if the key is missing
		api_base_url = config.get_value("api", "base_url", "")
	else:
		push_error("The [api] section was not found in env.cfg!")
