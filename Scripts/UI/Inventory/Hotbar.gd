extends UserInterface

const SlotClass = preload("res://scripts/ui/inventory/Slot.gd") # Preload the Slot script
@onready var hotbar = $HotbarSlots # Reference to the HotbarSlots node
@onready var slots = $HotbarSlots.get_children() #List of all child nodes of HotbarSlots
@onready var active_item_label = $ActiveItemLabel # Reference to the ActiveItemLabel node
@onready var tooltip = $ActiveItemLabel/Tooltip # Reference to the Tooltip node
var t

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Sets up the Hotbar
	PlayerInventory.active_item_updated.connect(self.update_active_item_label)
	for i in range(slots.size()):
		slots[i].gui_input.connect(slot_gui_input.bind(slots[i]))
		PlayerInventory.active_item_updated.connect(slots[i].refresh_style)
		slots[i].slot_index = i
		slots[i].slot_type = SlotClass.SlotType.HOTBAR
	initialize_hotbar()
	update_active_item_label()
	
func tooltip_change():
	# Toggle the visibility of the tooltip
	tooltip.visible = !tooltip.visible

func update_active_item_label():
	tooltip.visible = true
	if PlayerInventory.active_item_slot == null or PlayerInventory.active_item_slot > 7:
		return
	if slots[PlayerInventory.active_item_slot].item != null:
		active_item_label.text = slots[PlayerInventory.active_item_slot].item.item_name
		tooltip.visible = true
		var tips = tooltip.get_children()
		tips[0].text = JsonData.item_data[active_item_label.text]["ItemCategory"]
		tips[1].text = slots[PlayerInventory.active_item_slot].item.item_name
		tips[2].text = JsonData.item_data[active_item_label.text]["Description"]
		if JsonData.item_data[slots[PlayerInventory.active_item_slot].item.item_name]["ItemCategory"] == "Consumable":
			tips[3].text = "Adds " + str(JsonData.item_data[slots[PlayerInventory.active_item_slot].item.item_name]["AddHealth"]) + " Health"
			tips[4].text = "Adds " + str(JsonData.item_data[slots[PlayerInventory.active_item_slot].item.item_name]["AddEnergy"]) + " Energy"
		elif JsonData.item_data[slots[PlayerInventory.active_item_slot].item.item_name]["ItemCategory"] == "Tool":
			tips[3].text = "Adds " + str(JsonData.item_data[slots[PlayerInventory.active_item_slot].item.item_name]["AddRepair"]) + " Repair"
			tips[4].text = "Adds " + str(JsonData.item_data[slots[PlayerInventory.active_item_slot].item.item_name]["AddEnergy"]) + " Energy"
		elif JsonData.item_data[slots[PlayerInventory.active_item_slot].item.item_name]["ItemCategory"] == "Weapon":
			tips[3].text = "Damage: " + str(JsonData.item_data[slots[PlayerInventory.active_item_slot].item.item_name]["ItemAttack"])
			tips[4].text = "Reload: " + str(JsonData.item_data[slots[PlayerInventory.active_item_slot].item.item_name]["ItemReload"]) + "s"
		else:
			tips[3].text = ""
			tips[4].text = ""
	else:
		active_item_label.text = "Empty Slot"
		tooltip.visible = false
		
func initialize_hotbar():
	for i in range(slots.size()):
		if PlayerInventory.hotbar.has(i):
			slots[i].initialize_item(PlayerInventory.hotbar[i][0], PlayerInventory.hotbar[i][1])

func slot_gui_input(event: InputEvent, slot: SlotClass):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			if find_parent("UI").holding_item != null:
				if !slot.item:
					PlayerInventory.add_item_to_empty_slot(find_parent("UI").holding_item, slot)
					slot.putIntoSlot(find_parent("UI").holding_item)
					find_parent("UI").holding_item = null
				else:
					if find_parent("UI").holding_item.item_name != slot.item.item_name:
						PlayerInventory.remove_item(slot)
						PlayerInventory.add_item_to_empty_slot(find_parent("UI").holding_item, slot)
						var temp_item = slot.item
						slot.pickFromSlot()
						temp_item.global_position = event.global_position
						slot.putIntoSlot(find_parent("UI").holding_item)
						find_parent("UI").holding_item = temp_item
					else:
						var stack_size = int(JsonData.item_data[slot.item.item_name]["StackSize"])
						var able_to_add = stack_size - slot.item.item_quantity
						if able_to_add >= find_parent("UI").holding_item.item_quantity:
							PlayerInventory.add_item_quantity(slot, find_parent("UI").holding_item.item_quantity)
							slot.item.add_item_quantity(find_parent("UI").holding_item.item_quantity)
							find_parent("UI").holding_item.queue_free()
							find_parent("UI").holding_item = null
						else:
							PlayerInventory.add_item_quantity(slot, able_to_add)
							slot.item.add_item_quantity(able_to_add)
							find_parent("UI").holding_item.decrease_item_quantity(able_to_add)
			elif slot.item:
				PlayerInventory.remove_item(slot)
				find_parent("UI").holding_item = slot.item
				slot.pickFromSlot()
				find_parent("UI").holding_item.global_position = get_global_mouse_position()
			update_active_item_label()
		if event.button_index == MOUSE_BUTTON_RIGHT && event.pressed:
			if slot.item:
				var amount_to_remove = slot.item.item_quantity/2
				PlayerInventory.decrease_item_quantity(slot, amount_to_remove)
				slot.item.decrease_item_quantity(amount_to_remove)
				t = SlotClass.new()
				add_child(t)
				t.initialize_item(slot.item.item_name, amount_to_remove)
				find_parent("UI").holding_item = t.item
				t.remove_child(t.item)
				t.getFromSlot()
				find_parent("UI").holding_item.global_position = get_global_mouse_position()
