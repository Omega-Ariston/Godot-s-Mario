class_name Vine
extends Node2D

@onready var tile_map: TileMap = $TileMap
@onready var climb_area: CollisionShape2D = $Area2D/ClimbArea

const VINE_TILE_COORDS := Vector2(4,4)
const LAYER := 0
const SOURCE_ID := 3
const SINGLE_DURATION := 0.5

var curr_spawn_point := Vector2(0, 1)

# 实例化时不断上升，并且每上升一个瓦片高度就在脚下生成一个新的藤枝，上升终点为地图高度+2瓦片高度
func _ready() -> void:
	var tile_height := Variables.TILE_SIZE.y
	var loop_count := global_position.y / tile_height + 2
	for i in loop_count:
		var tween := create_tween()
		# 上升的同时拉长碰撞判定面积
		tween.set_parallel(true)
		tween.tween_property(self, "global_position:y", global_position.y - tile_height, SINGLE_DURATION)
		tween.tween_property(climb_area, "shape:size:y", climb_area.shape.get_rect().size.y + tile_height, SINGLE_DURATION)
		tween.tween_property(climb_area, "position:y", climb_area.position.y + tile_height / 2, SINGLE_DURATION)
		await tween.finished
		# 生成新藤枝
		tile_map.set_cell(LAYER, curr_spawn_point, SOURCE_ID, VINE_TILE_COORDS)
		curr_spawn_point.y += 1


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		# 让玩家进入攀爬状态，并设置正确的朝向
		body.can_climb = true
		body.climbing_vine = self
		if body.velocity.x < 0:
			body.direction = body.Direction.LEFT
		else:
			body.direction = body.Direction.RIGHT
		# 把玩家固定到攀爬点
		body.global_position.x = climb_area.global_position.x - body.direction * body.collision_shape_2d.shape.get_rect().size.x / 2
		body.velocity = Vector2.ZERO

