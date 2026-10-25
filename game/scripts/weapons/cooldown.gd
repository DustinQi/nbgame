class_name Cooldown
extends RefCounted

var _duration := 0.0
var _left := 0.0

func _init(duration: float) -> void:
    _duration = maxf(duration, 0.0)

# 开始冷却
func start() -> void:
    _left = _duration

# 每帧递减，最低到 0
func tick(delta: float) -> void:
    _left = maxf(_left - maxf(delta, 0.0), 0.0)

func is_ready() -> bool:
    return _left <= 0.0

func time_left() -> float:
    return _left
