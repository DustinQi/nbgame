extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const ENEMY_STATS = preload("res://scripts/enemies/enemy_stats.gd")

# 验证敌人血量、死亡信号和重复受击
func run(t) -> void:
    var enemy = ENEMY_STATS.new(60.0)
    t.check_equal(enemy.get_health(), 60.0, "初始血量")
    t.check_equal(enemy.get_max_health(), 60.0, "最大血量")

    var death_count := [0]
    enemy.died.connect(func(): death_count[0] += 1)

    enemy.take_damage(20.0)
    t.check_equal(enemy.get_health(), 40.0, "受伤后血量")
    t.check_equal(death_count[0], 0, "未死亡不触发信号")

    enemy.take_damage(999.0)
    t.check_equal(enemy.get_health(), 0.0, "血量下限为 0")
    t.check(enemy.is_dead(), "死亡状态正确")
    t.check_equal(death_count[0], 1, "死亡信号触发一次")

    enemy.take_damage(10.0)
    t.check_equal(death_count[0], 1, "死亡后不再触发")
