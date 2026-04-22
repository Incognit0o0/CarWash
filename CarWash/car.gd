extends Node2D

signal arrived_at_box
signal finished_and_leaving

@export var speed: float = 200.0
@export var box_progress: float = 0.5  # Где находится мойка

var path_follow: PathFollow2D = null
var is_moving: bool = false
var current_progress: float = 0.0
var waiting_for_wash: bool = false
var has_stopped_at_box: bool = false  # 🔴 Новый флаг для отладки

func drive_along_path(path_node: PathFollow2D) -> void:
	print("🚗 drive_along_path вызван!")
	path_follow = path_node
	is_moving = true
	current_progress = 0.0
	waiting_for_wash = false
	has_stopped_at_box = false  #  Сбрасываем флаг при спавне

func _process(delta: float) -> void:
	if waiting_for_wash:
		return
	
	if not is_moving or not path_follow:
		return
	
	var path_node: Path2D = path_follow.get_parent()
	var path_length = path_node.curve.get_baked_length()
	var step = (speed * delta) / path_length
	
	current_progress += step
	
	# 🔴 ПРОВЕРКА: Доехали до мойки?
	if current_progress >= box_progress and not has_stopped_at_box:
		current_progress = box_progress
		path_follow.progress_ratio = current_progress
		is_moving = false
		waiting_for_wash = true
		has_stopped_at_box = true
		print("🛑 Машина остановилась на мойке! Прогресс: ", current_progress)
		arrived_at_box.emit()
		return
	
	# 🔴 ПРОВЕРКА: Доехали до конца пути?
	if current_progress >= 1.0:
		current_progress = 1.0
		is_moving = false
		path_follow.progress_ratio = current_progress
		print("🏁 Прогресс 1.0, is_moving = false")
		finished_and_leaving.emit()  # ← 🔥 ДОБАВИТЬ ЭТУ СТРОКУ!
		return
	
	path_follow.progress_ratio = current_progress
	
	
func resume() -> void:
	print("▶️ Машина продолжает движение")
	waiting_for_wash = false
	is_moving = true

func leave() -> void:
	print("🚗 leave() вызван")
	if waiting_for_wash:
		resume()
	
	while is_moving:
		await get_tree().process_frame
	
	print("✅ Машина уехала, отправляем сигнал")
	finished_and_leaving.emit()
	queue_free()
