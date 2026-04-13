extends Node

@onready var math_popup = $"/root/Main/UI/MathPopup"

func _ready() -> void:
	# Если начинаем с нуля или денег нет → принудительно открываем обучение
	if GameManager.money <= 0:
		math_popup.startup_complete.connect(_on_startup_complete)
		math_popup.open_popup()
	else:
		print("Игра загружена. Баланс: %d$" % GameManager.money)

func _on_startup_complete() -> void:
	print("🎉 Стартовый капитал получен. Игра разблокирована.")
	# Здесь запускаем таймер спавна машин, активируем кнопки магазина и т.д.
