extends World

@onready var spawn_point_2: SpawnPoint = $SpawnPoints/SpawnPoint2


func _process(delta: float) -> void:
	super(delta)
	# 更新重生点
	if player.global_position.x > spawn_point_2.global_position.x:
		GameManager.current_spawn_point = spawn_point_2.name
