extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const PLAYER_STATS = preload("res://scripts/player/player_stats.gd")
const WEAPON_MANAGER = preload("res://scripts/weapons/weapon_manager.gd")

# 验证玩家场景的节点结构和武器挂载
func run(t) -> void:
    var packed: PackedScene = load("res://scenes/player/player.tscn")
    t.check(packed != null, "玩家场景可加载")
    if packed == null:
        return
    var player = packed.instantiate()
    t.root.add_child(player)
    t.check(player is CharacterBody3D, "玩家是 CharacterBody3D")
    t.check(player.get_node_or_null("CollisionShape3D") is CollisionShape3D, "玩家有碰撞体")
    t.check(player.get_node_or_null("Head/Camera3D") is Camera3D, "有第一人称相机")
    var manager = player.get_node_or_null("Head/WeaponManager")
    t.check(manager != null and manager.get_script() == WEAPON_MANAGER, "有武器管理器")
    if manager != null:
        t.check(manager.weapon != null, "武器管理器已装备武器")
        t.check(manager.throwable_scene != null, "武器管理器已绑定投掷物场景")
    t.check_equal(player.collision_layer, 1, "玩家在玩家层")
    t.check_equal(player.collision_mask, 6, "玩家会与场景和敌人碰撞")
    t.check(player.stats != null and player.stats.get_script() == PLAYER_STATS, "玩家持有属性对象")
    t.check_equal(player.stats.get_health(), 100.0, "玩家初始血量")
    player.free()
