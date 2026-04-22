extends Node
class_name PlayerProgressManager

# --- Сигналы для UI (прогресса) ---
signal xp_changed(amount: int)
signal level_up(new_level: int)
signal upgrade_purchased(type: String, level: int)

# --- Прогресс (то, что нужно сохранять) ---
var xp: int = 0
var level: int = 1
var wash_upgrades: Dictionary = {
	"foam": 0,
	"water": 0,
	"dry": 0
}
var stats: Dictionary = {
	"cars_washed": 0,
	"total_earned": 0,
	"play_time": 0
}

# --- Таблица уровней ---
var xp_table: Array[int] = [0, 100, 250, 500, 1000, 2000, 5000, 10000, 20000, 50000]

func _ready() -> void:
	# 🔥 ПОДКЛЮЧАЕМСЯ К GameManager
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.bankruptcy_check.connect(_on_bankruptcy)
	load_progress()

# --- Методы, которые вызываются из GameManager ---
func _on_money_changed(amount: int) -> void:
	# Деньги изменились в GameManager → просто сохраняем прогресс
	# Мы не храним money у себя, мы берем его из GameManager при сохранении
	save_progress()

func _on_bankruptcy() -> void:
	# Логика при банкротстве (если нужна в прогрессе)
	print("⚠️ Банкротство зафиксировано в статистике")

# --- Методы опыта и уровней ---
func add_xp(amount: int) -> void:
	xp += amount
	xp_changed.emit(xp)
	
	while level < xp_table.size() and xp >= xp_table[level]:
		level += 1
		level_up.emit(level)
	
	save_progress()

func get_xp_progress() -> float:
	if level >= xp_table.size(): return 1.0
	var current_xp = xp_table[level - 1] if level > 1 else 0
	var next_xp = xp_table[level]
	return float(xp - current_xp) / float(next_xp - current_xp)

# --- Методы улучшений ---
func get_upgrade_level(upgrade_type: String) -> int:
	return wash_upgrades.get(upgrade_type, 0)

func upgrade_wash(upgrade_type: String, cost: int) -> bool:
	print("🔧 Попытка улучшения: тип=%s, стоимость=%d" % [upgrade_type, cost])
	print("📊 Текущий уровень %s: %d" % [upgrade_type, wash_upgrades.get(upgrade_type, 0)])
	
	if GameManager.spend_money(cost):
		wash_upgrades[upgrade_type] = wash_upgrades.get(upgrade_type, 0) + 1
		print("✅ Уровень повышен! Новый уровень %s: %d" % [upgrade_type, wash_upgrades[upgrade_type]])
		
		upgrade_purchased.emit(upgrade_type, wash_upgrades[upgrade_type])
		save_progress()
		return true
	else:
		print("❌ Недостаточно денег!")
		return false

# --- Сохранение / Загрузка ---
func save_progress() -> void:
	var save_data = {
		# 🔥 БЕРЕМ ТЕКУЩИЕ ДЕНЬГИ ИЗ GameManager
		"money": GameManager.money, 
		"xp": xp,
		"level": level,
		"wash_upgrades": wash_upgrades,
		"stats": stats
	}
	
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_progress() -> void:
	if not FileAccess.file_exists("user://savegame.save"):
		return
	
	var file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		# 🔥 ВОССТАНАВЛИВАЕМ ДЕНЬГИ В GameManager
		GameManager.money = save_data.get("money", 0)
		GameManager.money_changed.emit(GameManager.money) # Уведомляем UI
		
		xp = save_data.get("xp", 0)
		level = save_data.get("level", 1)
		wash_upgrades = save_data.get("wash_upgrades", wash_upgrades)
		stats = save_data.get("stats", stats)
