extends Control

@onready var problem_label = $MarginContainer/VBoxContainer/Label
@onready var answer_input = $MarginContainer/VBoxContainer/LineEdit
@onready var check_button = $MarginContainer/VBoxContainer/HBoxContainer/Button
@onready var math_logic = $MathChallenge

signal startup_complete()

#привет матвей

func _ready() -> void:
	visible = false
	# Подписка на сигналы логики
	math_logic.problem_generated.connect(_on_problem_generated)
	math_logic.challenge_solved.connect(_on_challenge_solved)
	math_logic.challenge_failed.connect(_on_challenge_failed)
	check_button.pressed.connect(_on_check_pressed)

func open_popup() -> void:
	visible = true
	answer_input.text = ""
	answer_input.grab_focus()
	math_logic.generate_problem(1)

func _on_problem_generated(text: String) -> void:
	problem_label.text = text
	problem_label.modulate = Color.WHITE

func _on_check_pressed() -> void:
	if answer_input.text.is_empty() or not answer_input.text.is_valid_int():
		problem_label.text = "⚠️ Введите число!"
		return
	math_logic.check_answer(int(answer_input.text))

func _on_challenge_solved(reward: int) -> void:
	GameManager.add_money(reward)
	problem_label.text = "✅ Верно! +%d$" % reward
	await get_tree().create_timer(1.0).timeout
	close_popup()
	startup_complete.emit()

func _on_challenge_failed() -> void:
	problem_label.text = "❌ Ошибка! Попробуй снова."
	await get_tree().create_timer(1.0).timeout
	math_logic.generate_problem(1)

func close_popup() -> void:
	visible = false
