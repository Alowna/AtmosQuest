from fastapi import FastAPI
from pydantic import BaseModel, Field
from typing import Literal
from fastapi import HTTPException
from typing import Optional
import secrets
import string

app = FastAPI()




#######################################################
# HEALTH CHECK / PING ENDPOINT
# Lightweight route to check if the server is online
#######################################################

@app.get("/health")
def health_check():
    return {"status": "online"}


#######################################################
#   LOBBIES                                           #
#######################################################

# Represents a player inside a lobby
class Player(BaseModel):
    id: Optional[int] = None
    username: str
    shipSkin: int
    pilotSkin: int

# Represents a game lobby containing players
class Lobby(BaseModel):
    key: str
    ownerId: int
    players: list[Player] = Field(default_factory=list)


# Global storage for active lobbies and online players
Lobbies = []    
Players = []

# Generates a random alphanumeric string for lobby keys
def generate_lobby_key(length=6):
    chars = (
        string.ascii_uppercase +
        string.ascii_lowercase +
        string.digits  
    )
    return ''.join(secrets.choice(chars) for _ in range(length))

# Ensures the generated lobby key is completely unique among active lobbies
def generate_unique_lobby_key():
    while True:
        key = generate_lobby_key()
        if not any(lobby.key == key for lobby in Lobbies):
            return key

# Route: Registers a new player when they join the server/main menu
# Processing: Assigns a unique incremental ID and stores the player in the global Players list.
@app.post("/join_server")
def createPlayer(player: Player):
    playerid = len(Players) + 1
    new_player = Player(
        id=playerid, 
        username=player.username, 
        shipSkin=player.shipSkin, 
        pilotSkin=player.pilotSkin
    )
    Players.append(new_player)
    return new_player

# Route: Creates a new lobby
# Processing: Generates a unique key, assigns the creator as the owner, adds them to the lobby, and stores it.
@app.post("/create_lobby")
def createLobby(ownerId: int):
    lobbyKey = generate_unique_lobby_key()
    lobby = Lobby(
        key=lobbyKey,
        ownerId=ownerId
    )
    # Find the owner in the global player list and add them to the lobby
    for player in Players:
        if player.id == ownerId:
            lobby.players.append(player)
            break
    
    Lobbies.append(lobby)
    return {
        "lobbyKey": lobby.key,
        "lobbyPlayers": lobby.players,
        "ownerId": ownerId
    }

# Route: Adds a player to an existing lobby
# Processing: Validates player existence, checks for duplicates, enforces lobby capacity (max 10), and adds the player.
@app.post("/join_lobby")
def joinLobby(lobbyKey: str, playerId: int):
    joiningPlayer = None
    
    # Locate the joining player in the global list
    for player in Players:
        if player.id == playerId:
            joiningPlayer = player
            break
            
    if joiningPlayer is None:
        return {"error": "Player not found"}
        
    # Locate the requested lobby
    for lobby in Lobbies:
        if lobby.key == lobbyKey:
            # Prevent duplicate joins from the same player
            for player in lobby.players:
                if player.id == playerId:
                    return {
                        "lobbyKey": lobby.key,
                        "players": lobby.players
                    }
                    
            # Enforce maximum lobby capacity of 10 players
            if len(lobby.players) >= 10:
                return {"error": "Lobby full"}
                
            lobby.players.append(joiningPlayer)
            return {
                "lobbyKey": lobby.key,
                "players": lobby.players,
                "ownerId": lobby.ownerId
            }
            
    return {"error": "Lobby not found"}


# Route: Removes a player from a lobby
# Processing: Handles ownership transfer if the owner leaves, deletes the lobby if empty, and removes the player globally.
@app.post("/leave_lobby")
def leaveLobby(lobbyKey: str, playerId: int):
    # Find the target lobby
    lobby = next((l for l in Lobbies if l.key == lobbyKey), None)
    if lobby is None:
        raise HTTPException(status_code=404, detail="Lobby not found")
        
    # Find the player inside that lobby
    player = next((p for p in lobby.players if p.id == playerId), None)
    if player is None:
        raise HTTPException(status_code=404, detail="Player not found in lobby")
        
    # Remove player from the lobby
    lobby.players.remove(player)
    
    # Remove the player from the global player list (cleanup)
    Players[:] = [p for p in Players if p.id != playerId]
    
    # Handle lobby ownership transfer or lobby deletion
    if lobby.ownerId == playerId:
        if lobby.players:
            # Transfer ownership to the next available player
            lobby.ownerId = lobby.players[0].id
        else:
            # No players left, delete the empty lobby
            Lobbies.remove(lobby)
            return {
                "message": "Lobby deleted because it became empty"
            }
            
    return {
        "message": "Player left the lobby",
        "ownerId": lobby.ownerId,
        "players": lobby.players
    }

# Route: Fetches all active lobbies
# Processing: Returns the entire Lobbies array.
@app.get("/get_lobbies")
def getLobbies():
    return Lobbies

# Route: Fetches the current state of a specific lobby
# Processing: Searches for the lobby by key and returns its details if found.
@app.get("/get_lobby/{lobbyKey}")
def getLobby(lobbyKey: str):
    for lobby in Lobbies:
        if lobby.key == lobbyKey:
            return {
                "lobbyKey": lobby.key,
                "ownerId": lobby.ownerId,
                "players": lobby.players
            }
    raise HTTPException(
        status_code=404,
        detail="Lobby not found"
    )

# Route: Fetches all global players
# Processing: Returns the entire Players array.
@app.get("/get_players")
def getPlayers():
    return Players

#######################################################
# GAME EVENTS
#######################################################

# Represents in-game notifications (chat/UI events)
class GameEvent(BaseModel):
    id: int
    # Event types: score | life_lost | death | atmosphere | finish
    type: str
    playerId: int
    # Optional numeric value (e.g., current points or remaining lives)
    value: int | None = None
    # Optional custom message payload
    message: str | None = None

#######################################################
# PLAYER STATE INSIDE THE GAME
#######################################################

# Represents a player's active state during an ongoing match
class gamePlayer(BaseModel):
    id: int
    username: str
    shipSkin: int
    pilotSkin: int
    # Current game state flags
    deathStateSent: bool = False
    atmosLayer: int
    isAlive: bool
    finished: bool
    lives: int
    altitude: int
    maxAltitude: int
    points: int
    # Game statistics for post-match processing
    collisions: int
    correctAnswers: int
    wrongAnswers: int
    # Death information log
    collisionDeathObject: str

#######################################################
# GAME STATE
#######################################################

# Represents an active game instance
class Game(BaseModel):
    key: str
    # List of players actively playing
    players: list[gamePlayer] = Field(default_factory=list)
    # Event queue for clients to fetch and display messages
    events: list = Field(default_factory=list) # Assumindo que GameEvent está definido em outro lugar
    # Counter to assign unique incremental IDs to events
    nextEventId: int = 1
    # Global game status
    isFinished: bool = False

#######################################################
# ACTIVE GAMES STORAGE
#######################################################
games: list[Game] = []
Players = [] # Assumindo que existe globalmente
Lobbies = [] # Assumindo que existe globalmente

#######################################################
# CREATE GAME FROM LOBBY
#######################################################

@app.post("/create_game")
def createGame(lobbyKey: str):
    # Avoid duplicate game creation for the same key
    for game in games:
        if game.key == lobbyKey:
            raise HTTPException(
                status_code=400,
                detail="Game key already created."
            )
            
    # Locate the target lobby to start the game
    lobby_to_start = None
    for lobby in Lobbies:
        if lobby.key == lobbyKey:
            lobby_to_start = lobby
            
            # Initialize the new game instance
            game = Game(key=lobbyKey)
            
            # Convert lobby players into active game players with default starting stats
            for player in lobby.players:
                game_player = gamePlayer(
                    id=player.id,
                    username=player.username,
                    shipSkin=player.shipSkin,
                    pilotSkin=player.pilotSkin,
                    # Initial state
                    atmosLayer=0,
                    isAlive=True,
                    finished=False,
                    lives=6,
                    altitude=0,
                    maxAltitude=0,
                    points=0,
                    # Statistics
                    collisions=0,
                    correctAnswers=0,
                    wrongAnswers=0,
                    # Death information
                    collisionDeathObject="Unknown" # Padronizado
                )
                game.players.append(game_player)
                
            # Save the initialized game
            games.append(game)
            
            # Cleanup: Remove these players from the global pre-game lists
            player_ids_in_lobby = [p.id for p in lobby_to_start.players]
            Players[:] = [p for p in Players if p.id not in player_ids_in_lobby]
            Lobbies.remove(lobby_to_start)
            
            return game
            
    raise HTTPException(
        status_code=404,
        detail="Lobby not found."
    )

@app.post("/leave_server")
def leave_server(id: int):
    for player in Players:
        if player.id == id:
            Players.remove(player)
            return {"success": True}
    return {"success": False, "message": "Player not found"}


#######################################################
# CLIENT ACTION MODEL
#######################################################

class GameAction(BaseModel):
    gameKey: str
    playerId: int
    # Allowed action types
    action: Literal["altitude", "question_result", "finish"]
    # Used when action == "altitude"
    isAlive: bool | None = None
    altitude: int | None = None
    atmosLayer: int | None = None
    # Used when action == "question_result" AND "altitude" (para registrar colisões em objetos)
    collisionObject: str | None = None
    correctAnswer: bool | None = None

    lives: int | None = None
    points: int | None = None
    collisions: int | None = None
    correctAnswers: int | None = None
    wrongAnswers: int | None = None

#######################################################
# UPDATE GAME STATE
#######################################################

@app.post("/game_action")
def gameAction(action: GameAction):
    # Locate the active game
    game = next((g for g in games if g.key == action.gameKey), None)
    if game is None:
        raise HTTPException(status_code=404, detail="Game not found.")
        
    # Locate the target player within the game
    player = next((p for p in game.players if p.id == action.playerId), None)
    if player is None:
        raise HTTPException(status_code=404, detail="Player not found.")
        
    # Prevent dead players from continuously altering the game state
    # MUDANÇA: Retorna success suave em vez de crashar a requisição HTTP
    if not player.isAlive:
        if not player.deathStateSent:
            player.deathStateSent = True
        else:
            return {"success": False, "message": "Player is already dead, action ignored."}
        
    # Process: Altitude update
    if action.action == "altitude":
        # Validações seguras contra valores nulos antes de atualizar
        if action.altitude is not None:
            player.altitude = action.altitude
            # Só atualiza a maxAltitude se o valor atual for maior
            if player.altitude > player.maxAltitude:
                player.maxAltitude = player.altitude

        if action.atmosLayer is not None: player.atmosLayer = action.atmosLayer
        if action.isAlive is not None: player.isAlive = action.isAlive
        if action.lives is not None: player.lives = action.lives
        if action.points is not None: player.points = action.points
        if action.collisions is not None: player.collisions = action.collisions
        if action.correctAnswers is not None: player.correctAnswers = action.correctAnswers
        if action.wrongAnswers is not None: player.wrongAnswers = action.wrongAnswers
                
        if action.atmosLayer is not None:
            player.atmosLayer = action.atmosLayer
            
        if action.isAlive is not None:
            player.isAlive = action.isAlive
            
        # MUDANÇA: Se o jogador informou que morreu na atualização de altitude, salva o objeto!
        if player.isAlive == False and action.collisionObject:
            player.collisionDeathObject = action.collisionObject

        return {"success": True}
        
    # Process: Handling collision/question responses
    elif action.action == "question_result":
        player.collisions += 1
        
        # Handle correct answer scenario
        if action.correctAnswer:
            player.correctAnswers += 1
            player.points += 100
            
            # Broadcast score event
            game.events.append(
                GameEvent(
                    id=game.nextEventId,
                    type="score",
                    playerId=player.id,
                    value=player.points
                )
            )
            
        # Handle wrong answer scenario
        else:
            player.wrongAnswers += 1
            player.lives -= 1
            
            # Check for player death
            if player.lives <= 0:
                player.lives = 0
                player.isAlive = False
                player.deathStateSent = False
                # Captura o objeto fornecido ou coloca "Unknown"
                player.collisionDeathObject = action.collisionObject or "Unknown"
                
                # Broadcast death event
                game.events.append(
                    GameEvent(
                        id=game.nextEventId,
                        type="death",
                        playerId=player.id
                    )
                )
            else:
                # Player survives but loses a life, broadcast life_lost event
                game.events.append(
                    GameEvent(
                        id=game.nextEventId,
                        type="life_lost",
                        playerId=player.id,
                        value=player.lives
                    )
                )
        game.nextEventId += 1
        return {"success": True}
        
    # Process: Player finishes the game
    elif action.action == "finish":
        player.finished = True
        # Broadcast finish event
        game.events.append(
            GameEvent(
                id=game.nextEventId,
                type="finish",
                playerId=player.id
            )
        )
        game.nextEventId += 1
        return {"success": True}
        
    raise HTTPException(status_code=400, detail="Invalid action.")


#######################################################
# GET GAME STATE (POLLING)
#######################################################

@app.get("/get_game_state/{gameKey}")
def getGameState(gameKey: str):
    game = next((g for g in games if g.key == gameKey), None)
    if game is None:
        raise HTTPException(
            status_code=404,
            detail="Game not found."
        )
    return game

#######################################################
# END GAME / CLEANUP
#######################################################

@app.delete("/end_game/{gameKey}")
def endGame(gameKey: str):
    game_to_delete = next((g for g in games if g.key == gameKey), None)
    if game_to_delete is None:
        raise HTTPException(
            status_code=404,
            detail="Game not found or already deleted."
        )
    games.remove(game_to_delete)
    return {"success": True, "message": f"Game {gameKey} and all its data were deleted."}

#######################################################
# LEAVE GAME (MID-GAME QUIT)
#######################################################

@app.post("/leave_game")
def leaveGame(gameKey: str, playerId: int):
    # Locate the active game
    game = next((g for g in games if g.key == gameKey), None)
    if game is None:
        raise HTTPException(
            status_code=404, 
            detail="Game not found."
        )
        
    # Find the player inside the game
    player_to_remove = next((p for p in game.players if p.id == playerId), None)
    
    if player_to_remove:
        # 1. Remove the player from the active game
        game.players.remove(player_to_remove)
        
        # 2. (Optional) Broadcast an event so other clients know this player left
        game.events.append(
            GameEvent(
                id=game.nextEventId,
                type="disconnect", # Or "leave"
                playerId=playerId
            )
        )
        game.nextEventId += 1
        
        # 3. CLEANUP: If the game is now completely empty, delete it from the server
        if len(game.players) == 0:
            games.remove(game)
            print(f"Game '{gameKey}' deleted because all players left mid-game.")
            
        return {"success": True, "message": "Player removed from game."}
        
    # If game exists but player isn't in it (maybe already left/deleted)
    return {"success": False, "message": "Player not found in this game."}  