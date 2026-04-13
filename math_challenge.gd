extends Node

signal problem_generated(text: String)
signal challenge_solved(reward: int)
signal challenge_failed()

var current_answer: int = 0

func generate_problem(difficulty: int = 1) -> void:
	var a = randi_range(1, 10 * difficulty)
	var b = randi_range(1, 10 * difficulty)
	current_answer = a + b
	problem_generated.emit("%d + %d = ?" % [a, b])

func check_answer(user_answer: int) -> void:
	if user_answer == current_answer:
		challenge_solved.emit(50) # Награда за правильный ответ
	else:
		challenge_failed.emit()
