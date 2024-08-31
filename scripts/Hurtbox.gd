class_name Hurtbox
extends Area2D


# 被碰了
func _on_body_entered(body: Node2D) -> void:
	print_debug("%s hit %s" % [body.name, owner.name])
	if body is Player:
		# 优先处理无敌星，然后才是被踩
		if body.is_under_star:
			# 碰到无敌星了
			owner.on_charged(body)
		elif GameManager.is_stomp(body, owner):
			# 如果来自上方就自己被踩
			owner.on_stomped(body)
		elif (owner is Turtle and owner.state_machine.current_state in Turtle.SHOOTABLE_STATE) \
				or (owner is Beetle and owner.state_machine.current_state in Beetle.SHOOTABLE_STATE):
			# 壳被玩家撞跑
			owner.on_stomped(body)
		else:
			# 伤害玩家
			body.hurt(owner)
	if body is Fireball:
		owner.on_hit(body)
		body.on_hit_enemy(owner)
	if (body is Turtle and body.state_machine.current_state == Turtle.State.SHOOT) \
			or (body is Beetle and body.state_machine.current_state == Beetle.State.SHOOT):
		owner.on_charged(body)
