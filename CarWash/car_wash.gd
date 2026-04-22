extends Node2D
class_name CarWash

# --- Сигналы ---
signal wash_completed(earnings: int)
signal upgrade_purchased(stage: int, level: int)

# --- Параметры мойки ---
@export var wash_price: int = 10
@export var upgrade_cost: int = 100

# Время этапов (в секундах)
@export var foam_time: float = 2.0
@export var water_time: float = 2.0
@export var dry_time: float = 2.0

@export var ui_icons: Array[Node] = []
@export var upgrade_buttons: Array[Button] = []
@export var floating_text_scene: PackedScene  # ← Ссылка на FloatingText.tscn

# Уровни улучшений для каждого этапа
var foam_level: int = 0
var water_level: int = 0
var dry_level: int = 0

# --- Состояние ---
var is_busy: bool = false
var current_car: Node2D = null

# --- Ссылки на узлы (заполнить в инспекторе!) ---
@onready var path_follow: PathFollow2D = $CarPath/PathFollow
@onready var wash_box_position: Vector2 = $WashBox.position


func _ready() -> void:
	print_tree()
	
	var path_node = get_node_or_null("CarPath")
	
	# Проверяем, что у PathFollow2D есть родитель Path2D
	var parent = path_follow.get_parent()
	update_upgrade_buttons()
	for icon in ui_icons:
		icon.modulate.a = 0.3
	
	# ТЕСТ: запустить машину через 1 секунду
	await get_tree().create_timer(1.0).timeout
	print("🧪 ТЕСТ: вызываю spawn_car()")
	spawn_car()



func spawn_car() -> void:
	if is_busy:
		return
	
	is_busy = true
	
	var car_scene = preload("res://CarWash/car.tscn")
	current_car = car_scene.instantiate()
	
	path_follow.add_child(current_car)
	current_car.position = Vector2.ZERO

	current_car.arrived_at_box.connect(_on_car_arrived)
	current_car.finished_and_leaving.connect(_on_car_left)
	
	current_car.drive_along_path(path_follow)
	print(" Машина заспавнена, мойка занята")

func _on_car_arrived() -> void:
	print("🧼 Начинаем цикл мойки...")
	await _run_wash_cycle()
	
	for icon in ui_icons:
		icon.modulate.a = 0.3
	
	if current_car:
		print("▶️ Запускаем resume()")
		current_car.resume()
		print("⏳ Ждём finished_and_leaving...")
		await current_car.finished_and_leaving
		print("✅ Сигнал получен, вызываем _on_car_left()")
		_on_car_left()
		
func _run_wash_cycle() -> void:
	await _run_stage(0, foam_time)
	await _run_stage(1, water_time)
	await _run_stage(2, dry_time)
	
	# 1. Деньги начисляем через GameManager (как было)
	GameManager.add_money(wash_price)
	
	# 2. Опыт даем через PlayerProgress (новое)
	PlayerProgress.add_xp(10)
	PlayerProgress.stats["cars_washed"] += 1
	show_floating_text("+%d$" % wash_price)
	wash_completed.emit(wash_price)

func _run_stage(icon_index: int, duration: float) -> void:
	# Подсветка активной иконки
	for i in range(ui_icons.size()):
		ui_icons[i].modulate.a = 1.0 if i == icon_index else 0.3
	
	await get_tree().create_timer(duration).timeout

func _on_car_left() -> void:
	print(" _on_car_left() вызван!")
	is_busy = false
	current_car = null
	for icon in ui_icons:
		icon.modulate.a = 0.3
	print("🏁 Мойка свободна")

# --- Система Улучшений (3 отдельные кнопки) ---

func _get_stage_name(stage: int) -> String:
	match stage:
		0: return "foam"
		1: return "water"
		2: return "dry"
		_: return "unknown"
		
func _apply_upgrade_bonus(stage: int) -> void:
	var stage_name = _get_stage_name(stage)
	
	# Пересчитываем время на основе уровней из PlayerProgress
	foam_time = max(0.5, 2.0 * pow(0.9, PlayerProgress.get_upgrade_level("foam")))
	water_time = max(0.5, 2.0 * pow(0.9, PlayerProgress.get_upgrade_level("water")))
	dry_time = max(0.5, 2.0 * pow(0.9, PlayerProgress.get_upgrade_level("dry")))
	
	# Пересчитываем цену мойки
	var total_upgrades = (PlayerProgress.get_upgrade_level("foam") + 
						  PlayerProgress.get_upgrade_level("water") + 
						  PlayerProgress.get_upgrade_level("dry"))
	wash_price = 10 + (total_upgrades * 5)
	
	# 🔥 Обновляем кнопки UI
	update_upgrade_buttons()
	
	print("⚙️ Бонусы применены! Время: пена=%.2fс, вода=%.2fс, сушка=%.2fс" % [foam_time, water_time, dry_time])
	print("💰 Новая цена мойки: %d$" % wash_price)

func upgrade_stage(stage: int) -> void:
	var cost = get_upgrade_cost(stage)
	var stage_name = _get_stage_name(stage)
	
	print("🔧 Улучшение этапа %s. Стоимость: %d" % [stage_name, cost])
	
	if PlayerProgress.upgrade_wash(stage_name, cost):
		print("✅ Улучшение куплено! Применяем бонусы...")
		
		# 🔥 Применяем бонусы и обновляем UI
		_apply_upgrade_bonus(stage)
	else:
		print("❌ Улучшение не куплено")

func get_stage_level(stage: int) -> int:
	match stage:
		0: return foam_level
		1: return water_level
		2: return dry_level
	return 0

func get_upgrade_cost(stage: int) -> int:
	# Цена растет от уровня конкретного этапа
	var stage_name = _get_stage_name(stage)
	var level = PlayerProgress.get_upgrade_level(stage_name)
	return int(upgrade_cost * pow(1.5, level))

func update_upgrade_buttons() -> void:
	for i in range(upgrade_buttons.size()):
		var btn = upgrade_buttons[i]
		var stage_name = _get_stage_name(i)
		
		# 🔥 БЕРЕМ УРОВЕНЬ ИЗ PlayerProgress, а не из локальных переменных!
		var level = PlayerProgress.get_upgrade_level(stage_name)
		var cost = get_upgrade_cost(i)
		
		btn.text = "Ур.%d\n%d$" % [level, cost]
		print("🔄 Кнопка %s обновлена: Ур.%d" % [stage_name, level])

# --- Обработчики кнопок ---

func _on_btn_upgrade_foam_pressed() -> void:
	upgrade_stage(0)

func _on_btn_upgrade_water_pressed() -> void:
	upgrade_stage(1)

func _on_btn_upgrade_dry_pressed() -> void:
	upgrade_stage(2)
	
	
func show_floating_text(text: String) -> void:
	if floating_text_scene == null:
		return
	
	var text_instance = floating_text_scene.instantiate()
	
	# Позиция: над боксом мойки (немного рандома для живости)
	var offset_x = randf_range(-20, 20)
	var offset_y = randf_range(-50, -30)
	text_instance.position = wash_box_position + Vector2(offset_x, offset_y)
	
	text_instance.setup(text, Color(0.4, 1.0, 0.4))
	
	# Добавляем в сцену (на тот же уровень, что и CarWash)
	get_parent().add_child(text_instance)
