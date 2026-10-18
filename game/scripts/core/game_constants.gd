class_name GameConstants
extends RefCounted

# 移动与视角数值，后续玩家控制器统一从这里取
const GRAVITY := 24.0
const WALK_SPEED := 6.0
const JUMP_VELOCITY := 8.0
const MOUSE_SENSITIVITY := 0.0025

# 生命与能量数值，后续玩家属性和 HUD 统一从这里取
const MAX_HEALTH := 100.0
const MAX_ENERGY := 100.0
const ENERGY_PER_KILL := 15.0
