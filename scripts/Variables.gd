extends Node

const TILE_SIZE := Vector2(16, 16)

var DEFAULT_GRAVITY := ProjectSettings.get_setting("physics/2d/default_gravity") as float
# const DEFAULT_GRAVITY := 562.5 # 00280

const WATER_SURFACE_Y_OFFSET := floori(TILE_SIZE.y * 5)

const BOTTOM_BOUNDARY := ceili(15.5 * TILE_SIZE.y)
const TOP_BOUNDARY := floori(1.5 * TILE_SIZE.y)
