extends RefCounted

# 验证最小场地结构：玩家、地面、四面墙、灯光、天空
func run(t) -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    t.check(packed != null, "主场景可加载")
    if packed == null:
        return
    var main = packed.instantiate()
    t.root.add_child(main)

    var player := main.get_node_or_null("Player")
    t.check(player is CharacterBody3D, "场地里有玩家")
    if player != null:
        t.check(player.position.y > 0.0, "玩家出生点在地面之上")

    t.check(main.get_node_or_null("Ground") is StaticBody3D, "场地有地面")
    t.check(main.get_node_or_null("Ground/CollisionShape3D") is CollisionShape3D, "地面有碰撞体")
    t.check(main.get_node_or_null("DirectionalLight3D") is DirectionalLight3D, "场地有灯光")
    t.check(main.get_node_or_null("WorldEnvironment") is WorldEnvironment, "场地有天空环境")

    for wall_name in ["WallNorth", "WallSouth", "WallEast", "WallWest"]:
        t.check(main.get_node_or_null(wall_name) is StaticBody3D, "有墙体: " + wall_name)
        t.check(
            main.get_node_or_null(wall_name + "/CollisionShape3D") is CollisionShape3D,
            "墙体有碰撞体: " + wall_name
        )

    main.free()
