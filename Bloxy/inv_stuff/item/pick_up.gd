extends RigidBody3D

#they still fall through the floor, even when being forced to the floor by player -_-
#change mass based on block type (not yet, leave this here... forever...)
@export var slot_data: SlotData

@onready var box: CSGBox3D = $CsgBox3d
@onready var WaterBucketModel = preload("res://inv_stuff/WaterBucketModel.tscn")

var collectable = false

func _ready():
	slot_data.resource_local_to_scene = true
	box.material_override.resource_local_to_scene = true
	print(slot_data.item_data.name)
	if slot_data.item_data.name == 'Dirt':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Dirt.png")
	if slot_data.item_data.name == 'Grass':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Grass.png")
	if slot_data.item_data.name == 'Oak Leaves':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Oak Leaves.png")
	if slot_data.item_data.name == 'Oak Log':
		$Top.show()
		$Bottom.show()
		$Left.show()
		$Right.show()
		$Top.mesh.material.albedo_texture = preload("res://inv_stuff/item/items/item_images/Oak Trunk (top).png")
		$Bottom.mesh.material.albedo_texture = preload("res://inv_stuff/item/items/item_images/Oak Trunk (top).png")
		$Left.mesh.material.albedo_texture = preload("res://inv_stuff/item/items/item_images/Oak Trunk (side).png")
		$Right.mesh.material.albedo_texture = preload("res://inv_stuff/item/items/item_images/Oak Trunk (side).png")
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Oak Trunk (side).png")
	if slot_data.item_data.name == 'Raw Coal':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Raw Coal.png")
	if slot_data.item_data.name == 'Raw Gold':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Raw Gold.png")
	if slot_data.item_data.name == 'Raw Iron':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Raw Iron.png")
	if slot_data.item_data.name == 'Sand':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Sand.png")
	if slot_data.item_data.name == 'Stone Pail':
		box.hide()
		var instance = WaterBucketModel.instantiate()
		if slot_data.item_data.amount_left == 0:
			instance.find_child('water').hide()
		add_child(instance)
	if slot_data.item_data.name == 'Stone':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Stone.png")
	if slot_data.item_data.name == 'Wooden Crate':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Wooden Crate.png")
	await get_tree().create_timer(0.4).timeout
	freeze = false

func _physics_process(delta):
	#add a press key to pick up UI if I need it
	if collectable and get_parent().get_node('CharacterBody3d').inventory_data.pick_up_slot_data(slot_data):
		if Input.is_action_pressed('PickUpItem'):
			queue_free()

func _on_area_3d_body_entered(body):
	if body == get_parent().get_node('CharacterBody3d'):
		collectable = true

func _on_area_3d_body_exited(body):
	if body == get_parent().get_node('CharacterBody3d'):
		collectable = false
