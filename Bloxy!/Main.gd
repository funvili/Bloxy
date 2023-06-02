extends Node3D

const PickUp = preload("res://inv_stuff/item/pick_up.tscn")

@onready var player: RigidBody3D = $CharacterBody3d
@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bat_inv: PanelContainer = $UI/HotBatInv

func _ready() -> void:
	player.toggle_inv.connect(toggle_inventory_interface)
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.set_equip_inventory_data(player.equip_inventory_data)
	inventory_interface.force_close.connect(toggle_external_inventory_interface)
	hot_bat_inv.set_inventory_data(player.inventory_data)

func toggle_inventory_interface() -> void:
	inventory_interface.visible = not inventory_interface.visible
	
	if inventory_interface.visible:
		hot_bat_inv.hide()
	else:
		hot_bat_inv.show()

func toggle_external_inventory_interface(external_inventory_owner = null) -> void:
	$UI/InventoryInterface/ExternalInventory.visible = not $UI/InventoryInterface/ExternalInventory.visible
	if external_inventory_owner:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		pass
		#inventory_interface.clear_external_inventory()

func update_chests(node):
	#for node in get_tree().get_nodes_in_group('chest'):
	node.toggle_inventory.connect(toggle_external_inventory_interface)

func _on_inventory_interface_drop_slot_data(slot_data):
	var pick_up = PickUp.instantiate()
	pick_up.slot_data = slot_data
	pick_up.position = player.get_drop_position()
	add_child(pick_up)
