class_name PlayerController
extends CharacterBody3D

# 用 preload 引用常量和输入脚本，避免依赖全局类名缓存
const GAME_CONSTANTS = preload("res://scripts/core/game_constants.gd")
const INPUT_SETUP = preload("res://scripts/core/input_setup.gd")
const PLAYER_STATS = preload("res://scripts/player/player_stats.gd")

const PITCH_MIN := -1.45
const PITCH_MAX := 1.45

@onready var camera: Camera3D = get_node_or_null("Head/Camera3D") as Camera3D

# 玩家属性对象在实例化时就创建，保证 HUD 随时能连接信号
var stats = PLAYER_STATS.new()

var _pitch := 0.0

func _ready() -> void:
    INPUT_SETUP.ensure_actions()
    # 无界面测试时不捕获鼠标
    if DisplayServer.get_name() != "headless":
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# 鼠标视角、点击重新捕获、Esc 释放
func _unhandled_input(event: InputEvent) -> void:
    # 鼠标释放状态下点击窗口，重新捕获鼠标，但这一下不触发游戏操作
    if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        get_viewport().set_input_as_handled()
        return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * GAME_CONSTANTS.MOUSE_SENSITIVITY)
        _pitch = clampf(
            _pitch - event.relative.y * GAME_CONSTANTS.MOUSE_SENSITIVITY,
            PITCH_MIN,
            PITCH_MAX
        )
        if camera != null:
            camera.rotation.x = _pitch
    elif event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# 第一人称移动与跳跃
func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= GAME_CONSTANTS.GRAVITY * delta
    if Input.is_action_just_pressed(INPUT_SETUP.ACTION_JUMP) and is_on_floor():
        velocity.y = GAME_CONSTANTS.JUMP_VELOCITY

    var input_dir := Input.get_vector(
        INPUT_SETUP.ACTION_MOVE_LEFT,
        INPUT_SETUP.ACTION_MOVE_RIGHT,
        INPUT_SETUP.ACTION_MOVE_FORWARD,
        INPUT_SETUP.ACTION_MOVE_BACK
    )
    var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
    if direction.length_squared() > 0.0:
        velocity.x = direction.x * GAME_CONSTANTS.WALK_SPEED
        velocity.z = direction.z * GAME_CONSTANTS.WALK_SPEED
    else:
        velocity.x = move_toward(velocity.x, 0.0, GAME_CONSTANTS.WALK_SPEED * 4.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, GAME_CONSTANTS.WALK_SPEED * 4.0 * delta)
    move_and_slide()
