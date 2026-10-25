class_name Arena
extends Node3D

# 用 preload 引用常量脚本，避免依赖全局类名缓存
const GAME_CONSTANTS = preload("res://scripts/core/game_constants.gd")

signal enemies_remaining_changed(remaining: int)
signal cleared

var _remaining := 0
var _player

func _ready() -> void:
    _player = get_tree().get_first_node_in_group("player")
    var enemies := get_tree().get_nodes_in_group("enemies")
    _remaining = enemies.size()
    for enemy in enemies:
        if enemy.has_signal("killed"):
            enemy.killed.connect(_on_enemy_killed)
    # 延迟一帧发送初始数量，确保 HUD 已经连接好信号
    call_deferred("_emit_initial_remaining")

func _emit_initial_remaining() -> void:
    enemies_remaining_changed.emit(_remaining)

# 每死亡一个目标：回能、更新剩余数、清场时发信号
func _on_enemy_killed() -> void:
    if _remaining <= 0:
        return
    _remaining -= 1
    if _player != null:
        _player.stats.add_energy(GAME_CONSTANTS.ENERGY_PER_KILL)
    enemies_remaining_changed.emit(_remaining)
    if _remaining == 0:
        cleared.emit()
