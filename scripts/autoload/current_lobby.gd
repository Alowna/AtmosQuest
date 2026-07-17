extends Node
#autoload for current lobby

var players = []
var lobbyKey: String = ""
var owner_id: int = -1

func clear():
	lobbyKey = ""
	players.clear()
	owner_id = -1
