extends RefCounted

# 验证玩家场景的节点结构和碰撞设置
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
    t.check_equal(player.collision_layer, 1, "玩家在玩家层")
    t.check_equal(player.collision_mask, 2, "玩家会与场景碰撞")
    player.free()
