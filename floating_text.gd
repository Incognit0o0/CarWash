extends Node2D

@export var label: Label

@export var fade_speed: float = 2.0
@export var move_speed: float = 20.0

func setup(text: String, color: Color = Color.GREEN) -> void:
	label.text = text
	label.modulate = color

func _process(delta: float) -> void:
	# Движение вверх
	position.y -= move_speed * delta
	
	# Исчезновение
	label.modulate.a -= fade_speed * delta
	
	# Удаление, когда стал прозрачным
	if label.modulate.a <= 0:
		queue_free()
