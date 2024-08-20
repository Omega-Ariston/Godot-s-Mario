class_name Vine
extends Node2D

@onready var tile_map: TileMapLayer = $TileMap
@onready var climable: Climable = $Climable
@onready var climb_area: CollisionShape2D = $Climable/ClimbArea

const VINE_TILE_COORDS := Vector2(4,4)
const SOURCE_ID := 3
const SINGLE_DURATION := 0.5

# 颜色顺序为叶片、叶茎
const COLOR_ORIGIN := [
	Vector4(0.06, 0.65, 0.0, 1.0),
	Vector4(0.84, 0.60, 0.11, 1.0)
]
const COLOR_CYAN := [
	Vector4(0.0, 0.48, 0.54, 1.0),
	Vector4(0.47, 0.24, 0.09, 1.0)
]

var curr_spawn_point := Vector2(0, 1)
var rise_count: int # 在过场动画中会被手动指定，其余情况根据开始生长的高度来确定

signal rise_completed

# 实例化时不断上升，并且每上升一个瓦片高度就在脚下生成一个新的藤枝，没指定终点时上升终点为地图高度+2瓦片高度
func _ready() -> void:
	var sprite_material := tile_map.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
	if GameManager.current_world_type == World.Type.UNDER:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_CYAN.duplicate())
		
	var tile_height := Variables.TILE_SIZE.y
	if not rise_count:
		rise_count = ceili(global_position.y / tile_height + 2)
	for i in rise_count:
		var tween := create_tween()
		# 上升的同时拉长碰撞判定面积
		tween.set_parallel(true)
		tween.tween_property(self, "global_position:y", global_position.y - tile_height, SINGLE_DURATION)
		tween.tween_property(climb_area, "shape:size:y", climb_area.shape.get_rect().size.y + tile_height, SINGLE_DURATION)
		tween.tween_property(climb_area, "position:y", climb_area.position.y + tile_height / 2, SINGLE_DURATION)
		await tween.finished
		# 生成新藤枝
		tile_map.set_cell(curr_spawn_point, SOURCE_ID, VINE_TILE_COORDS)
		curr_spawn_point.y += 1
	rise_completed.emit()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player and not body.collision_shape_2d.disabled:
		# 让玩家下去
		body._unclimb()
