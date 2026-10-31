extends Control

# Audio Bus Names (Tiyaking may Master, BGM, at SFX buses o gagamit ito ng Master bilang fallback)
var master_bus_idx: int = 0
var bgm_bus_idx: int = -1
var sfx_bus_idx: int = -1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_detect_audio_buses()
	_build_settings_ui()
	
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("open")

func _detect_audio_buses() -> void:
	master_bus_idx = AudioServer.get_bus_index("Master")
	bgm_bus_idx = AudioServer.get_bus_index("BGM")
	sfx_bus_idx = AudioServer.get_bus_index("SFX")
	
	# Fallback sa Master bus kung wala pang nakahandang hiwalay na BGM/SFX bus
	if bgm_bus_idx == -1:
		bgm_bus_idx = master_bus_idx
	if sfx_bus_idx == -1:
		sfx_bus_idx = master_bus_idx

func _close_panel() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("click")
		
	if get_parent() is CanvasLayer:
		get_parent().queue_free()
	else:
		queue_free()

func _build_settings_ui() -> void:
	for child in get_children():
		child.queue_free()
		
	# Dark Overlay Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_close_panel()
	)
	add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# Settings Main Panel Container
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 320)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.98)
	style.border_color = Color(0.85, 0.65, 0.3, 1.0)
	style.set_border_width_all(4)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.shadow_color = Color(0, 0, 0, 0.8)
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "⚙️ AUDIO SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 4)
	vbox.add_child(title)
	
	# Line Divider
	var divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.85, 0.65, 0.3, 0.8)
	vbox.add_child(divider)
	
	# Audio Volume Sliders
	vbox.add_child(_create_volume_slider("Master Volume", master_bus_idx))
	vbox.add_child(_create_volume_slider("BGM Volume", bgm_bus_idx))
	vbox.add_child(_create_volume_slider("SFX Volume", sfx_bus_idx))
	
	# Close Button
	var close_btn = Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(0, 36)
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.7, 0.2, 0.15)
	close_style.set_corner_radius_all(6)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	
	close_btn.pressed.connect(_close_panel)
	vbox.add_child(close_btn)

func _create_volume_slider(label_text: String, bus_idx: int) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	
	var hbox = HBoxContainer.new()
	
	var name_lbl = Label.new()
	name_lbl.text = label_text
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_lbl)
	
	var current_vol_db = AudioServer.get_bus_volume_db(bus_idx)
	var current_pct = int(db_to_linear(current_vol_db) * 100)
	
	var val_lbl = Label.new()
	val_lbl.text = str(current_pct) + "%"
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
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
		
		if label_text == "SFX Volume" and has_node("/root/AudioManager"):
			AudioManager.play_sfx("click")
	)
	
	container.add_child(slider)
	return container

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
			_close_panel()
