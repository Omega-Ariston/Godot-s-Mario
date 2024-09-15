extends VisibleOnScreenNotifier2D


func _on_screen_entered() -> void:
	# 将所有兄弟节点激活
	var brothers := get_parent().get_children()
	for brother in brothers:
		if brother.has_method("start"):
			brother.start()

func _on_screen_exited() -> void:
	queue_free()
