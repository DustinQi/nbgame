extends RefCounted

# 用 preload 引用被测脚本，避免依赖全局类名缓存
const GAME_CONSTANTS = preload("res://scripts/core/game_constants.gd")

# 验证移动、视角、生命与能量常量的精确数值
func run(t) -> void:
    # 移动与视角
    t.check_equal(GAME_CONSTANTS.GRAVITY, 24.0, "重力为 24")
    t.check_equal(GAME_CONSTANTS.WALK_SPEED, 6.0, "移动速度为 6")
    t.check_equal(GAME_CONSTANTS.JUMP_VELOCITY, 8.0, "跳跃初速度为 8")
    t.check_equal(GAME_CONSTANTS.MOUSE_SENSITIVITY, 0.0025, "鼠标灵敏度为 0.0025")
    # 生命与能量
    t.check_equal(GAME_CONSTANTS.MAX_HEALTH, 100.0, "生命上限为 100")
    t.check_equal(GAME_CONSTANTS.MAX_ENERGY, 100.0, "能量上限为 100")
    t.check_equal(GAME_CONSTANTS.ENERGY_PER_KILL, 15.0, "每次击杀回复 15 能量")
