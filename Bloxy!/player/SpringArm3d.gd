extends SpringArm3D

@export var sensitivity = 0.01
var speed = 0.2
var zoom = 7

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if Input.get_action_strength("Camera"):
			rotation.x -= event.relative.y * sensitivity
			rotation.x = clamp(rotation.x, -90.0, 30.0)
			
			rotation.y -= event.relative.x * sensitivity
			rotation.y = wrapf(rotation.y, 0.0, 360.0)

	if event.is_pressed():
		if Input.get_action_strength("ZoomIn"):
			if zoom > -1:
				zoom = zoom - speed
		if Input.get_action_strength("ZoomOut"):
			if zoom < 20:
				zoom = zoom + speed
		spring_length = zoom

func _on_inventory_interface_gui_input(event):
	if event is InputEventMouseMotion:
		if Input.get_action_strength("Camera"):
			rotation.x -= event.relative.y * sensitivity
			rotation.x = clamp(rotation.x, -90.0, 30.0)
			
			rotation.y -= event.relative.x * sensitivity
			rotation.y = wrapf(rotation.y, 0.0, 360.0)

	if event.is_pressed():
		if Input.get_action_strength("ZoomIn"):
			if zoom > -1:
				zoom = zoom - speed
		if Input.get_action_strength("ZoomOut"):
			if zoom < 20:
				zoom = zoom + speed
		spring_length = zoom
