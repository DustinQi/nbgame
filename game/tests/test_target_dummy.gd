extends RefCounted

# 验证假人场景加载、受伤、受击变暗和死亡移除
func run(t) -> void:
    var packed: PackedScene = load("res://scenes/enemies/target_dummy.tscn")
    t.check(packed != null, "假人场景可加载")
    if packed == null:
        return
    var dummy = packed.instantiate()
    t.root.add_child(dummy)
    var killed := [0]
    dummy.killed.connect(func(): killed[0] += 1)

    # 记录受击前的材质颜色，用于验证变暗反馈
    var mesh = dummy.get_node("Mesh") as MeshInstance3D
    var material = mesh.material_override as StandardMaterial3D
    var base_color: Color = material.albedo_color

    # 另一个假人，验证材质互不影响
    var dummy2 = packed.instantiate()
    t.root.add_child(dummy2)
    var material2 = (dummy2.get_node("Mesh") as MeshInstance3D).material_override as StandardMaterial3D
    var base_color2: Color = material2.albedo_color

    t.check(not dummy.is_dead(), "初始存活")
    dummy.take_damage(20.0)
    t.check_equal(dummy.get_health(), 40.0, "受伤后剩余血量")
    t.check_equal(killed[0], 0, "未死亡不触发信号")
    t.check(material.albedo_color.r < base_color.r, "受击后材质变暗")
    t.check(material2.albedo_color == base_color2, "假人之间材质互不影响")

    dummy.take_damage(999.0)
    t.check(dummy.is_dead(), "血量归零后死亡")
    t.check_equal(killed[0], 1, "死亡信号触发一次")
    t.check(dummy.is_queued_for_deletion(), "死亡后自动移除")
    dummy2.free()
