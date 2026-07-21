extends Node2D

@onready var PropellerFire = $PropellerFire
@onready var WingsFire = $WingsFire
@onready var CofferFire = $CofferFire
@onready var FinalFire = $FinalFire

var propellerStarted := false
var wingsStarted := false
var cofferStarted := false
var finalStarted := false

var transitioning := false
var currentAtmosLayer := -1


func _ready() -> void:
	PropellerFire.visible = false
	WingsFire.visible = false
	CofferFire.visible = false
	FinalFire.visible = false


func _process(_delta: float) -> void:
	if transitioning:
		return

	if PlayerConfig.atmosLayer != currentAtmosLayer:
		currentAtmosLayer = PlayerConfig.atmosLayer
		enableFire(currentAtmosLayer)


func enableFire(atmosLayer: int) -> void:
	match atmosLayer:
		0:
			if not propellerStarted:
				startPropeller()
		1:
			if not wingsStarted:
				startWings()
		2:
			if not cofferStarted:
				startCoffer()
		4:
			if not finalStarted:
				startFinal()


func startPropeller() -> void:
	transitioning = true
	propellerStarted = true

	PropellerFire.visible = true
	PropellerFire.play("SpawnFire")

	await PropellerFire.animation_finished

	PropellerFire.play("LoopFire")

	transitioning = false


func startWings() -> void:
	transitioning = true
	wingsStarted = true

	PropellerFire.play("KillFire")

	await PropellerFire.animation_finished

	PropellerFire.visible = false

	WingsFire.visible = true
	WingsFire.play("SpawnFire")

	await WingsFire.animation_finished

	WingsFire.play("LoopFire")

	transitioning = false


func startCoffer() -> void:
	transitioning = true
	cofferStarted = true

	WingsFire.play("KillFire")

	await WingsFire.animation_finished

	WingsFire.visible = false

	CofferFire.visible = true
	CofferFire.play("SpawnFire")

	await CofferFire.animation_finished

	CofferFire.play("LoopFire")

	transitioning = false


func startFinal() -> void:
	transitioning = true
	finalStarted = true

	CofferFire.play("KillFire")

	await CofferFire.animation_finished

	CofferFire.visible = false

	FinalFire.visible = true
	FinalFire.play("SpawnFire")

	await FinalFire.animation_finished

	FinalFire.play("LoopFire")

	transitioning = false
