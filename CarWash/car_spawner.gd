extends Node
class_name CarSpawner

@export var spawn_interval: float = 5.0
@export var car_wash: CarWash

var timer: float = 0.0

func _ready() -> void:
	print("📡 CarSpawner готов. CarWash: ", car_wash)

func _process(delta: float) -> void:
	if not car_wash:
		return
	
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0

		try_spawn_car()

func try_spawn_car() -> void:
	if not car_wash.is_busy:
		print("🚀 Вызов spawn_car()")
		car_wash.spawn_car()
