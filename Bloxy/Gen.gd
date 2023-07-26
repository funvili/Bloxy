extends VoxelGeneratorScript

const channel : int = VoxelBuffer.CHANNEL_TYPE
const graph = preload('res://Generation.tres')
const AIR = 0

#make mountains ridgid and taller
#add rivers and water features above alt 0, underwater there are patches of stone and dirt
#add islands
#cave openings above land, and probaly fix up the caves more, is there gold in there?

var tree_max_height = 1000
var unfinished_trees := []

func _get_used_channels_mask() -> int:
	return 1 << channel

func _generate_block(voxels : VoxelBuffer, origin : Vector3i, lod : int):
	graph.generate_block(voxels, origin, lod)
	var tree = randi_range(0, 5)
	
	if tree < 5:
		treegen(origin, voxels, randi_range(3, 14), randi_range(3, 14))
		if tree < 4:
			treegen(origin, voxels, randi_range(3, 14), randi_range(3, 14))
			if tree < 3:
				treegen(origin, voxels, randi_range(3, 14), randi_range(3, 14))
				if tree < 2:
					treegen(origin, voxels, randi_range(3, 14), randi_range(3, 14))
					if tree < 1:
						treegen(origin, voxels, randi_range(3, 14), randi_range(3, 14))
						if tree < 0:
							treegen(origin, voxels, randi_range(3, 14), randi_range(3, 14))

func get_height_at(x: int, z: int, search_min_y: int, search_max_y: int) -> int:
	var _column = VoxelBuffer.new()
	_column.create(1, search_max_y - search_min_y, 1)
	graph.generate_block(_column, Vector3i(x, search_min_y, z), 0)

	var ry := _column.get_size().y - 1
	while ry >= 0:
		if _column.get_voxel(0, ry, 0) != AIR:
			return search_min_y + ry
		ry -= 1
	return -1
	
func treegen(origin, voxels, x, z):
	var tree_x = origin.x + x
	var tree_z = origin.z + z
	var h = get_height_at(tree_x, tree_z, origin.y - tree_max_height, origin.y + voxels.get_size().y)
	
	if voxels.get_voxel(x, h - origin.y, z) == 1 and h - origin.y < 10 and origin.y > 0:
		voxels.fill_area(7, Vector3i(x-2,h - origin.y + 3,z-2), Vector3i(x+3,h - origin.y + randi_range(8, 15),z+3))
		voxels.fill_area(6, Vector3i(x, h - origin.y + 1, z), Vector3i(x+1,h - origin.y + 6,z+1))
