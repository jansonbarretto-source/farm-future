extends Node

# Player Currencies & Resources
var money: int = 500
var seeds: int = 10
var wheat: int = 0

# Hotbar Item Selection
enum ActiveItem { HOE, WATERING_CAN, SEED }
var selected_item: ActiveItem = ActiveItem.HOE

# Signal to notify UI when data changes
signal data_changed

func add_money(amount: int) -> void:
	money += amount
	data_changed.emit()

func remove_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		data_changed.emit()
		return true
	return false

func add_seeds(amount: int) -> void:
	seeds += amount
	data_changed.emit()

func remove_seeds(amount: int) -> bool:
	if seeds >= amount:
		seeds -= amount
		data_changed.emit()
		return true
	return false

func add_wheat(amount: int) -> void:
	wheat += amount
	data_changed.emit()

func remove_wheat(amount: int) -> bool:
	if wheat >= amount:
		wheat -= amount
		data_changed.emit()
		return true
	return false

func select_item(item: ActiveItem) -> void:
	selected_item = item
	data_changed.emit()
