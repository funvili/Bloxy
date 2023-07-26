extends RigidBody3D

#load all chunks first
#change interact size for larger placements, like beds
#spam mining/building

var SPEED = 10
var JUMP_VELOCITY = 10

@onready var spring_arm = $SpringArm3d
@onready var model  = $CsgBox3d
@onready var cam = $SpringArm3d/Camera3d
@onready var interact = $Interact
@onready var hot_bat_inv = $"../UI/HotBatInv"

@onready var terrain = get_parent().get_node('VoxelTerrain')
@onready var vt: VoxelToolTerrain = get_parent().get_node('VoxelTerrain').get_voxel_tool()

@onready var chest = preload("res://chest.tscn")
@onready var inventory = preload('res://inv_stuff/inventory/Inventory.tscn')

@export var inventory_data: InventoryData
@export var equip_inventory_data: InventoryDataEquip

signal toggle_inv()

var mouse_on_UI = false
var minebuild = 'mine'

var rot_speed = 5
var health = 10

const ID_TO_NAME = ['Air', 'Grass', 'Dirt', 'Stone', 'Sand', 'Stone Pail', 'Oak Log', 'Oak Leaves', 'Raw Coal', 'Raw Iron', 'Raw Gold', 'Wooden Crate']

func _ready():
	PlayerManager.player = self

func _physics_process(delta):
	if submerged():
		gravity_scale = 0.25
		SPEED = 5
		JUMP_VELOCITY = 5
	else:
		gravity_scale = 1
		SPEED = 10
		JUMP_VELOCITY = 10
	
	if minebuild == 'mine':
		if raycast():
			interact.global_position = Vector3(raycast().x + 0.5, raycast().y + 0.5, raycast().z + 0.5)
	elif minebuild == 'build':
		if raycast():
			interact.global_position = Vector3(raycast().x + 0.5, raycast().y + 0.5, raycast().z + 0.5)
	
	$ToInteract.target_position = interact.position
	
	var Landing = $Land.get_overlapping_bodies().size() > 1
	if Input.is_action_just_pressed("Jump") and Landing:
		linear_velocity.y = JUMP_VELOCITY
	
	var input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, spring_arm.rotation.y).normalized()
	
	if direction:
		linear_velocity.x = direction.x * SPEED
		linear_velocity.z = direction.z * SPEED
	else:
		linear_velocity.x = move_toward(linear_velocity.x, 0, SPEED)
		linear_velocity.z = move_toward(linear_velocity.z, 0, SPEED)
		
	if Vector2(linear_velocity.z, linear_velocity.x).length() > 0.2:
		var look_direction = Vector2(linear_velocity.z, linear_velocity.x)
		model.rotation.y = lerp_angle(model.rotation.y, look_direction.angle(), delta * rot_speed)
	
	if Input.is_action_just_pressed("Mine") and raycast() != null and mouse_on_UI != true:
		if minebuild == 'mine':
			if not inventory_data.slot_datas[hot_bat_inv.selected_slot - 1]: #contradictary to pickaxes, but is only for buckets
				vt.mode = VoxelTool.MODE_REMOVE
				var raycast = raycast()
				var id = vt.get_voxel(raycast)
				
				if id != 0 and id != 5:
					print('mine')
					vt.do_point(raycast)
					
					drop_voxel(raycast + Vector3.UP)
					drop_voxel(raycast + Vector3.DOWN)
					drop_voxel(raycast + Vector3.LEFT)
					drop_voxel(raycast + Vector3.RIGHT)
					drop_voxel(raycast + Vector3.FORWARD)
					drop_voxel(raycast + Vector3.BACK)
					
					#FIX PERFOMANCE BUT UNTIL THEN, UNUSED! (it sometimes detects chunks, but does'nt delete them and turn them into ridgidbodies)
					#CCL(raycast)
					
					#make sure that the voxel the item spawns in a air voxel (MAYBE, create queue for 'pickups' and repeatedly tries to spawn them until they are able to spawn)
					get_parent().create_item(id, raycast, Vector3.ZERO)
					if id == 11:
						for node in get_tree().get_nodes_in_group('chest'):
							if node.pos == raycast:
								node.remove_items()
		elif minebuild == 'build':
			vt.mode = VoxelTool.MODE_ADD
			if vt.value != 5 and vt.get_voxel(raycast()) != 5:# and not $ToInteract.is_colliding(): 
				#instead of not being able to place underwater, the water displaces itself
				#maybe dont do raycast thingy, but if I do keep it, make it raycast for every interaction
				print('build')
				vt.do_point(raycast())
				if vt.value == 11:
					var instance = chest.instantiate()
					add_child(instance)
					instance.pos = raycast()
					get_parent().update_chests(instance)
			
				if inventory_data.slot_datas[hot_bat_inv.selected_slot - 1]:
					if inventory_data.slot_datas[hot_bat_inv.selected_slot - 1].item_data != preload("res://inv_stuff/item/items/Stone Pail.tres"): #change to 'not a itemdatacontainer'
						if inventory_data.slot_datas[hot_bat_inv.selected_slot - 1].quantity == 1:
							inventory_data.slot_datas[hot_bat_inv.selected_slot - 1] = null
						else:
							inventory_data.slot_datas[hot_bat_inv.selected_slot - 1].quantity -= 1
		
		if inventory_data.slot_datas[hot_bat_inv.selected_slot - 1]:
			if inventory_data.slot_datas[hot_bat_inv.selected_slot - 1].item_data == preload("res://inv_stuff/item/items/Stone Pail.tres"): #change to 'a itemdatacontainer'
				print('use')
				inventory_data.slot_datas[hot_bat_inv.selected_slot - 1].item_data.use()
	
	$"../UI/HotBatInv".populate_hot_bar(inventory_data)
	$"../UI/InventoryInterface/PlayerInventory".populate_item_grid(inventory_data)
	
	if select_raycast() and vt.get_voxel(select_raycast()) == 11 and Input.is_action_just_pressed("Camera"):
		for node in get_tree().get_nodes_in_group('chest'):
			if node.pos == select_raycast():
				node.player_interact()
	
	if Input.is_action_just_pressed("InventoryToggle"):
		toggle_inv.emit()

func submerged() -> bool:
	if vt.get_voxel(position.floor()) == 5\
	or vt.get_voxel(position + Vector3.UP.floor()) == 5 or vt.get_voxel(position + Vector3.DOWN.floor()) == 5\
	or vt.get_voxel(position + Vector3.LEFT.floor()) == 5 or vt.get_voxel(position + Vector3.RIGHT.floor()) == 5\
	or vt.get_voxel(position + Vector3.FORWARD.floor()) == 5 or vt.get_voxel(position + Vector3.BACK.floor()) == 5:
		return true
	else:
		return false

func drop_water(container):
	#be able to place water on water
	minebuild = 'build'
	vt.mode = VoxelTool.MODE_ADD
	var raycast = Vector3(raycast())
	if vt.get_voxel(raycast) == 0:
		print('drop')
		vt.do_point(raycast)
		container.amount_left -= 1

func collect_water(container):
	minebuild = 'mine'
	vt.mode = VoxelTool.MODE_REMOVE
	var raycast = vt_raycast()
	if vt.get_voxel(raycast) == 5:
		print('collect')
		vt.do_point(raycast)
		container.amount_left += 1
		
		drop_voxel(raycast + Vector3.UP)
		drop_voxel(raycast + Vector3.DOWN)
		drop_voxel(raycast + Vector3.LEFT)
		drop_voxel(raycast + Vector3.RIGHT)
		drop_voxel(raycast + Vector3.FORWARD)
		drop_voxel(raycast + Vector3.BACK)

func raycast():
	var par = PhysicsRayQueryParameters3D.new()
	cam = get_tree().root.get_camera_3d()
	par.from = cam.project_ray_origin(get_viewport().get_mouse_position())
	par.to = par.from + cam.project_ray_normal(get_viewport().get_mouse_position()) * 20000
	var ray = get_world_3d().direct_space_state.intersect_ray(par)
	
	if ray.has('position') and ray['collider'] != get_parent().get_node('CharacterBody3d') and global_position.distance_to(ray['position']) <= 5:
		var normal = ray['normal']
		ray = ray['position']
		if minebuild == 'mine':
			ray = ray - (normal.normalized()*0.5)
		else:
			ray = ray + (normal.normalized()*0.5)
		ray = Vector3(snap(1, ray.x), snap(1, ray.y), snap(1, ray.z))
		$Interact.visible = true
		return ray
	else:
		ray = null
		$Interact.visible = false
		return ray
	return Vector3()

func select_raycast():
	var par = PhysicsRayQueryParameters3D.new()
	cam = get_tree().root.get_camera_3d()
	par.from = cam.project_ray_origin(get_viewport().get_mouse_position())
	par.to = par.from + cam.project_ray_normal(get_viewport().get_mouse_position()) * 20000
	var ray = get_world_3d().direct_space_state.intersect_ray(par)
	
	if ray.has('position') and ray['collider'] != get_parent().get_node('CharacterBody3d') and global_position.distance_to(ray['position']) <= 5:
		var normal = ray['normal']
		ray = ray['position']
		ray = ray - (normal.normalized()*0.5)
		ray = Vector3(snap(1, ray.x), snap(1, ray.y), snap(1, ray.z))
		return ray
	return Vector3()

func snap(grid, num):
	var end = (grid * floor(num / grid)) + (grid / 2)
	return end

func drop_voxel(pos):#NEED BLENDER TO CREATE WATER-SLABS
	if vt.get_voxel(pos) == 5: #change after version 1 for more liquids
		if vt.get_voxel(Vector3(pos.x, pos.y - 1, pos.z)) == 0:
			await get_tree().create_timer(0.1).timeout
			vt.value = 5
			vt.do_point(Vector3(pos.x, pos.y - 1, pos.z))
			vt.value = 0
			vt.do_point(Vector3(pos.x, pos.y, pos.z))
			drop_voxel(Vector3(pos.x, pos.y - 1, pos.z))
		if vt.get_voxel(Vector3(pos.x, pos.y - 1, pos.z)) != 0:
			pass

func CCL(pos: Vector3):
	var rigidbody_node = $"../RigidBodies"
	var rigidbody = preload("res://physics_stuff/rigid_body.tscn")
	var cube = preload("res://physics_stuff/voxel.tscn")
	
	const BOX_SIZE = 40
	
	var label = 1
	var labels = []
	var equal_labels = []
	
	for x in BOX_SIZE:
		labels.append([])
		for y in BOX_SIZE:
			labels[x].append([])
			for z in BOX_SIZE:
				labels[x][y].append(0)
	
	#water should be considred as air? (and then water uses physics to make things float, add after I turn chunks into terrain nodes)
	for x in BOX_SIZE:
		for y in BOX_SIZE:
			for z in BOX_SIZE:
				var voxel = (pos - Vector3(BOX_SIZE / 2, BOX_SIZE / 2, BOX_SIZE / 2)) + Vector3(x,y,z)
				
				if vt.get_voxel(voxel) != 0:
					var neighbors = []
					if vt.get_voxel(Vector3(voxel.x-1,voxel.y,voxel.z)) != 0:
						if labels[x-1][y][z] and labels[x-1][y][z] != 0:
							neighbors.append(labels[x-1][y][z])
					if vt.get_voxel(Vector3(voxel.x,voxel.y-1,voxel.z)) != 0:
						if labels[x][y-1][z] and labels[x][y-1][z] != 0:
							neighbors.append(labels[x][y-1][z])
					if vt.get_voxel(Vector3(voxel.x,voxel.y,voxel.z-1)) != 0:
						if labels[x][y][z-1] and labels[x][y][z-1] != 0:
							neighbors.append(labels[x][y][z-1])
					
					if neighbors.size() == 0:
						labels[x][y][z] = label
						label += 1
					elif neighbors.count(neighbors[0]) == neighbors.size():
						labels[x][y][z] = neighbors[0]
					else:
						labels[x][y][z] = neighbors.min()
						
						var matched = false
						
						for set in equal_labels:
							for l in neighbors:
								if set.has(l):
									matched = true
									equal_labels[equal_labels.find(set)].append_array(neighbors)
						
						if not equal_labels.has(neighbors) and not matched:
							equal_labels.append(neighbors)
	
	var new_equal_labels = []
	for set in equal_labels:
		var unique_labels = []
		for l in set:
			if not unique_labels.has(l):
				unique_labels.append(l)
		unique_labels.sort()
		if not new_equal_labels.has(unique_labels):
			new_equal_labels.append(unique_labels)
	equal_labels = new_equal_labels
	new_equal_labels = []
	
	var flat = []
	for x in BOX_SIZE:
		for y in BOX_SIZE:
			for z in BOX_SIZE:
				var voxel = (pos - Vector3(BOX_SIZE / 2, BOX_SIZE / 2, BOX_SIZE / 2)) + Vector3(x,y,z)
				if vt.get_voxel(voxel) != 0:
					for set in equal_labels:
						if set.has(labels[x][y][z]):
							labels[x][y][z] = set.min()
				
				if not flat.has(labels[x][y][z]):
					flat.append(labels[x][y][z])
	
	flat.sort()
	var old_flat = flat
	for l in flat:
		if flat[flat.find(l)] != 0:
			flat[flat.find(l)] = flat[flat.find(l) - 1] + 1
	
	var terrain_labels = []
	for x in BOX_SIZE:
		for y in BOX_SIZE:
			for z in BOX_SIZE:
				labels[x][y][z] = flat[old_flat.find(labels[x][y][z])]
				
				#if section is touching edge, it does not turn into a ridgidbody, WILL need to get a bigger box somehow
				if not terrain_labels.has(labels[x][y][z]) and labels[x][y][z] != 0:
					if x == 0 or x == 39 or y == 0 or y == 39 or z == 0 or z == 39:
						terrain_labels.append(labels[x][y][z])
	terrain_labels.sort()
	
	var old_terrain_labels = terrain_labels
	terrain_labels = []
	for l in flat:
		if not old_terrain_labels.has(l) and l != 0:
			terrain_labels.append(l)
	old_terrain_labels = []
	
	print(terrain_labels)
	
	#counsult with the godot voxels server, this idea is goofy
	#also sleep and hide rigidbodies when out of range if voxel viewer dosent work out
	#I could make them seperate terrain nodes! (something about voxel buffers)
	#rigidbodies need to seperate into smaller ones too!
	vt.mode = VoxelTool.MODE_REMOVE
	for l in terrain_labels:
		var instance = rigidbody.instantiate()
		rigidbody_node.add_child(instance)
		for x in BOX_SIZE:
			for y in BOX_SIZE:
				for z in BOX_SIZE:
					if labels[x][y][z] == l:
						var voxel = (pos - Vector3(BOX_SIZE / 2, BOX_SIZE / 2, BOX_SIZE / 2)) + Vector3(x,y,z)
						var type = vt.get_voxel(voxel)
						vt.do_point(voxel)
						
						var voxel_instance: CollisionShape3D = cube.instantiate()
						voxel_instance.voxel = ID_TO_NAME[type]
						instance.add_child(voxel_instance)
						voxel_instance.transform.origin = voxel

func get_drop_position():
	var par = PhysicsRayQueryParameters3D.new()
	cam = get_tree().root.get_camera_3d()
	par.from = cam.project_ray_origin(get_viewport().get_mouse_position())
	par.to = par.from + cam.project_ray_normal(get_viewport().get_mouse_position()) * 20000
	var ray = get_world_3d().direct_space_state.intersect_ray(par)
	
	if ray.has('position') and ray['collider'] != get_parent().get_node('CharacterBody3d') and global_position.distance_to(ray['position']) <= 5:
		var normal = ray['normal']
		ray = ray['position']
		ray = ray + (normal.normalized()*0.5)
		return ray
	else:
		ray = null
		return ray
	return Vector3()

func vt_raycast():
	if raycast():
		var raycast = vt.raycast(cam.global_position, cam.global_position.direction_to(raycast() + Vector3(0.5,0.5,0.5)), 5000)
		if raycast:
			return raycast.position
