class_name TargetDummy
extends StaticBody3D

# 用 preload 引用敌人属性脚本，避免依赖全局类名缓存
const ENEMY_STATS = preload("res://scripts/enemies/enemy_stats.gd")

signal killed

@export var max_health := 60.0

var _stats
var _mesh: MeshInstance3D
var _base_color := Color.TRANSPARENT

func _ready() -> void:
    _mesh = get_node_or_null("Mesh") as MeshInstance3D
    if _mesh != null and _mesh.material_override != null:
        _base_color = _mesh.material_override.albedo_color
        # 每个假人复制一份独立材质，避免受击变暗互相影响
        _mesh.material_override = _mesh.material_override.duplicate() as StandardMaterial3D
    _stats = ENEMY_STATS.new(max_health)
    _stats.died.connect(_on_died)
    _stats.health_changed.connect(_on_health_changed)

func take_damage(amount: float) -> void:
    if _stats != null:
        _stats.take_damage(amount)

func get_health() -> float:
    return _stats.get_health() if _stats != null else 0.0

func is_dead() -> bool:
    return _stats != null and _stats.is_dead()

# 受击后按剩余血量比例调暗材质，没有血条也能直观看到掉血
func _on_health_changed(_current: float, _maximum: float) -> void:
    if _mesh == null or _mesh.material_override == null or _base_color == Color.TRANSPARENT:
        return
    var ratio: float = _stats.get_health() / _stats.get_max_health()
    _mesh.material_override.albedo_color = _base_color.darkened(1.0 - ratio)

func _on_died() -> void:
    killed.emit()
    queue_free()
