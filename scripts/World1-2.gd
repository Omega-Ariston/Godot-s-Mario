extends World

@onready var removes: Node2D = $Enemies/Removes
@onready var spawn_point_2: SpawnPoint = $SpawnPoints/SpawnPoint2

func _physics_process(_delta: float) -> void:
	# 更新重生点
	if player.global_position.x > spawn_point_2.global_position.x:
		GameManager.current_spawn_point = spawn_point_2.name
		
func _ready() -> void:
	super()
	if GameManager.current_spawn_point == spawn_point_2.name:
		# 移除出生点附近的敌人
		removes.queue_free()
