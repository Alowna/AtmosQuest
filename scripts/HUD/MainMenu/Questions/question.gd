extends Control

@onready var QuestionScreen = $QuestionScreen
@onready var QuestionPop = $QuestionPop
@onready var QuestionManager = $QuestionScreen/QuestionManager
@onready var Hull = $"../Hull"


# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	QuestionPop.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
func start() -> void:
	visible = true
	

	Hull.visible = false
	
	QuestionManager.load_question()
	
	QuestionPop.visible = true
	QuestionScreen.visible = false
	
	QuestionPop.play("PopUp")
	await QuestionPop.animation_finished
	
	QuestionPop.stop()
	QuestionPop.frame = 0
	QuestionPop.visible = false
	
	QuestionPop.visible = false
	QuestionScreen.visible = true
	
	
	
func popout() -> void:
	QuestionScreen.visible = false
	QuestionPop.visible = true

	QuestionPop.animation = "PopOut"
	QuestionPop.frame = 0
	QuestionPop.play()

	await QuestionPop.animation_finished
	Hull.visible = true
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
