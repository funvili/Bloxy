extends Panel

signal slot_clicked(index: int, button: int)

@onready var texture_rect: TextureRect = $MarginContainer/TextureRect
@onready var quantity_label: Label = $QuantityLabel

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

func _on_slot_mouse_entered():
	find_parent('Node3d').get_node('CharacterBody3d').mouse_on_UI = true

func _on_slot_mouse_exited():
	find_parent('Node3d').get_node('CharacterBody3d').mouse_on_UI = false


func _on_slot_gui_input(event):
	if event is InputEventMouseButton \
			and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT) \
			and event.is_pressed():
		slot_clicked.emit(get_index(), event.button_index)
