extends RigidBody3D

@export var slot_data: SlotData

@onready var box: CSGBox3D = $CsgBox3d

func _ready():
	if slot_data.item_data.name == 'Grass':
		box.material_override.albedo_texture = preload("res://inv_stuff/item_textures/Grass.png")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == get_parent().get_node('CharacterBody3d') and body.inventory_data.pick_up_slot_data(slot_data):
		queue_free()
