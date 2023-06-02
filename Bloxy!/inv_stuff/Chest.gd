extends Node3D

signal toggle_inventory(external_inventory_owner)
@export var inventory_data = InventoryData.new()

var pos = Vector3()

func _ready():
	inventory_data.slot_datas = [null,null,null,null,null,null,null,null]

func player_interact() -> void:
	toggle_inventory.emit(self)
