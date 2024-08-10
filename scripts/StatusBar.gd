extends CanvasLayer

@export var time: int = -1: # 8-1和8-3只有300秒，其余关是400秒，切屏界面不显示时间，用-1表示
	set(v):
		if not is_node_ready():
			await ready
		time = v
		time_label.text = 'Time\n' + (str(time) if time != -1 else '')
		
@export var world: int = 1: # 世界编号
	set(v):
		if not is_node_ready():
			await ready
		world = v
		level_label.text = '[center]WORLD\n' + str(world) + '-' + str(level) + '[/center]'
		
@export var level: int = 1: # 关卡编号
	set(v):
		if not is_node_ready():
			await ready
		level = v
		level_label.text = '[center]WORLD\n' + str(world) + '-' + str(level) + '[/center]'

var score := 0:
	set(v):
		if not is_node_ready():
			await ready
		score = v
		score_label.text = 'MARIO\n' + ("%06d" % score)
		
var coin := 0:
	set(v):
		if not is_node_ready():
			await ready
		coin = v
		coin_label.text = ("%02d" % coin)

@onready var score_label: RichTextLabel = $Score
@onready var time_label: RichTextLabel = $Time
@onready var level_label: RichTextLabel = $Level
@onready var coin_label: RichTextLabel = $Coin

