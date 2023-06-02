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
			#more testing on voxel physics
			#for floodfill: end = false
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
	#It scans through a box of voxels, giving connected ones a "label" (ID)
	#When different labels touch as it goes through them it merges them as a single label
	#At the end, a grid of labels is obtained so each one can be extracted
	#as its own "floating chunk" of voxels
	
	var next_label = 0
	
	var data = []
	var linked = []
	var labels = []
	
	var x = 0
	var y = 0
	var z = 0
	
	const BOX_SIZE = 20
	while x < BOX_SIZE:
		labels.append([])
		data.append([])
		while y < BOX_SIZE:
			labels[x].append([])
			data[x].append([])
			while z < BOX_SIZE:
				labels[x][y].append(0)
				var voxel = (pos - Vector3(10,10,10)) + Vector3(x,y,z)
				data[x][y].append(vt.get_voxel(voxel))
				z += 1
			y += 1
			z = 0
		x += 1
		y = 0
		z = 0
	x = 0
	
	for x2 in BOX_SIZE:
		for y2 in BOX_SIZE:
			for z2 in BOX_SIZE:
				#var voxel = (pos - Vector3(10,10,10)) + Vector3(x2,y2,z2)
				#vt.do_point(voxel)
				#will need for when I turn them into ridgidbodies
				if data[x2][y2][z2] != 0:
					var neighbors = []
					if data[x2][y2+1][z2] != 0 and labels[x2][y2+1][z2] != null:
						neighbors.append(labels[x2][y2+1][z2])
					if data[x2][y2-1][z2] != 0 and labels[x2][y2-1][z2] != null:
						neighbors.append(labels[x2][y2-1][z2])
					if data[x2-1][y2][z2] != 0 and labels[x2-1][y2][z2] != null:
						neighbors.append(labels[x2-1][y2][z2])
					if data[x2+1][y2][z2] != 0 and labels[x2+1][y2][z2] != null:
						neighbors.append(labels[x2+1][y2][z2])
					if data[x2][y2][z2-1] != 0 and labels[x2][y2][z2-1] != null:
						neighbors.append(labels[x2][y2][z2-1])
					if data[x2][y2][z2+1] != 0 and labels[x2][y2][z2+1] != null:
						neighbors.append(labels[x2][y2][z2+1])
					
					if neighbors.size() == 0:
						linked[next_label] = [next_label]
						labels[x2][y2][z2] = next_label
						next_label += 1
					else:
						var L = neighbors
						labels[x2][y2][z2] = min(L)
						print(L)
						for label in L:
							linked[label].append(L)
	
	#for x2 in BOX_SIZE:
		#for y2 in BOX_SIZE:
			#for z2 in BOX_SIZE:
				#if data[x2][y2][z2] != 0:
					#print(labels[x2][y2][z2])
					#labels[x2][y2][z2] = labels.find(labels[x2][y2][z2])
	
	for x2 in BOX_SIZE:
		for y2 in BOX_SIZE:
			for z2 in BOX_SIZE:
				var voxel = (pos - Vector3(10,10,10)) + Vector3(x2,y2,z2)
				if labels[x2][y2][z2] == 1:
					vt.mode = VoxelTool.MODE_ADD
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
