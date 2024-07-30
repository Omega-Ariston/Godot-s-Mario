class_name Vine
extends Node2D

@onready var tile_map: TileMap = $TileMap

const VINE_TILE_COORDS := Vector2(4,4)
const LAYER := 0
const SOURCE_ID := 3
const SINGLE_DURATION := 0.5

var curr_spawn_point := Vector2(0, 1)

# 实例化时不断上升，并且每上升一个瓦片高度就在脚下生成一个新的藤枝，上升终点为地图高度+1瓦片高度
func _ready() -> void:
	var loop_count := global_position.y / Variables.TILE_SIZE.y + 1
	for i in loop_count:
		var tween := create_tween()
		tween.tween_property(self, "global_position:y", global_position.y - Variables.TILE_SIZE.y, SINGLE_DURATION)
		await tween.finished
		tile_map.set_cell(LAYER, curr_spawn_point, SOURCE_ID, VINE_TILE_COORDS)
		curr_spawn_point.y += 1
