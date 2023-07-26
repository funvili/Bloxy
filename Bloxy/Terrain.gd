extends VoxelTerrain

const MyGenerator = preload("res://Gen.gd")

@onready var terrain = get_parent().get_node('VoxelTerrain')

func _ready():
	terrain.generator = MyGenerator.new()
