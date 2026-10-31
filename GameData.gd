extends Node

signal data_changed

var days_progress: int = 1
var coins: int = 500 
var unlocked_slots: int = 6 
var crop_inventory: Dictionary = {"Wheat": 10}
var animal_inventory: Dictionary = {}
var seed_inventory: Dictionary = {}

func _ready() -> void:
	if OS.has_feature("web"):
		var js_days = JavaScriptBridge.eval("window.initialDaysProgress || 1")
		var js_coins = JavaScriptBridge.eval("window.initialCoins || 500")
		
		if js_days != null:
			days_progress = int(js_days)
		if js_coins != null:
			coins = int(js_coins)
			
		print("[LOAD] Loaded from database -> Days: ", days_progress, " | Coins: ", coins)

# Direktang i-sync ang progress papunta sa web dashboard/PHP backend
func update_progress_and_sync(new_days: int, new_coins: int) -> void:
	days_progress = new_days
	coins = new_coins
	data_changed.emit()
	
	if OS.has_feature("web"):
		var js_code = """
			if (window.updateDashboardProgress) {
				window.updateDashboardProgress(%d, %d);
			}
		""" % [days_progress, coins]
		JavaScriptBridge.eval(js_code)
		print("[BRIDGE] Sent progress to web dashboard -> Days: ", days_progress, " | Coins: ", coins)

func add_coins(amount: int) -> void:
	coins += amount
	update_progress_and_sync(days_progress, coins)

func remove_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		update_progress_and_sync(days_progress, coins)
		return true
	return false

# Tawagin ito kapag pinindot ang Exit button para bumalik sa dashboard
func exit_to_dashboard() -> void:
	update_progress_and_sync(days_progress, coins)
	
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = '../dashboard.php';")
	else:
		get_tree().quit()
