class_name PlayerStats
extends RefCounted

# 用 preload 引用常量脚本，避免依赖全局类名缓存
const GAME_CONSTANTS = preload("res://scripts/core/game_constants.gd")

signal health_changed(current: float, maximum: float)
signal energy_changed(current: float, maximum: float)
signal died

var _health := GAME_CONSTANTS.MAX_HEALTH
var _energy := 0.0

func get_health() -> float:
    return _health

func get_energy() -> float:
    return _energy

func is_dead() -> bool:
    return _health <= 0.0

# 扣血：死亡后不再响应，避免重复触发死亡信号
func take_damage(amount: float) -> void:
    if is_dead() or amount <= 0.0:
        return
    _health = clampf(_health - amount, 0.0, GAME_CONSTANTS.MAX_HEALTH)
    health_changed.emit(_health, GAME_CONSTANTS.MAX_HEALTH)
    if _health <= 0.0:
        died.emit()

# 治疗：死亡状态不可治疗（本作没有复活）
func heal(amount: float) -> void:
    if is_dead() or amount <= 0.0:
        return
    _health = clampf(_health + amount, 0.0, GAME_CONSTANTS.MAX_HEALTH)
    health_changed.emit(_health, GAME_CONSTANTS.MAX_HEALTH)

func add_energy(amount: float) -> void:
    if amount <= 0.0:
        return
    _energy = clampf(_energy + amount, 0.0, GAME_CONSTANTS.MAX_ENERGY)
    energy_changed.emit(_energy, GAME_CONSTANTS.MAX_ENERGY)

# 消耗能量：足够则扣除并返回 true
func spend_energy(amount: float) -> bool:
    if amount <= 0.0:
        return true
    if _energy < amount:
        return false
    _energy -= amount
    energy_changed.emit(_energy, GAME_CONSTANTS.MAX_ENERGY)
    return true
