extends Node

# Player Currencies & Resources
var money: int = 500
var seeds: int = 10
var wheat: int = 0

# Signal para madaling i-update ang UI kapag nagbago ang data
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
