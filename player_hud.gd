extends CanvasLayer

@export var money_label: Label
@export var level_label: Label
@export var xp_bar: ProgressBar

func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	PlayerProgress.xp_changed.connect(_on_xp_changed)
	PlayerProgress.level_up.connect(_on_level_up)
	
	_on_money_changed(GameManager.money)
	_on_xp_changed(PlayerProgress.xp)
	_on_level_up(PlayerProgress.level)

func _on_money_changed(amount: int) -> void:
	money_label.text = "$%d" % amount

func _on_xp_changed(amount: int) -> void:
	xp_bar.value = PlayerProgress.get_xp_progress() * 100

func _on_level_up(new_level: int) -> void:
	level_label.text = "Ур. %d" % new_level
	# Можно добавить анимацию или эффект
