extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const COOLDOWN = preload("res://scripts/weapons/cooldown.gd")

# 验证冷却计时器的边界行为
func run(t) -> void:
    var cd = COOLDOWN.new(0.5)
    t.check(cd.is_ready(), "初始可用")
    cd.start()
    t.check(not cd.is_ready(), "启动后不可用")
    cd.tick(0.25)
    t.check(not cd.is_ready(), "时间未到仍不可用")
    cd.tick(0.25)
    t.check(cd.is_ready(), "时间到后恢复可用")
    t.check_equal(cd.time_left(), 0.0, "剩余时间归零")
    cd.start()
    cd.tick(10.0)
    t.check_equal(cd.time_left(), 0.0, "超时不会变成负数")
