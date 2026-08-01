from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Literal, Optional, List
import secrets
import string
import time
import asyncio

app = FastAPI()

#######################################################
# HEALTH CHECK / PING ENDPOINT
# Lightweight route to check if the server is online
#######################################################

@app.get("/health")
def health_check():
    return {"status": "online"}


#######################################################
# pydantic models for request and response validation
#######################################################

class Player(BaseModel):
    id: Optional[int] = None
    username: str
    shipSkin: int
    pilotSkin: int

class Lobby(BaseModel):
    key: str
    ownerId: int
    players: List[Player] = Field(default_factory=list)

class GameEvent(BaseModel):
    id: int
    type: str  # score | life_lost | death | atmosphere | finish
    playerId: int
    value: Optional[int] = None
    message: Optional[str] = None

class GamePlayer(BaseModel):
    id: int
    username: str
    shipSkin: int
    pilotSkin: int
    deathStateSent: bool = False
    atmosLayer: int
    isAlive: bool
    finished: bool
    lives: int
    altitude: int
    maxAltitude: int
    points: int
    collisions: int
    correctAnswers: int
    wrongAnswers: int
    collisionDeathObject: str
    last_seen: float = Field(default_factory=time.time)

class Game(BaseModel):
    key: str
    players: List[GamePlayer] = Field(default_factory=list)
    events: List[GameEvent] = Field(default_factory=list)
    nextEventId: int = 1
    isFinished: bool = False

class GameAction(BaseModel):
    gameKey: str
    playerId: int
    action: Literal["altitude", "question_result", "finish"]

    isAlive: Optional[bool] = None
    finished: Optional[bool] = None
    altitude: Optional[int] = None
    atmosLayer: Optional[int] = None
    collisionObject: Optional[str] = None
    correctAnswer: Optional[bool] = None
    lives: Optional[int] = None
    points: Optional[int] = None
    collisions: Optional[int] = None
    correctAnswers: Optional[int] = None
    wrongAnswers: Optional[int] = None


#######################################################
# global arrays
#######################################################

Players: List[Player] = []
Lobbies: List[Lobby] = []
games: List[Game] = []


#######################################################
# UTIL FUNCTIONS
#######################################################

def generate_lobby_key(length: int = 6) -> str:
    chars = string.ascii_uppercase + string.ascii_lowercase + string.digits
    return ''.join(secrets.choice(chars) for _ in range(length))

def generate_unique_lobby_key() -> str:
    while True:
        key = generate_lobby_key()
        if not any(lobby.key == key for lobby in Lobbies):
            return key

def getRandomId() -> int:
    playerId = 1

    while any(player.id == playerId for player in Players):
        playerId += 1

    return playerId

#######################################################
# LOBBY AND PLAYER ROUTES
#######################################################




@app.post("/join_server")
def createPlayer(player: Player):
    playerid = getRandomId()
    new_player = Player(
        id=playerid,
        username=player.username,
        shipSkin=player.shipSkin,
        pilotSkin=player.pilotSkin
    )
    Players.append(new_player)
    return new_player

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

@app.post("/join_lobby")
def joinLobby(lobbyKey: str, playerId: int):
    joiningPlayer = next((p for p in Players if p.id == playerId), None)

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

@app.post("/leave_lobby")
def leaveLobby(lobbyKey: str, playerId: int):
    lobby = next((l for l in Lobbies if l.key == lobbyKey), None)
    if lobby is None:
        raise HTTPException(status_code=404, detail="Lobby not found")

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
            return {"message": "Lobby deleted because it became empty"}

    return {
        "message": "Player left the lobby",
        "ownerId": lobby.ownerId,
        "players": lobby.players
    }

@app.get("/get_lobbies")
def getLobbies():
    return Lobbies

@app.get("/get_lobby/{lobbyKey}")
def getLobby(lobbyKey: str):
    for lobby in Lobbies:
        if lobby.key == lobbyKey:
            return {
                "lobbyKey": lobby.key,
                "ownerId": lobby.ownerId,
                "players": lobby.players
            }
    raise HTTPException(status_code=404, detail="Lobby not found")

@app.get("/get_players")
def getPlayers():
    return Players

@app.post("/leave_server")
def leave_server(id: int):
    for player in Players:
        if player.id == id:
            Players.remove(player)
            return {"success": True}
    return {"success": False, "message": "Player not found"}


#######################################################
# GAME ROUTES
#######################################################

@app.post("/create_game")
def createGame(lobbyKey: str):
    # Avoid duplicate game creation for the same key
    if any(g.key == lobbyKey for g in games):
        raise HTTPException(status_code=400, detail="Game key already created.")

    # Locate the target lobby to start the game
    lobby_to_start = next((l for l in Lobbies if l.key == lobbyKey), None)

    if lobby_to_start:
        game = Game(key=lobbyKey)

        # Convert lobby players into active game players with default starting stats
        for player in lobby_to_start.players:
            game_player = GamePlayer(
                id=player.id,
                username=player.username,
                shipSkin=player.shipSkin,
                pilotSkin=player.pilotSkin,
                atmosLayer=0,
                isAlive=True,
                finished=False,
                lives=6,
                altitude=0,
                maxAltitude=0,
                points=0,
                collisions=0,
                correctAnswers=0,
                wrongAnswers=0,
                collisionDeathObject="Unknown"
            )
            game.players.append(game_player)

        games.append(game)

        # Cleanup: Remove these players from the global pre-game lists
        player_ids_in_lobby = {p.id for p in lobby_to_start.players}
        Players[:] = [p for p in Players if p.id not in player_ids_in_lobby]
        Lobbies.remove(lobby_to_start)

        return game

    raise HTTPException(status_code=404, detail="Lobby not found.")



@app.post("/game_action")
def gameAction(action: GameAction):
    game = next((g for g in games if g.key == action.gameKey), None)
    if game is None:
        raise HTTPException(status_code=404, detail="Game not found.")

    player = next((p for p in game.players if p.id == action.playerId), None)
    if player is None:
        raise HTTPException(status_code=404, detail="Player not found.")

    # 1. PROCESS: Explicit finish request
    # MUST REMAIN HERE, ABOVE THE DEATH BLOCK, to ensure dead players can finalize the match!
    if action.action == "finish":
        player.finished = True
        game.events.append(
            GameEvent(id=game.nextEventId, type="finish", playerId=player.id)
        )
        game.nextEventId += 1
        return {"success": True}

    # 2. DEATH STATE CHECK / RATE LIMITING
    # Prevents dead players from spamming altitude updates or score modifications
    if not player.isAlive:
        if not player.deathStateSent:
            player.deathStateSent = True
        else:
            # Returns 200 OK so the client engine doesn't break, but skips further logic
            return {"success": False, "message": "Player is already dead, action ignored."}

    # 3. PROCESS: Altitude Update
    if action.action == "altitude":
        if action.altitude is not None:
            player.altitude = action.altitude
            if player.altitude > player.maxAltitude:
                player.maxAltitude = player.altitude

        if action.atmosLayer is not None: player.atmosLayer = action.atmosLayer
        if action.isAlive is not None: player.isAlive = action.isAlive

        # Accepts dynamic finished status updates sent via regular client polling
        if action.finished is not None:
            player.finished = action.finished

        if action.lives is not None: player.lives = action.lives
        if action.points is not None: player.points = action.points
        if action.collisions is not None: player.collisions = action.collisions
        if action.correctAnswers is not None: player.correctAnswers = action.correctAnswers
        if action.wrongAnswers is not None: player.wrongAnswers = action.wrongAnswers

        if not player.isAlive and action.collisionObject:
            player.collisionDeathObject = action.collisionObject

        return {"success": True}

    # 4. PROCESS: Handling collision/question responses
    elif action.action == "question_result":
        player.collisions += 1

        if action.correctAnswer:
            player.correctAnswers += 1
            player.points += 100

            game.events.append(
                GameEvent(
                    id=game.nextEventId,
                    type="score",
                    playerId=player.id,
                    value=player.points
                )
            )
        else:
            player.wrongAnswers += 1
            player.lives -= 1

            if player.lives <= 0:
                player.lives = 0
                player.isAlive = False
                player.deathStateSent = False
                player.collisionDeathObject = action.collisionObject or "Unknown"

                game.events.append(
                    GameEvent(id=game.nextEventId, type="death", playerId=player.id)
                )
            else:
                game.events.append(
                    GameEvent(id=game.nextEventId, type="life_lost", playerId=player.id, value=player.lives)
                )
        game.nextEventId += 1
        return {"success": True}

    raise HTTPException(status_code=400, detail="Invalid action.")


@app.get("/get_game_state/{gameKey}")
def getGameState(gameKey: str):
    game = next((g for g in games if g.key == gameKey), None)
    if game is None:
        raise HTTPException(status_code=404, detail="Game not found.")
    return game

@app.delete("/end_game/{gameKey}")
def endGame(gameKey: str):
    game_to_delete = next((g for g in games if g.key == gameKey), None)
    if game_to_delete is None:
        raise HTTPException(status_code=404, detail="Game not found or already deleted.")

    games.remove(game_to_delete)
    return {"success": True, "message": f"Game {gameKey} and all its data were deleted."}

@app.post("/leave_game")
def leaveGame(gameKey: str, playerId: int):
    game = next((g for g in games if g.key == gameKey), None)
    if game is None:
        raise HTTPException(status_code=404, detail="Game not found.")

    player_to_remove = next((p for p in game.players if p.id == playerId), None)

    if player_to_remove:
        game.players.remove(player_to_remove)

        game.events.append(
            GameEvent(
                id=game.nextEventId,
                type="disconnect",
                playerId=playerId
            )
        )
        game.nextEventId += 1

        if len(game.players) == 0:
            games.remove(game)

        return {"success": True, "message": "Player removed from game."}

    return {"success": False, "message": "Player not found in this game."}

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(cleanup_players())

@app.post("/heartbeat")
def heartbeat(id: int):
    # 1. Search for players in the global Players list (to handle heartbeat updates in menus/lobbies)
    for player in Players:
        if player.id == id:
            player.last_seen = time.time()
            return {"status": "ok", "location": "menu_or_lobby"}

    # 2. Search for players in-game (to handle heartbeat updates during active matches)
    for game in games:
        for g_player in game.players:
            if g_player.id == id:
                g_player.last_seen = time.time()
                return {"status": "ok", "location": "in_game"}

    raise HTTPException(
        status_code=404,
        detail="Player not found"
    )


async def cleanup_players():
    while True:
        now = time.time()
        timeout_seconds = 90  # Limit time for player inactivity before removal

        # 1. Clean up players in the global Players list
        for player in Players[:]:
            if now - player.last_seen > timeout_seconds:
                print(f"Removendo jogador inativo: {player.id}")
                Players.remove(player)

                # Remove the player from any lobbies they are part of
                for lobby in Lobbies[:]:
                    if player in lobby.players:
                        lobby.players.remove(player)
                        # Pass the crown to another player or delete the empty lobby
                        if lobby.ownerId == player.id:
                            if lobby.players:
                                lobby.ownerId = lobby.players[0].id
                            else:
                                Lobbies.remove(lobby)

        # 2. In game clean up
        for game in games[:]:
            for g_player in game.players[:]:
                if now - g_player.last_seen > timeout_seconds:
                    print(f"Removendo jogador {g_player.id} da partida {game.key} por inatividade")
                    game.players.remove(g_player)

                    # Register disconnect event for the player in the game events
                    game.events.append(
                        GameEvent(id=game.nextEventId, type="disconnect", playerId=g_player.id)
                    )
                    game.nextEventId += 1

            # If game empty delete it
            if len(game.players) == 0:
                games.remove(game)

        await asyncio.sleep(10)