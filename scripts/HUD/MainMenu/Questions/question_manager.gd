extends Node2D

@onready var QuestionControl = $"../.."

@onready var Statement: Label = $Statement
@onready var AnswerA: Button = $AnswerA
@onready var AnswerB: Button = $AnswerB
@onready var AnswerC: Button = $AnswerC
@onready var AnswerD: Button = $AnswerD
@onready var TimerLabel: Label = $TimerLabel


# Stores the current question data so we can validate the answer later
var current_question: Dictionary = {}

# Controls the countdown timer
var time_left: float = 30.0
var timer_active: bool = false


signal question_finished


func _ready() -> void:
	# Connect button signals via code and bind a String parameter to identify each button
	AnswerA.pressed.connect(_on_answer_button_pressed.bind("A"))
	AnswerB.pressed.connect(_on_answer_button_pressed.bind("B"))
	AnswerC.pressed.connect(_on_answer_button_pressed.bind("C"))
	AnswerD.pressed.connect(_on_answer_button_pressed.bind("D"))

	# Initialize the timer label
	TimerLabel.text = str(ceil(time_left))


func _process(delta: float) -> void:
	# Countdown only runs while a question is active
	if timer_active:
		time_left -= delta

		# Update the timer text on screen
		TimerLabel.text = str(ceil(time_left))

		# If time reaches zero, the question is automatically wrong
		if time_left <= 0:
			timer_active = false
			time_out()


func load_question() -> void:
	# Fetch a random question from the Autoload memory
	current_question = getRandomQuestion(PlayerConfig.atmosLayer)

	if not current_question.is_empty():

		Statement.text = current_question.statement
		AnswerA.text = current_question.answer_a
		AnswerB.text = current_question.answer_b
		AnswerC.text = current_question.answer_c
		AnswerD.text = current_question.answer_d


		# Reset and start the countdown timer
		time_left = 30.0
		timer_active = true
		TimerLabel.text = str(ceil(time_left))


	else:
		Statement.text = "All questions answered for this layer!"
		close_popup()



func getRandomQuestion(layer_id: int) -> Dictionary:

	var available_questions: Array = []

	print("Current layer: ", PlayerConfig.atmosLayer)


	# Search for unanswered questions from the current layer
	for q in PlayerConfig.all_questions:
		if q.layer_id == layer_id and not (q.id in PlayerConfig.answeredQuestions):
			available_questions.append(q)


	# Return a random available question
	if available_questions.size() > 0:
		return available_questions.pick_random()


	return {}



func _on_answer_button_pressed(selected_option: String) -> void:

	# Stop the timer when the player answers
	timer_active = false


	# Check if the selected button matches the correct answer
	if selected_option == current_question.correct_answer:

		print("Correct Answer!")

		# Update correct answer counter
		PlayerConfig.correctAnswer(current_question.id)


		# Reward the player depending on how fast they answered
		if time_left >= 20:

			PlayerConfig.points += 200
			print("Speed bonus: +200 points")


		elif time_left >= 10:

			PlayerConfig.points += 100
			print("Speed bonus: +100 points")


		else:

			print("No speed bonus")


		close_popup()


	else:

		print("Wrong Answer!")

		# Update wrong answer counter
		PlayerConfig.wrongAnswer(current_question.id)


		close_popup()



func time_out() -> void:

	print("Time is over! Question counted as wrong.")

	PlayerConfig.wrongAnswer(current_question.id)


	close_popup()



func close_popup() -> void:

	# Play closing animation before removing the popup
	await QuestionControl.popout()


	# Notify whoever opened this question that it has finished
	question_finished.emit()


	# Debug information
	print("Correct answers: ", PlayerConfig.correctAnswers)
	print("Wrong answers: ", PlayerConfig.wrongAnswers)
	print("Answered questions: ", PlayerConfig.answeredQuestions)
	print("Current points: ", PlayerConfig.points)


	# Resume the game
	get_tree().paused = false
