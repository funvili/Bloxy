extends Node3D

#everything with volume and mass is goofy right now...
const PickUp = preload("res://inv_stuff/item/pick_up.tscn")

const ID_TO_ITEM = [null, 
	preload("res://inv_stuff/item/items/Grass.tres"),
	preload("res://inv_stuff/item/items/Dirt.tres"),
	preload("res://inv_stuff/item/items/Stone.tres"),
	preload("res://inv_stuff/item/items/Sand.tres"),
	null, # water voxel
	preload("res://inv_stuff/item/items/Oak Log.tres"),
	preload("res://inv_stuff/item/items/Oak Leaves.tres"),
	preload("res://inv_stuff/item/items/Raw Coal.tres"),
	preload("res://inv_stuff/item/items/Raw Iron.tres"),
	preload("res://inv_stuff/item/items/Raw Gold.tres"),
	preload("res://inv_stuff/item/items/Wooden Crate.tres")
]

@onready var player: RigidBody3D = $CharacterBody3d
@onready var inventory_interface: Control = $UI/InventoryInterface
@onready var hot_bat_inv: PanelContainer = $UI/HotBatInv

var slot = SlotData.new()

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
		inventory_interface.clear_external_inventory()

func update_chests(node):
	node.toggle_inventory.connect(toggle_external_inventory_interface)

func _on_inventory_interface_drop_slot_data(slot_data):
	var pick_up = PickUp.instantiate()
	pick_up.slot_data = slot_data
	pick_up.position = player.get_drop_position()
	add_child(pick_up)

func create_item(id: int, pos: Vector3, rot: Vector3):
	print(id)
	var pick_up = PickUp.instantiate()
	pick_up.slot_data = slot.create_single_slot_data()
	pick_up.slot_data.item_data = ID_TO_ITEM[id]
	pick_up.position = pos + Vector3(.5,.5,.5)
	pick_up.rotation = rot
	add_child(pick_up)
