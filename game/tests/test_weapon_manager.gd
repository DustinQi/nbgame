extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const WEAPON_MANAGER = preload("res://scripts/weapons/weapon_manager.gd")
const INPUT_SETUP = preload("res://scripts/core/input_setup.gd")

# 验证装备检查和冷却阻断
func run(t) -> void:
    INPUT_SETUP.ensure_actions()
    var manager = WEAPON_MANAGER.new()
    t.check(not manager.can_throw(), "没有武器时不能投掷")

    manager.weapon = load("res://resources/weapons/chopsticks.tres")
    t.check(not manager.can_throw(), "没有投掷物场景时不能投掷")

    manager.throwable_scene = load("res://scenes/weapons/throwable.tscn")
    t.check(manager.can_throw(), "装备齐全且冷却结束时可以投掷")

    manager._get_cooldown().start()
    t.check(not manager.can_throw(), "冷却中不能投掷")

    manager._get_cooldown().tick(999.0)
    t.check(manager.can_throw(), "冷却结束后恢复投掷")
    manager.free()
