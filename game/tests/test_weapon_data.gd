extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const WEAPON_DATA = preload("res://scripts/weapons/weapon_data.gd")

# 验证武器默认值和筷子资源文件
func run(t) -> void:
    var weapon = WEAPON_DATA.new()
    t.check_equal(weapon.display_name, "筷子", "默认名称")
    t.check_equal(weapon.damage, 20.0, "默认伤害")
    t.check(weapon.throw_speed > 0.0, "投掷速度为正数")
    t.check(weapon.cooldown > 0.0, "冷却为正数")
    t.check(weapon.gravity_scale >= 0.0, "重力缩放不为负")

    var chopsticks = load("res://resources/weapons/chopsticks.tres")
    t.check(chopsticks != null, "筷子资源可加载")
    if chopsticks != null:
        t.check_equal(chopsticks.damage, 20.0, "筷子伤害")
        t.check_equal(chopsticks.throw_speed, 30.0, "筷子投掷速度")
        t.check_equal(chopsticks.cooldown, 0.35, "筷子冷却")
