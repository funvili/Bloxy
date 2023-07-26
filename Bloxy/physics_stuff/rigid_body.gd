extends RigidBody3D

#place blocks on these?
#interact with blocks on these

func _ready():
	mass = get_child_count() * 10

func _process(delta):
	if get_child_count() == 1:
		await get_tree().create_timer(0.1).timeout
		if get_child_count() == 1:
			queue_free()
