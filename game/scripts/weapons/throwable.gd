class_name Throwable
extends RigidBody3D

@export var lifetime := 6.0

# 本次投掷使用的武器数据（无类型标注，headless 下无法解析 class_name）
var data
var _hit_done := false

func _ready() -> void:
    contact_monitor = true
    max_contacts_reported = 2
    body_entered.connect(_on_body_entered)
    # 超时自动回收，防止场景里堆积垃圾
    get_tree().create_timer(lifetime).timeout.connect(queue_free)

# 发射：设置速度、重力缩放和外观颜色
func launch(direction: Vector3, weapon_data) -> void:
    data = weapon_data
    gravity_scale = weapon_data.gravity_scale
    linear_velocity = direction.normalized() * weapon_data.throw_speed
    _apply_color(weapon_data.color)

func _apply_color(color: Color) -> void:
    var mesh := get_node_or_null("Mesh") as MeshInstance3D
    if mesh == null:
        return
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    mesh.material_override = material

# 命中：只对带 take_damage 的节点结算一次
func _on_body_entered(body: Node) -> void:
    if _hit_done or data == null:
        return
    if body.has_method("take_damage"):
        _hit_done = true
        body.take_damage(data.damage)
