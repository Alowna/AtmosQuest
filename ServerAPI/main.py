from fastapi import FastAPI
from pydantic import BaseModel, Field
from typing import Literal
from fastapi import HTTPException
from typing import Optional
import secrets

app = FastAPI()

#######################################################
#   LOBBIES                                           #
#                                                     #
#######################################################

#Lobby player class
class Player(BaseModel):
    id: Optional[int] = None
    username: str
    rocketSkin: int
    playerSkin: int

#Lobby class
class Lobby(BaseModel):
    key: str
    players: list[Player] = Field(default_factory=list)


#Lobby and Player arrays
Lobbies = []    
Players = []

#generate random lobby key
def generate_lobby_key(length=6):
    chars = (
        string.ascii_uppercase +
        string.ascii_lowercase +
        string.digits
         + "!@#$%"  
    )

    return ''.join(secrets.choice(chars) for _ in range(length))

def generate_unique_lobby_key():
    while True:
        key = generate_lobby_key()

        if not any(lobby.key == key for lobby in Lobbies):
            return key

#Receive players joining the game lobby menu
@app.post("/join_server")
def createPlayer(player: Player):
    playerid = len(Players) + 1
    new_player = Player(
        id=playerid, 
        username=player.username, 
        rocketSkin=player.rocketSkin, 
        playerSkin=player.playerSkin
    )
    Players.append(new_player)
    return new_player

#Receive players creating a lobby
@app.post("/create_lobby")
def createLobby(ownerId: int):
    lobbyKey = generate_unique_lobby_key()

    lobby = Lobby(key=lobbyKey)

    for player in Players:
        if player.id == ownerId:
            lobby.players.append(player)
            break

    Lobbies.append(lobby)

    return {
        "lobbyKey": lobby.key,
        "lobby": lobby
    }

#Receive players joining a lobby through key
@app.post("/join_lobby")
def joinLobby(lobbyKey: str, playerId: int):
    joiningPlayer = None

    # Find player
    for player in Players:
        if player.id == playerId:
            joiningPlayer = player
            break

    if joiningPlayer is None:
        return {"error": "Player not found"}

    # Find lobby
    for lobby in Lobbies:
        if lobby.key == lobbyKey:
            lobby.players.append(joiningPlayer)
            return lobby

    return {"error": "Lobby not found"}

#Get lobbies for loading lobbies menu
@app.get("/get_lobbies")
def getLobbies():
    return Lobbies

@app.get("/get_players")
def getPlayers():
    return Players

#######################################################
# GAME EVENTS
# Used for the in-game chat / notifications
#######################################################

class GameEvent(BaseModel):

    id: int

    # score | life_lost | death | atmosphere | finish
    type: str

    playerId: int

    # Optional numeric value
    # Example: current points or remaining lives
    value: int | None = None

    # Optional custom message
    message: str | None = None



#######################################################
# PLAYER STATE INSIDE THE GAME
#######################################################

class gamePlayer(BaseModel):

    id: int
    username: str

    rocketSkin: int
    playerSkin: int


    ############################
    # Current game state
    ############################

    isAlive: bool
    finished: bool

    lives: int

    altitude: int
    maxAltitude: int

    points: int


    ############################
    # Game statistics
    ############################

    collisions: int

    correctAnswers: int

    wrongAnswers: int


    ############################
    # Death information
    ############################

    collisionDeathObject: str



#######################################################
# GAME STATE
#######################################################

class Game(BaseModel):

    key: str


    # All players currently in this game
    players: list[gamePlayer] = Field(
        default_factory=list
    )


    # Events used by clients to display messages
    events: list[GameEvent] = Field(
        default_factory=list
    )


    # Used to create unique event IDs
    nextEventId: int = 1


    # Game status
    isFinished: bool = False



#######################################################
# ACTIVE GAMES STORAGE
#######################################################

games: list[Game] = []



#######################################################
# CREATE GAME FROM LOBBY
#######################################################

@app.post("/create_game")
def createGame(lobbyKey: str):


    ############################
    # Avoid duplicate games
    ############################

    for game in games:

        if game.key == lobbyKey:

            raise HTTPException(
                status_code=400,
                detail="Game key already created."
            )



    ############################
    # Find lobby
    ############################

    lobby_to_start = None

    for lobby in Lobbies:
        

        if lobby.key == lobbyKey:
            lobby_to_start = lobby


            ############################
            # Create new game
            ############################

            game = Game(
                key=lobbyKey
            )



            ############################
            # Convert lobby players
            # into game players
            ############################

            for player in lobby.players:


                game_player = gamePlayer(

                    id=player.id,

                    username=player.username,


                    # Player customization
                    rocketSkin=player.rocketSkin,
                    playerSkin=player.playerSkin,


                    ####################
                    # Initial state
                    ####################

                    isAlive=True,

                    finished=False,

                    lives=6,

                    altitude=0,

                    maxAltitude=0,

                    points=0,


                    ####################
                    # Statistics
                    ####################

                    collisions=0,

                    correctAnswers=0,

                    wrongAnswers=0,


                    ####################
                    # Death information
                    ####################

                    collisionDeathObject="none"
                )


                # Add player to game
                game.players.append(
                    game_player
                )



            ############################
            # Save game
            ############################

            games.append(game)

            # If lobby not found
            if lobby_to_start is None:
                raise HTTPException(
                    status_code=404,
                    detail="Lobby not found."
                )

            ###################################################
            # CLEANUP
            ###################################################
            
            # Get all players in lobby by id
            player_ids_in_lobby = [p.id for p in lobby_to_start.players]
            
            # Remove players from global online players
            Players[:] = [p for p in Players if p.id not in player_ids_in_lobby]
            
            # Remove lobby from global online Lobbies
            Lobbies.remove(lobby_to_start)

            # Return created game
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
#
# Godot sends events here.
# The server decides the result.
#######################################################

class GameAction(BaseModel):

    gameKey: str

    playerId: int


    # Available actions
    action: Literal[
        "altitude",
        "question_result",
        "finish"
    ]


    ############################
    # Altitude update
    ############################

    altitude: int | None = None


    ############################
    # Question result
    ############################

    collisionObject: str | None = None

    correctAnswer: bool | None = None



#######################################################
# UPDATE GAME STATE
#######################################################

@app.post("/game_action")
def gameAction(action: GameAction):


    ############################
    # Find game
    ############################

    game = next(
        (
            g for g in games
            if g.key == action.gameKey
        ),
        None
    )


    if game is None:

        raise HTTPException(
            status_code=404,
            detail="Game not found."
        )



    ############################
    # Find player
    ############################

    player = next(
        (
            p for p in game.players
            if p.id == action.playerId
        ),
        None
    )


    if player is None:

        raise HTTPException(
            status_code=404,
            detail="Player not found."
        )



    ############################
    # Ignore actions from dead players
    ############################

    if not player.isAlive:

        raise HTTPException(
            status_code=400,
            detail="Player is already dead."
        )



    ###################################################
    # UPDATE ALTITUDE
    ###################################################

    if action.action == "altitude":


        player.altitude = action.altitude


        if action.altitude > player.maxAltitude:

            player.maxAltitude = action.altitude


        return {
            "success": True
        }



    ###################################################
    # QUESTION ANSWER AFTER COLLISION
    ###################################################

    elif action.action == "question_result":


        # Every question means one collision
        player.collisions += 1



        ############################
        # Correct answer
        ############################

        if action.correctAnswer:


            player.correctAnswers += 1

            # Reward points
            player.points += 100

            game.events.append(

                GameEvent(

                    id=game.nextEventId,
                    type="score",
                    playerId=player.id,
                    value=player.points

                )

            )

        ############################
        # Wrong answer
        ############################

        else:

            player.wrongAnswers += 1

            # Lose one life
            player.lives -= 1

            ########################
            # Player died
            ########################

            if player.lives <= 0:

                player.lives = 0
                player.isAlive = False

                player.collisionDeathObject = (
                    action.collisionObject
                    or "unknown"
                )

                game.events.append(

                    GameEvent(

                        id=game.nextEventId,

                        type="death",

                        playerId=player.id

                    )

                )



            ########################
            # Player survived
            ########################

            else:


                game.events.append(

                    GameEvent(

                        id=game.nextEventId,

                        type="life_lost",

                        playerId=player.id,

                        value=player.lives

                    )

                )



        game.nextEventId += 1



        return {
            "success": True
        }



    ###################################################
    # PLAYER FINISHED
    ###################################################

    elif action.action == "finish":


        player.finished = True



        game.events.append(

            GameEvent(

                id=game.nextEventId,

                type="finish",

                playerId=player.id

            )

        )


        game.nextEventId += 1



        return {
            "success": True
        }



    raise HTTPException(
        status_code=400,
        detail="Invalid action."
    )

#######################################################
# GET GAME STATE (POLLING)
#######################################################

@app.get("/get_game_state/{gameKey}")
def getGameState(gameKey: str):
    
    # Find game in active games
    game = next(
        (g for g in games if g.key == gameKey), 
        None
    )

    # if game doesnt exist
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
    
    #find ended game
    game_to_delete = next(
        (g for g in games if g.key == gameKey), 
        None
    )

    #if game not found
    if game_to_delete is None:
        raise HTTPException(
            status_code=404,
            detail="Game not found or already deleted."
        )

    # Remove game from global online Games
    games.remove(game_to_delete)
    
    return {"success": True, "message": f"Game {gameKey} and all its data were deleted."}