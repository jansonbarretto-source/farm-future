extends TextureButton

const SETTINGS_ICON_PATH = "res://Settings button.png"
const HOW_TO_PLAY_IMAGE_PATH = "res://images/How To Play.png"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	position = Vector2(20, 85)
	custom_minimum_size = Vector2(40, 40)
	
	if ResourceLoader.exists(SETTINGS_ICON_PATH):
		texture_normal = load(SETTINGS_ICON_PATH)
		ignore_texture_size = true
		stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	else:
		print("[WARNING] Settings icon texture not found at: ", SETTINGS_ICON_PATH)
	
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			var existing_settings = get_tree().root.get_node_or_null("SettingsLayer")
			var existing_htp = get_tree().root.get_node_or_null("HowToPlayLayer")
			
			if existing_htp:
				if has_node("/root/AudioManager"):
					AudioManager.play_sfx("click")
				existing_htp.queue_free()
				get_viewport().set_input_as_handled()
			elif existing_settings:
				if has_node("/root/AudioManager"):
					AudioManager.play_sfx("click")
				existing_settings.queue_free()
				get_viewport().set_input_as_handled()
			else:
				_on_pressed()
				get_viewport().set_input_as_handled()

func _on_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("open")
		
	var existing_settings = get_tree().root.get_node_or_null("SettingsLayer")
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
	panel.custom_minimum_size = Vector2(360, 350)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.11, 0.07, 0.98)
	style.border_color = Color(0.9, 0.63, 0.27, 1.0)
	style.set_border_width_all(4)
	style.border_width_top = 6
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color(0, 0, 0, 0.85)
	style.shadow_size = 14
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "GAME SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 4)
	vbox.add_child(title)
	
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.9, 0.63, 0.27, 0.8)
	vbox.add_child(divider)
	
	var master_idx = AudioServer.get_bus_index("Master")
	var bgm_idx = AudioServer.get_bus_index("BGM")
	if bgm_idx == -1: bgm_idx = master_idx
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx == -1: sfx_idx = master_idx
	
	vbox.add_child(_create_volume_slider("Master Volume", master_idx))
	vbox.add_child(_create_volume_slider("Music / BGM Volume", bgm_idx))
	vbox.add_child(_create_volume_slider("SFX Volume", sfx_idx))
	
	# --- CLOSE SETTINGS BUTTON ---
	var close_btn = Button.new()
	close_btn.text = "CLOSE SETTINGS"
	close_btn.custom_minimum_size = Vector2(0, 30)
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.82, 0.35, 0.12)
	close_style.border_color = Color(0.98, 0.8, 0.4)
	close_style.set_border_width_all(2)
	close_style.set_corner_radius_all(6)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.add_theme_font_size_override("font_size", 11)
	
	close_btn.pressed.connect(func():
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("click")
		canvas_layer.queue_free()
	)
	vbox.add_child(close_btn)
	
	# --- HOW TO PLAY BUTTON ---
	var how_to_play_btn = Button.new()
	how_to_play_btn.text = "HOW TO PLAY"
	how_to_play_btn.custom_minimum_size = Vector2(0, 30)
	how_to_play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var htp_style = StyleBoxFlat.new()
	htp_style.bg_color = Color(0.25, 0.55, 0.75)
	htp_style.border_color = Color(0.8, 0.9, 1.0)
	htp_style.set_border_width_all(2)
	htp_style.set_corner_radius_all(6)
	how_to_play_btn.add_theme_stylebox_override("normal", htp_style)
	how_to_play_btn.add_theme_color_override("font_color", Color.WHITE)
	how_to_play_btn.add_theme_font_size_override("font_size", 11)
	
	how_to_play_btn.pressed.connect(func():
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("click")
		_show_how_to_play_panel()
	)
	vbox.add_child(how_to_play_btn)
	
	# --- QUIT GAME BUTTON ---
	var quit_btn = Button.new()
	quit_btn.text = "QUIT GAME"
	quit_btn.custom_minimum_size = Vector2(0, 30)
	quit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var quit_style = StyleBoxFlat.new()
	quit_style.bg_color = Color(0.65, 0.15, 0.15)
	quit_style.border_color = Color(0.95, 0.5, 0.5)
	quit_style.set_border_width_all(2)
	quit_style.set_corner_radius_all(6)
	quit_btn.add_theme_stylebox_override("normal", quit_style)
	quit_btn.add_theme_color_override("font_color", Color.WHITE)
	quit_btn.add_theme_font_size_override("font_size", 11)
	
	quit_btn.pressed.connect(func():
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("click")
		
		var menu_path = "res://scenes/Main_Menu.tscn"
		if ResourceLoader.exists(menu_path):
			get_tree().change_scene_to_file(menu_path)
		else:
			print("[ERROR] Main Menu scene not found at: ", menu_path)
	)
	vbox.add_child(quit_btn)
	
	canvas_layer.add_child(settings_ui)
	get_tree().root.add_child(canvas_layer)

# --- IPAPALABAS ANG HOW TO PLAY IMAGE PANEL GAMIT ANG CODE ---
func _show_how_to_play_panel() -> void:
	var htp_layer = CanvasLayer.new()
	htp_layer.name = "HowToPlayLayer"
	htp_layer.layer = 130 # Mas mataas kaysa settings para lumitaw sa ibabaw
	
	var ui_control = Control.new()
	ui_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.03, 0.02, 0.8)
	bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			htp_layer.queue_free()
	)
	ui_control.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_control.add_child(center)
	
	var texture_rect = TextureRect.new()
	if ResourceLoader.exists(HOW_TO_PLAY_IMAGE_PATH):
		texture_rect.texture = load(HOW_TO_PLAY_IMAGE_PATH)
	else:
		print("[WARNING] How To Play image not found at: ", HOW_TO_PLAY_IMAGE_PATH)
		
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.custom_minimum_size = Vector2(600, 400)
	center.add_child(texture_rect)
	
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(35, 35)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -60
	close_btn.offset_top = 30
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.8, 0.2, 0.2)
	btn_style.set_corner_radius_all(6)
	close_btn.add_theme_stylebox_override("normal", btn_style)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	
	close_btn.pressed.connect(func():
		if has_node("/root/AudioManager"):
			AudioManager.play_sfx("click")
		htp_layer.queue_free()
	)
	
	ui_control.add_child(close_btn)
	htp_layer.add_child(ui_control)
	get_tree().root.add_child(htp_layer)

func _create_volume_slider(label_text: String, bus_idx: int) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 1)
	
	var hbox = HBoxContainer.new()
	
	var name_lbl = Label.new()
	name_lbl.text = label_text
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_lbl)
	
	var current_vol_db = AudioServer.get_bus_volume_db(bus_idx)
	var current_pct = int(db_to_linear(current_vol_db) * 100)
	
	var val_lbl = Label.new()
	val_lbl.text = str(current_pct) + "%"
	
	# Ayos na ang void return error dito
	if val_lbl.has_method("add_font_size_override"):
		val_lbl.add_font_size_override("font_size", 11)
	else:
		val_lbl.add_theme_font_size_override("font_size", 11)
		
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
