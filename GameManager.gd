extends Node

# Сигналы для UI и механики банкротства
signal money_changed(amount: int)
signal bankruptcy_check()

var money: int = 0
var day: int = 1

func _ready() -> void:
	# При старте можно загрузить сохранение или показать стартовый попап
	pass

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	else:
		# Денег не хватает → предлагаем решить пример
		check_bankruptcy()
		return false

func check_bankruptcy() -> void:
	# Исправлено: проверяем <= 0, т.к. spend_money не даёт уйти в минус
	if money <= 0:
		bankruptcy_check.emit()
