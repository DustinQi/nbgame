class_name WeaponManager
extends Node3D

# 用 preload 引用其他脚本，避免依赖全局类名缓存
const COOLDOWN = preload("res://scripts/weapons/cooldown.gd")
const INPUT_SETUP = preload("res://scripts/core/input_setup.gd")

# 信号参数无类型标注（headless 下无法解析自定义 class_name）
signal threw(weapon)
signal cooldown_changed(remaining: float, duration: float)

@export var weapon: Resource
@export var throwable_scene: PackedScene

var _cooldown

func _ready() -> void:
    INPUT_SETUP.ensure_actions()

func _process(delta: float) -> void:
    if _cooldown == null or _cooldown.is_ready():
        return
    _cooldown.tick(delta)
    cooldown_changed.emit(_cooldown.time_left(), _cooldown_duration())

func _unhandled_input(event: InputEvent) -> void:
    # 鼠标没被捕获时（例如按了 Esc），点击不投掷
    if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        return
    if event.is_action_pressed(INPUT_SETUP.ACTION_THROW):
        try_throw()

func can_throw() -> bool:
    return weapon != null and throwable_scene != null and _get_cooldown().is_ready()

# 真正执行投掷：从相机中心朝前飞出
func try_throw() -> bool:
    if not can_throw():
        return false
    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return false
    var projectile = throwable_scene.instantiate()
    if projectile == null:
        return false
    var forward := -camera.global_transform.basis.z
    get_tree().current_scene.add_child(projectile)
    projectile.global_position = camera.global_position + forward * 0.6
    projectile.launch(forward, weapon)
    _get_cooldown().start()
    threw.emit(weapon)
    return true

# 延迟创建冷却计时器，方便测试时无需进入场景树
func _get_cooldown():
    if _cooldown == null:
        _cooldown = COOLDOWN.new(_cooldown_duration())
    return _cooldown

func _cooldown_duration() -> float:
    return weapon.cooldown if weapon != null else 0.0
