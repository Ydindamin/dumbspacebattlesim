extends Area3D

func _on_lifetimer_timeout():
	queue_free()
