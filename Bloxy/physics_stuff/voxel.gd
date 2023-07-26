extends CollisionShape3D

#diffrent voxels are heavier
#side panels arent working correctly

var voxel = ''

@onready var player = find_parent('Node3d').get_node('CharacterBody3d')
@onready var box: CSGBox3D = $CsgBox3d

func _ready():
	if voxel == 'Dirt':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Dirt.png")
	if voxel == 'Grass':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Grass.png")
	if voxel == 'Oak Leaves':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Oak Leaves.png")
	if voxel == 'Oak Log':
		$Top.show()
		$Bottom.show()
		$Left.show()
		$Right.show()
		$Top.mesh.material.albedo_texture = preload("res://inv_stuff/item/items/item_images/Oak Trunk (top).png")
		$Bottom.mesh.material.albedo_texture = preload("res://inv_stuff/item/items/item_images/Oak Trunk (top).png")
		$Left.mesh.material.albedo_texture = preload("res://inv_stuff/item/items/item_images/Oak Trunk (side).png")
		$Right.mesh.material.albedo_texture = preload("res://inv_stuff/item/items/item_images/Oak Trunk (side).png")
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Oak Trunk (side).png")
	if voxel == 'Raw Coal':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Raw Coal.png")
	if voxel == 'Raw Gold':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Raw Gold.png")
	if voxel == 'Raw Iron':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Raw Iron.png")
	if voxel == 'Sand':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Sand.png")
	if voxel == 'Water':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Stone Pail.png")
		#GET WATER IMAGE!!!
	if voxel == 'Stone':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Stone.png")
	if voxel == 'Wooden Chest':
		box.material_override.albedo_texture = preload("res://inv_stuff/item/items/item_images/Wooden Crate.png")

func _on_area_3d_area_entered(area):
	if area == player.get_node('Interact/Area3d') and Input.is_action_pressed("Mine"):
		print('found!')
		find_parent('Node3d').create_item(player.ID_TO_NAME.find(voxel), global_position, global_rotation)
		queue_free()
