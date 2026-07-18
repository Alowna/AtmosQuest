extends Node

# Autoload: Env.
# Loads and stores environment configuration values.


# Base URL used for API requests.
var api_base_url: String = ""


func _ready():

	var config = ConfigFile.new()

	# Load the configuration file.
	var err = config.load("res://env.cfg")

	# Stop if the configuration file could not be loaded.
	if err != OK:

		push_error(
			"Could not load env.cfg. Error code: "
			+ str(err)
		)

		return


	# Check if the API configuration exists.
	if config.has_section("api"):

		# Store the API base URL.
		api_base_url = config.get_value(
			"api",
			"base_url",
			""
		)

	else:

		push_error(
			"The [api] section was not found in env.cfg!"
		)
