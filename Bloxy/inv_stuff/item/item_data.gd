extends Resource
class_name ItemData

#tooltip should have stats (when all items are added)

@export var name: String = ''
@export_multiline var description: String = ''
@export var stackable: bool = false
@export var texture: AtlasTexture

func use() -> void:
	pass
