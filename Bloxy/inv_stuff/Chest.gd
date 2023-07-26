extends Node3D

signal toggle_inventory(external_inventory_owner)
@export var inventory_data = InventoryData.new()

@onready var player = find_parent('Node3d').get_node('CharacterBody3d')

#give area3d to chests for better selection (or not, actually!)
var pos = Vector3()

func _ready():
	global_position = pos
	inventory_data.slot_datas = [null,null,null,null]

func player_interact() -> void:
	toggle_inventory.emit(self)

func remove_items():
	find_parent('Node3d').get_node('UI/InventoryInterface').clear_external_inventory()
	for slot in inventory_data.slot_datas:
		if slot:
			for item in slot.quantity:
				find_parent('Node3d').create_item(player.ID_TO_NAME.find(slot.item_data.name), pos, Vector3.ZERO)
	queue_free()
