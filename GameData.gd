
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
		var url_days = JavaScriptBridge.eval(
			"new URLSearchParams(window.location.search).get('days');"
		)
		var url_coins = JavaScriptBridge.eval(
			"new URLSearchParams(window.location.search).get('coins');"
		)

		if url_days != null and url_days != "":
			days_progress = int(url_days)

		if url_coins != null and url_coins != "":
			coins = int(url_coins)

		print("[LOAD] Days: ", days_progress, " | Coins: ", coins)

	data_changed.emit()


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


func exit_to_dashboard() -> void:
	if OS.has_feature("web"):
		# TEMPORARY TEST: Check if this function is running.
		JavaScriptBridge.eval(
			"alert('GameData exit function is running!');"
		)

		var save_script = """
		fetch('/GameLauncher/update_progress.php', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json'
			},
			credentials: 'same-origin',
			body: JSON.stringify({
				days_progress: %d,
				coins: %d
			})
		})
		.then(function(response) {
			if (!response.ok) {
				throw new Error('Save request failed: ' + response.status);
			}
			return response.json();
		})
		.then(function(data) {
			console.log('[SAVE RESPONSE]', data);

			if (data.status === 'success') {
				alert('Progress saved! Coins: ' + data.coins);
				window.location.href = '/GameLauncher/dashboard.php';
			} else {
				alert('Save failed: ' + JSON.stringify(data));
			}
		})
		.catch(function(error) {
			console.error('[SAVE ERROR]', error);
			alert('Unable to save progress: ' + error.message);
		});
		""" % [days_progress, coins]

		JavaScriptBridge.eval(save_script)
	else:
		get_tree().quit()
