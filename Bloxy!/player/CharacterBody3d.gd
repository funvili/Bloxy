extends RigidBody3D

#wind up camera on startup and load all chunks first

const SPEED = 50#14
const JUMP_VELOCITY = 25#12

@onready var spring_arm = $SpringArm3d
@onready var model  = $CsgBox3d
@onready var cam = $SpringArm3d/Camera3d
@onready var interact = $Interact

@onready var terrain = get_parent().get_node('VoxelTerrain')
@onready var vt = get_parent().get_node('VoxelTerrain').get_voxel_tool()

@onready var chest = preload("res://chest.tscn")
@onready var inventory = preload('res://inv_stuff/inventory/Inventory.tscn')

@export var inventory_data: InventoryData
@export var equip_inventory_data: InventoryDataEquip

signal toggle_inv()

var mouse_on_UI = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var minebuild = 'mine'

var voxels_connected = 1
var voxels_connected_array = []
var end = false

var rot_speed = 5
var health = 10

func _ready():
	PlayerManager.player = self

func _physics_process(delta):
	
	if raycast():
		interact.global_position = Vector3(raycast().x + 0.5, raycast().y + 0.5, raycast().z + 0.5)
	
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
	
	if Input.is_action_just_pressed("Switch"):
		if minebuild == 'mine':
			minebuild = 'build'
		else:
			minebuild = 'mine'
	
	if Input.is_action_just_pressed("Mine") and raycast() != null and mouse_on_UI != true:
		await not end
		vt.value = 3
		if minebuild == 'mine':
			vt.mode = VoxelTool.MODE_REMOVE
			vt.do_point(raycast())
			CCL(raycast())
		else:
			vt.mode = VoxelTool.MODE_ADD
			vt.do_point(raycast())
			if vt.value == 5:
				drop_voxel(raycast())
			if vt.value == 11:
				var instance = chest.instantiate()
				add_child(instance)
				instance.pos = raycast()
				get_parent().update_chests(instance)
	
	if select_raycast() and vt.get_voxel(select_raycast()) == 11 and Input.is_action_just_pressed("Camera"):
		for node in get_tree().get_nodes_in_group('chest'):
			if node.pos == select_raycast():
				node.player_interact()
	
	if Input.is_action_just_pressed("InventoryToggle"):
		toggle_inv.emit()

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

func drop_voxel(pos):
	if vt.get_voxel(Vector3(pos.x, pos.y - 1, pos.z)) == 0:
		await get_tree().create_timer(0.1).timeout
		vt.value = 5
		vt.do_point(Vector3(pos.x, pos.y - 1, pos.z))
		vt.value = 0
		vt.do_point(Vector3(pos.x, pos.y, pos.z))
		drop_voxel(Vector3(pos.x, pos.y - 1, pos.z))

func floodfill(pos: Vector3):
	#either use this floodfil or CCL, and I might need C++
	
	#floodfill starting from the 6 neighbor voxels if present
	#if the algorithm stops before reaching the limit
	#then it has found a reasonably small floating chunk
	#could be a tree
	
	if end:
		return
	
	if voxels_connected > 100000:
		print('done')
		end = true
		voxels_connected = 0
		return
	else:
		voxels_connected += 1
	
	voxels_connected_array.append(pos)
	print(voxels_connected)
	vt.mode = VoxelTool.MODE_ADD
	vt.do_point(pos)
	
	await get_tree().create_timer(0.001).timeout
	if vt.get_voxel(pos + Vector3.UP) != 0:
		floodfill(pos + Vector3.UP)
	if vt.get_voxel(pos + Vector3.DOWN) != 0:
		floodfill(pos + Vector3.DOWN)
	if vt.get_voxel(pos + Vector3.LEFT) != 0:
		floodfill(pos + Vector3.LEFT)
	if vt.get_voxel(pos + Vector3.RIGHT) != 0:
		floodfill(pos + Vector3.RIGHT)
	if vt.get_voxel(pos + Vector3.FORWARD) != 0:
		floodfill(pos + Vector3.FORWARD)
	if vt.get_voxel(pos + Vector3.BACK) != 0:
		floodfill(pos + Vector3.BACK)

func CCL(pos: Vector3):
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
								if set.has(l):# and not matched:
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
	
	#check each array after, if none of the unique numbers of the current array match
	#add another array that the algorithm checks
	#then if something matches but has a new number, add the new number
	
	for x in BOX_SIZE:
		for y in BOX_SIZE:
			for z in BOX_SIZE:
				var voxel = (pos - Vector3(BOX_SIZE / 2, BOX_SIZE / 2, BOX_SIZE / 2)) + Vector3(x,y,z)
				if vt.get_voxel(voxel) != 0:
					for set in equal_labels:
						if set.has(labels[x][y][z]):
							labels[x][y][z] = set.min()
	print(labels)
	
	vt.mode = VoxelTool.MODE_ADD
	
	for x in BOX_SIZE:
		for y in BOX_SIZE:
			for z in BOX_SIZE:
				var voxel = (pos - Vector3(BOX_SIZE / 2, BOX_SIZE / 2, BOX_SIZE / 2)) + Vector3(x,y,z)
				if vt.get_voxel(voxel) != 0: 
					vt.value = labels[x][y][z] + 1
					vt.do_point(voxel)

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

func heal(heal_value: int) -> void:
	health += heal_value
