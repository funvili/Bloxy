extends Control

signal drop_slot_data(slot_data: SlotData)
signal force_close

var grabbed_slot_data: SlotData
var external_inventory_owner

@onready var player_inventory: PanelContainer = $PlayerInventory
@onready var external_inventory: PanelContainer = $ExternalInventory
@onready var equip_inventory: PanelContainer = $EquipInventory
@onready var grabbed_slot: Panel = $GrabbedSlot
@onready var player: RigidBody3D = $"../../CharacterBody3d"

func _physics_process(delta: float) -> void:
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(5,5)
	if is_instance_valid(external_inventory_owner) and external_inventory_owner.pos.distance_to(PlayerManager.get_global_position()) > 6:
		force_close.emit()

func set_player_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	player_inventory.set_inventory_data(inventory_data)

func set_equip_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_interact.connect(on_inventory_interact)
	equip_inventory.set_inventory_data(inventory_data)

func set_external_inventory(_external_inventory_owner) -> void:
	external_inventory_owner = _external_inventory_owner
	var inventory_data = external_inventory_owner.inventory_data
	
	inventory_data.inventory_interact.connect(on_inventory_interact)
	external_inventory.set_inventory_data(inventory_data)

func clear_external_inventory() -> void:
	if external_inventory_owner:
		var inventory_data = external_inventory_owner.inventory_data
		
		inventory_data.inventory_interact.disconnect(on_inventory_interact)
		external_inventory.clear_inventory_data(inventory_data)
		
		external_inventory.hide()
		external_inventory_owner = null

func on_inventory_interact(inventory_data: InventoryData, index: int, button: int) -> void:
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[null, MOUSE_BUTTON_RIGHT]:
			inventory_data.use_slot_data(index)
		[_, MOUSE_BUTTON_RIGHT]:
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
	
	update_grabbed_slot()

func update_grabbed_slot() -> void:
	if grabbed_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot.hide()

func _on_inventory_interface_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and grabbed_slot_data:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				if player.get_drop_position():
					drop_slot_data.emit(grabbed_slot_data.create_single_slot_data())
					if grabbed_slot_data.quantity < 1:
						grabbed_slot_data = null
		update_grabbed_slot()

func _on_inventory_interface_visibility_changed():
	if not visible and grabbed_slot_data:
		pass #put item back in slot when you are still holding it and you hide inv (maybe)
