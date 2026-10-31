extends Node

# Tawagin ito tuwing nagbabago ang coins o araw ng player sa laro
func update_player_progress(current_days: int, current_coins: int) -> void:
	if OS.has_feature("web"):
		# Kinokonekta nito ang Godot papunta sa JavaScript function sa iyong HTML launcher page
		var js_code = """
			if (window.updateDashboardProgress) {
				window.updateDashboardProgress(%d, %d);
			}
		""" % [current_days, current_coins]
		JavaScriptBridge.eval(js_code)
	else:
		print("Running locally. Days: ", current_days, " | Coins: ", current_coins)
