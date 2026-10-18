extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const GAME_CONSTANTS = preload("res://scripts/core/game_constants.gd")

# 验证移动与视角常量的精确数值
func run(t) -> void:
    t.check_equal(GAME_CONSTANTS.GRAVITY, 24.0, "重力为 24")
    t.check_equal(GAME_CONSTANTS.WALK_SPEED, 6.0, "移动速度为 6")
    t.check_equal(GAME_CONSTANTS.JUMP_VELOCITY, 8.0, "跳跃初速度为 8")
    t.check_equal(GAME_CONSTANTS.MOUSE_SENSITIVITY, 0.0025, "鼠标灵敏度为 0.0025")
