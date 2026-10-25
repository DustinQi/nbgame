extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const PLAYER_CONTROLLER = preload("res://scripts/player/player_controller.gd")
const ARENA = preload("res://scripts/level/arena.gd")

# 验证主场景结构、清场信号只触发一次、击杀回能
func run(t) -> void:
    var packed: PackedScene = load("res://scenes/main.tscn")
    t.check(packed != null, "主场景可加载")
    if packed == null:
        return
    var main = packed.instantiate()
    t.root.add_child(main)

    # 竞技场根节点与基础结构
    t.check(main.get_script() == ARENA, "主场景根节点是竞技场")
    t.check(main.is_in_group("arena"), "主场景在竞技场组")

    var player = main.get_node_or_null("Player")
    t.check(player != null and player.get_script() == PLAYER_CONTROLLER, "主场景包含玩家")
    t.check_equal(main.get_tree().get_nodes_in_group("enemies").size(), 3, "主场景有 3 个目标")
    t.check(main.get_node_or_null("Ground") is StaticBody3D, "主场景有地面")

    # 场地环境：灯光、天空、四面墙
    t.check(main.get_node_or_null("DirectionalLight3D") is DirectionalLight3D, "场地有灯光")
    t.check(main.get_node_or_null("WorldEnvironment") is WorldEnvironment, "场地有天空环境")
    for wall_name in ["WallNorth", "WallSouth", "WallEast", "WallWest"]:
        t.check(main.get_node_or_null(wall_name) is StaticBody3D, "有墙体: " + wall_name)
        t.check(
            main.get_node_or_null(wall_name + "/CollisionShape3D") is CollisionShape3D,
            "墙体有碰撞体: " + wall_name
        )

    # 清场信号只触发一次
    var cleared := [0]
    main.cleared.connect(func(): cleared[0] += 1)
    for i in 3:
        main._on_enemy_killed()
    t.check_equal(cleared[0], 1, "清场信号只触发一次")
    main._on_enemy_killed()
    t.check_equal(cleared[0], 1, "清场后多余击杀不会重复触发")

    # 击杀回能
    t.check(player.stats.get_energy() > 0.0, "击杀后获得能量")
    main.free()
