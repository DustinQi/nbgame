class_name EnemyStats
extends RefCounted

signal health_changed(current: float, maximum: float)
signal died

var _maximum := 1.0
var _health := 1.0

func _init(maximum_health: float = 100.0) -> void:
    _maximum = maxf(maximum_health, 1.0)
    _health = _maximum

func get_health() -> float:
    return _health

func get_max_health() -> float:
    return _maximum

func is_dead() -> bool:
    return _health <= 0.0

# 扣血：死亡后忽略后续伤害
func take_damage(amount: float) -> void:
    if is_dead() or amount <= 0.0:
        return
    _health = clampf(_health - amount, 0.0, _maximum)
    health_changed.emit(_health, _maximum)
    if _health <= 0.0:
        died.emit()
