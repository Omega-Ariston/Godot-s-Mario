class_name Hurtbox
extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# 优先处理无敌星，然后才是被踩
		if body.is_under_star:
			# 碰到无敌星了
			owner.on_charged()
		elif (body.state_machine.current_state == body.State.FALL or body.velocity.y > 0) and body.global_position.y < global_position.y:
			# 如果来自上方就自己被踩
			owner.on_stomped(body)
		else:
			# 否则要伤害玩家
			body.hurt(owner)
	if body is Fireball:
		owner.hit_direction = Enemy.Direction.LEFT if body.global_position.x > global_position.x else Enemy.Direction.RIGHT
		owner.on_hit()
		body.on_hit_enemy(owner)
