class_name LocalQuestionProvider
extends QuestionProvider

func get_questions(category_id: int) -> Array[Question]:

	var questions: Array[Question] = []

	var q1 := Question.new()
	q1.id = 1
	q1.category_id = category_id
	q1.text = "Você é bobo?"
	q1.answers = [
		"Sim..",
		"Claro que não!",
		"Nope",
		"De forma alguma"
	]
	q1.correct_answer = 0

	questions.append(q1)


	var q2 := Question.new()
	q2.id = 2
	q2.category_id = category_id
	q2.text = "Soy el fuego que"
	q2.answers = [
		"Calienta tu pena",
		"Queima a amazonia",
		"Forja",
		"Arde nozoio"
	]
	q2.correct_answer = 0

	questions.append(q2)


	return questions
	# monta perguntas
