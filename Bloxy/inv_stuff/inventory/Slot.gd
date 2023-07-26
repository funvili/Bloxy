extends Panel

signal slot_clicked(index: int, button: int)

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect
@onready var quantity_label: Label = $QuantityLabel
@onready var amount_label: Label = $AmountLabel
@onready var container_mode_label: Label = $ContainerModeLabel

func set_slot_data(slot_data: SlotData) -> void:
	var item_data = slot_data.item_data
	if item_data:
		texture_rect.texture = item_data.texture
		tooltip_text = "%s\n%s" % [item_data.name, item_data.description]
	
	if slot_data.quantity > 1:
		quantity_label.text = "x%s" % slot_data.quantity
		quantity_label.show()
	else:
		quantity_label.hide()
	
	if slot_data.item_data is ItemDataContainer:
		amount_label.text = "%s" % slot_data.item_data.amount_left
		amount_label.show()
		
		if PlayerManager.player.get_parent().get_node('UI/HotBatInv').container_mode:
			container_mode_label.text = 'v'
		else:
			container_mode_label.text = '^'
		container_mode_label.show()
	else:
		amount_label.hide()

func _on_slot_mouse_entered():
	find_parent('Node3d').get_node('CharacterBody3d').mouse_on_UI = true

func _on_slot_mouse_exited():
	find_parent('Node3d').get_node('CharacterBody3d').mouse_on_UI = false

func _on_slot_gui_input(event):
	if event is InputEventMouseButton \
			and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT) \
			and event.is_pressed():
		slot_clicked.emit(get_index(), event.button_index)
