extends ItemData
class_name ItemDataContainer

@export var amount_left: int

func use() -> void:
	if name == 'Stone Pail':
		#stone pails would be able to use other things than water after first bloxy version
		if PlayerManager.player.get_parent().get_node('UI/HotBatInv').container_mode and amount_left != 0:
			PlayerManager.player.drop_water(self)
		elif amount_left != 10:
			PlayerManager.player.collect_water(self)
