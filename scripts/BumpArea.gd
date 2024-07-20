class_name BumpArea
extends Area2D

signal bump(bumper)

const BUMP_HEIGHT := 8.0
const BUMP_DURATION := 0.1

var parentNode: Node

func _init() -> void:
	area_entered.connect(_on_area_entered)
	
func _ready() -> void:
	parentNode = get_parent()

func _on_area_entered(bumper: Bumper) -> void:
	print_debug("[Bumped] %s => %s" % [bumper.owner.name, owner.name])
	if parentNode.bumpable:
		bump.emit(bumper)
		# TODO: 根据Bumper和parentNode来判断是向上顶还是撞碎
		do_bump()

func do_bump() -> void:
	# 先往上顶一小段距离，然后下落回来
	var tween:= create_tween()
	var originalY := parentNode.position.y as float
	tween.tween_property(parentNode, "position:y", originalY - BUMP_HEIGHT, BUMP_DURATION)
	tween.tween_property(parentNode, "position:y", originalY, BUMP_DURATION)
	await tween.finished
