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
		# Automatically grab days and coins from the browser URL on startup
		var url_days = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('days');")
		var url_coins = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('coins');")
		
		if url_days != null and url_days != "":
			days_progress = int(url_days)
		if url_coins != null and url_coins != "":
			coins = int(url_coins)
			
		print("[LOAD] Loaded from database -> Days: ", days_progress, " | Coins: ", coins)

func update_progress_and_sync(new_days: int, new_coins: int) -> void:
	days_progress = new_days
	coins = new_coins
	data_changed.emit()

func add_coins(amount: int) -> void:
	coins += amount
	update_progress_and_sync(days_progress, coins)

func remove_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		update_progress_and_sync(days_progress, coins)
		return true
	return false

# Master exit function that packages live stats into the redirect URL
func exit_to_dashboard() -> void:
	update_progress_and_sync(days_progress, coins)
	
	if OS.has_feature("web"):
		var url = "http://localhost/GameLauncher/dashboard.php?days=%d&coins=%d" % [days_progress, coins]
		JavaScriptBridge.eval("window.location.href = '%s';" % url)
	else:
		get_tree().quit()
