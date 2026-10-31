extends TextureButton

const SETTINGS_ICON_PATH = "res://Settings button.png"

func _ready() -> void:
	# Sinisiguro na mare-register ang mouse click input
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	position = Vector2(20, 85)
	custom_minimum_size = Vector2(40, 40)
	
	if ResourceLoader.exists(SETTINGS_ICON_PATH):
		texture_normal = load(SETTINGS_ICON_PATH)
		ignore_texture_size = true
		stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	else:
		print("[WARNING] Settings icon texture not found at: ", SETTINGS_ICON_PATH)
	
	if not is_connected("pressed", _on_pressed):
		pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("open")
		
	var existing_settings = get_tree().current_scene.get_node_or_null("SettingsLayer")
	if existing_settings:
		return

	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "SettingsLayer"
	canvas_layer.layer = 120
	
	var settings_ui = Control.new()
	settings_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.03, 0.02, 0.75)
	bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			canvas_layer.queue_free()
	)
	settings_ui.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_ui.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 380)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.11, 0.07, 0.98)
	style.border_color = Color(0.9, 0.63, 0.27, 1.0)
	style.set_border_width_all(5)
	style.border_width_top = 7
	style.set_corner_radius_all(14)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	style.shadow_color = Color(0, 0, 0, 0.85)
	style.shadow_size = 16
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🌿 GAME SETTINGS 🌿"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 5)
	vbox.add_child(title)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 3)
	divider.color = Color(0.9, 0.63, 0.27, 0.8)
	vbox.add_child(divider)
	
	var master_idx = AudioServer.get_bus_index("Master")
	var bgm_idx = AudioServer.get_bus_index("BGM")
	if bgm_idx == -1: bgm_idx = master_idx
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx == -1: sfx_idx = master_idx
	
	vbox.add_child(_create_volume_slider("🔊 Master Volume", master_idx))
	vbox.add_child(_create_volume_slider("🎵 Music / BGM Volume", bgm_idx))
	vbox.add_child(_create_volume_slider("🔔 SFX Volume", sfx_idx))
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = "CLOSE SETTINGS"
	close_btn.custom_minimum_size = Vector2(0, 42)
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.82, 0.35, 0.12)
	close_style.border_color = Color(0.98, 0.8, 0.4)
	close_style.set_border_width_all(2)
	close_style.set_corner_radius_all(8)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.add_theme_font_size_override("font_size", 14)
	
	close_btn.pressed.connect(func():
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("click")
		canvas_layer.queue_free()
	)
	vbox.add_child(close_btn)
	
	canvas_layer.add_child(settings_ui)
	get_tree().current_scene.add_child(canvas_layer)

func _create_volume_slider(label_text: String, bus_idx: int) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	
	var hbox = HBoxContainer.new()
	
	var name_lbl = Label.new()
	name_lbl.text = label_text
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_lbl)
	
	var current_vol_db = AudioServer.get_bus_volume_db(bus_idx)
	var current_pct = int(db_to_linear(current_vol_db) * 100)
	
	var val_lbl = Label.new()
	val_lbl.text = str(current_pct) + "%"
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.add_theme_color_override("font_color", Color(0.5, 0.95, 0.5))
	hbox.add_child(val_lbl)
	
	container.add_child(hbox)
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = db_to_linear(current_vol_db)
	
	slider.value_changed.connect(func(val: float):
		var db = linear_to_db(val)
		AudioServer.set_bus_volume_db(bus_idx, db)
		AudioServer.set_bus_mute(bus_idx, val <= 0.001)
		val_lbl.text = str(int(val * 100)) + "%"
		
		if label_text.contains("SFX") and has_node("/root/AudioManager"):
			AudioManager.play_sfx("click")
	)
	
	container.add_child(slider)
	return container
