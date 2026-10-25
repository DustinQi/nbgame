extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const PLAYER_STATS = preload("res://scripts/player/player_stats.gd")

# 验证玩家生命、治疗、能量和死亡信号
func run(t) -> void:
    var stats = PLAYER_STATS.new()
    t.check_equal(stats.get_health(), 100.0, "初始血量")
    t.check_equal(stats.get_energy(), 0.0, "初始能量")
    t.check(not stats.is_dead(), "初始未死亡")

    stats.take_damage(30.0)
    t.check_equal(stats.get_health(), 70.0, "受伤后血量")

    var death_count := [0]
    stats.died.connect(func(): death_count[0] += 1)
    stats.take_damage(999.0)
    t.check_equal(stats.get_health(), 0.0, "血量不会小于 0")
    t.check(stats.is_dead(), "血量归零后死亡")
    t.check_equal(death_count[0], 1, "死亡信号触发一次")
    stats.take_damage(10.0)
    t.check_equal(death_count[0], 1, "死亡后不再重复触发")

    var healed = PLAYER_STATS.new()
    healed.take_damage(30.0)
    healed.heal(50.0)
    t.check_equal(healed.get_health(), 100.0, "治疗恢复且不超过上限")

    t.check(not healed.spend_energy(10.0), "能量不足时不能消耗")
    healed.add_energy(30.0)
    t.check_equal(healed.get_energy(), 30.0, "获得能量")
    t.check(healed.spend_energy(20.0), "能量足够时可以消耗")
    t.check_equal(healed.get_energy(), 10.0, "消耗后剩余能量")
    healed.add_energy(999.0)
    t.check_equal(healed.get_energy(), 100.0, "能量不超过上限")
