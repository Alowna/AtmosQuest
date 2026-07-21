extends Node2D

@onready var QuestionControl = $"../.."
@onready var Statement: Label = $Statement
@onready var AnswerA: Button = $AnswerA
@onready var AnswerB: Button = $AnswerB
@onready var AnswerC: Button = $AnswerC
@onready var AnswerD: Button = $AnswerD

# Variable to hold the current question data so we can validate it later
var current_question: Dictionary = {}
signal question_finished

func _ready() -> void:
		# Connect button signals via code and bind a String parameter to identify them
		AnswerA.pressed.connect(_on_answer_button_pressed.bind("A"))
		AnswerB.pressed.connect(_on_answer_button_pressed.bind("B"))
		AnswerC.pressed.connect(_on_answer_button_pressed.bind("C"))
		AnswerD.pressed.connect(_on_answer_button_pressed.bind("D"))
		
func load_question() -> void:
	# Fetch a random question from the Autoload memory
	current_question = getRandomQuestion(PlayerConfig.atmosLayer)
	
	if not current_question.is_empty():
		Statement.text = current_question.statement
		AnswerA.text = current_question.answer_a
		AnswerB.text = current_question.answer_b
		AnswerC.text = current_question.answer_c
		AnswerD.text = current_question.answer_d
		

	else:
		Statement.text = "All questions answered for this layer!"
		AnswerA.disabled = true
		AnswerB.disabled = true
		AnswerC.disabled = true
		AnswerD.disabled = true
		close_popup()

func getRandomQuestion(layer_id: int) -> Dictionary:
	var available_questions: Array = []
	
	# Fetch from PlayerConfig instead of a local variable
	for q in PlayerConfig.all_questions:
		if q.layer_id == layer_id and not (q.id in PlayerConfig.answeredQuestions):
			available_questions.append(q)
			
	if available_questions.size() > 0:
		return available_questions.pick_random()
		
	return {}

func _on_answer_button_pressed(selected_option: String) -> void:
	# Check if the clicked button matches the correct answer from the JSON
	if selected_option == current_question.correct_answer:
		print("Correct Answer!")
		# Add this question ID to the correct answers Ids 
		PlayerConfig.correctAnswersIds.append(current_question.id)
		PlayerConfig.correctAnswer()
		
		# Add this question ID to the answered list so it doesn't appear again
		PlayerConfig.answeredQuestions.append(current_question.id)
		
		# Add code here to reward the player (points, move forward, etc.)
		close_popup()
	else:
		print("Wrong Answer!")
		# Add this question ID to the wrong answers Ids 
		PlayerConfig.wrongAnswersIds.append(current_question.id)
		# Add this question ID to the answered list so it doesn't appear again
		PlayerConfig.answeredQuestions.append(current_question.id)
		PlayerConfig.wrongAnswer()
		# Add code here to punish the player (lose HP, retry, etc.)
		close_popup()

func close_popup() -> void:
	
	await QuestionControl.popout()
	question_finished.emit()
	print("Perguntas Corretas: ", PlayerConfig.correctAnswers)
	print("Perguntas Erradas: ", PlayerConfig.wrongAnswers)
	print("Perguntas Respondidas: ", PlayerConfig.answeredQuestions)
	# Add animation or sound before freeing if you want
	
	
	get_tree().paused = false
	
