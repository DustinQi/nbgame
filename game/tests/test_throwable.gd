extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const WEAPON_DATA = preload("res://scripts/weapons/weapon_data.gd")
const THROWABLE = preload("res://scripts/weapons/throwable.gd")

# 模拟一个可受伤目标，用于验证命中逻辑
class DummyTarget extends Node:
    var damage_taken := 0.0

    func take_damage(amount: float) -> void:
        damage_taken += amount

# 验证投掷速度、方向和命中只结算一次
func run(t) -> void:
    var weapon = WEAPON_DATA.new()
    weapon.throw_speed = 20.0
    weapon.damage = 15.0
    weapon.gravity_scale = 0.5

    var projectile = THROWABLE.new()
    projectile.launch(Vector3.FORWARD, weapon)
    t.check_equal(projectile.linear_velocity.length(), 20.0, "投掷速度")
    t.check(projectile.linear_velocity.z < 0.0, "朝前方飞出")
    t.check_equal(projectile.gravity_scale, 0.5, "重力缩放生效")

    var target := DummyTarget.new()
    projectile._on_body_entered(target)
    t.check_equal(target.damage_taken, 15.0, "命中造成武器伤害")
    projectile._on_body_entered(target)
    t.check_equal(target.damage_taken, 15.0, "同一次投掷只造成一次伤害")

    projectile.free()
    target.free()

    var packed: PackedScene = load("res://scenes/weapons/throwable.tscn")
    t.check(packed != null, "投掷物场景可加载")
    if packed == null:
        return
    var scene_projectile = packed.instantiate()
    # preload 常量不能用于 is 类型检查，改为比对脚本身份
    t.check(scene_projectile != null and scene_projectile.get_script() == THROWABLE, "投掷物场景脚本正确")
    t.check_equal(scene_projectile.collision_mask & 1, 0, "碰撞遮罩不含玩家层")
    t.check((scene_projectile.collision_mask & 2) != 0, "碰撞遮罩含场景层")
    t.check((scene_projectile.collision_mask & 4) != 0, "碰撞遮罩含敌人层")
    scene_projectile.free()
