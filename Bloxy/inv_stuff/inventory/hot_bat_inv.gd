extends PanelContainer

signal hot_bar_use(index: int)

const Slot = preload("res://inv_stuff/inventory/Slot.tscn")

@onready var h_box_container: HBoxContainer = $MarginContainer/HBoxContainer
@onready var player = find_parent('Node3d').get_node('CharacterBody3d')

@onready var normal_color: Color
@onready var selected_color: Color

var selected_slot = 0
var container_mode = true
#true is drop, false is collect

func _ready():
	normal_color.r = 255
	normal_color.g = 255
	normal_color.b = 255
	
	selected_color.r = 2550
	selected_color.g = 2550
	selected_color.b = 2550

func _unhandled_key_input(event):
	var old = selected_slot
	var pressed = false
	
	if event.is_action('0'):
		selected_slot = 0
		pressed = true
	elif event.is_action('1'):
		selected_slot = 1
		pressed = true
	elif event.is_action('2'):
		selected_slot = 2
		pressed = true
	elif event.is_action('3'):
		selected_slot = 3
		pressed = true
	elif event.is_action('4'):
		selected_slot = 4
		pressed = true
	
	if pressed and old == selected_slot and not event.is_pressed() and selected_slot != 0 and player.inventory_data.slot_datas[selected_slot - 1]:
		#if player.inventory_data.slot_datas[selected_slot - 1].item_data.name == 'Stone Pail':
			change_container_mode()

func change_container_mode():
	container_mode = not container_mode
	
	if container_mode:
		player.minebuild = 'build'
	else:
		player.minebuild = 'mine'

func _process(delta):
	if selected_slot != 0 and player.inventory_data.slot_datas[selected_slot - 1]:
		if player.inventory_data.slot_datas[selected_slot - 1].item_data.name != 'Stone Pail':
			player.minebuild = 'build'
		player.vt.value = player.ID_TO_NAME.find(player.inventory_data.slot_datas[selected_slot - 1].item_data.name)
	else:
		player.minebuild = 'mine'
	if selected_slot != 0:
		$MarginContainer/HBoxContainer.get_child(selected_slot - 1).self_modulate = selected_color

func set_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_update.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)
	hot_bar_use.connect(inventory_data.use_slot_data)

func populate_hot_bar(inventory_data: InventoryData) -> void:
	for child in h_box_container.get_children():
		child.queue_free()
	
	for slot_data in inventory_data.slot_datas.slice(0,4):
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
		
		if slot_data:
			slot.set_slot_data(slot_data)
