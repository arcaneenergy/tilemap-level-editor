extends Node2D

onready var _camera: Camera2D = $"%Camera2D"
onready var _tm_container: Node2D = $"%Tilemaps"
onready var _cl: CanvasLayer = $CanvasLayer
onready var _ts_container: Control = $"%TilesetContainer"
onready var _layer_container: Control = $"%Layers"
onready var _fd_import: FileDialog = $"%FileDialogImportJson"
onready var _fd_export: FileDialog = $"%FileDialogExportJson"
onready var _fd_new_layer: FileDialog = $"%FileDialogNewLayer"
onready var _grid: Sprite = $Grid
onready var _lbl_position: Label = $"%LabelPosition"
onready var _cursor: Sprite = $"%Cursor"

var _initial_drag_pos: Vector2
var _layers := {}
var _current_layer := ""
var _selected_tile := -1

const CAMERA_MOVE_SPEED := 100

func _process(delta: float) -> void:
	if Input.is_action_pressed("move_up"):
		_camera.position.y -= CAMERA_MOVE_SPEED * _camera.zoom.x * delta

	if Input.is_action_pressed("move_down"):
		_camera.position.y += CAMERA_MOVE_SPEED * _camera.zoom.x * delta

	if Input.is_action_pressed("move_left"):
		_camera.position.x -= CAMERA_MOVE_SPEED * _camera.zoom.x * delta

	if Input.is_action_pressed("move_right"):
		_camera.position.x += CAMERA_MOVE_SPEED * _camera.zoom.x * delta

	if Input.is_action_pressed("drag"):
		_camera.position += _initial_drag_pos - get_global_mouse_position()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("drag"):
		_initial_drag_pos = get_global_mouse_position()

	if Input.is_action_just_pressed("toggle_gui"):
		_cl.visible = !_cl.visible

	if Input.is_action_just_pressed("zoom_in"):
		_camera.zoom = Vector2.ONE * clamp(_camera.zoom.x - 0.05, 0.01, 4.0)

	if Input.is_action_just_pressed("zoom_out"):
		_camera.zoom = Vector2.ONE * clamp(_camera.zoom.x + 0.05, 0.01, 4.0)

	var mouse_pos = get_global_mouse_position() / 64
	var place_pos := Vector2(floor(mouse_pos.x), floor(mouse_pos.y))
	_cursor.position = place_pos * 64 + Vector2.ONE * 32
	_lbl_position.text = str(place_pos)

	if _current_layer.empty(): return

	if Input.is_action_pressed("place"):
		_layers[_current_layer]["tm"].set_cellv(place_pos, _selected_tile)

	if Input.is_action_pressed("delete"):
		_layers[_current_layer]["tm"].set_cellv(place_pos, -1)

func _on_ButtonNewLayer_pressed() -> void:
	_fd_new_layer.popup()

func _on_Layer_toggled(button_pressed: bool, layer: Control) -> void:
	for i in _layer_container.get_children():
		i.get_node("MarginContainer/VBoxContainer/HBoxContainer/CheckBox").set_pressed_no_signal(false)
	layer.get_node("MarginContainer/VBoxContainer/HBoxContainer/CheckBox").set_pressed_no_signal(true)

	_clear_ts_container()

	var img_tex := _layers[layer.get_meta("path")]["tex"] as ImageTexture
	var idx := 0
	for x in range(img_tex.get_width() / 16):
		for y in range(img_tex.get_height() / 16):
			var btn := TextureButton.new()
			btn.focus_mode = Control.FOCUS_NONE
			btn.expand = true
			btn.rect_min_size = Vector2.ONE * 64
			btn.connect("pressed", self, "_on_TextureButton_pressed", [idx])
			var at := AtlasTexture.new()
			at.atlas = img_tex
			at.region = Rect2(x * 16, y * 16, 16, 16)
			btn.texture_normal = at
			_ts_container.add_child(btn)
			idx += 1

	_current_layer = layer.get_meta("path")
#	_update_cell_size()

func _on_TextureButton_pressed(idx: int) -> void:
	_selected_tile = idx

func _on_Layer_moved_up(layer: Control) -> void:
	if layer.get_index() - 1 >= 0:
		var new_idx := layer.get_index() - 1
		_layer_container.move_child(layer, new_idx)
		_tm_container.move_child(_layers[layer.get_meta("path")]["tm"], new_idx)
	_update_layers()

func _on_Layer_moved_down(layer: Control) -> void:
	if layer.get_index() + 1 < _layer_container.get_child_count():
		var new_idx := layer.get_index() + 1
		_layer_container.move_child(layer, new_idx)
		_tm_container.move_child(_layers[layer.get_meta("path")]["tm"], new_idx)
	_update_layers()

func _update_layers() -> void:
	var i := 1
	for l in _layer_container.get_children():
		l.get_node("LabelIndex").text = "#%d" % i
		i += 1

func _clear_ts_container() -> void:
	for i in _ts_container.get_children():
		i.queue_free()

func _on_Layer_deleted(layer: Control) -> void:
	_clear_ts_container()
	_layers[layer.get_meta("path")]["tm"].queue_free()
	_layer_container.remove_child(layer)
	_layers.erase(layer.get_meta("path"))
	layer.queue_free()
	_update_layers()
	_current_layer = ""
	_selected_tile = -1

func _on_ButtonImport_pressed() -> void:
	_fd_import.popup()

func _on_ButtonExport_pressed() -> void:
	_fd_export.popup()
	_fd_export.current_file = "level.json"

func _on_FileDialogImportJson_file_selected(path: String) -> void:
	var file := File.new()
	file.open(path, File.READ)
	var text := file.get_as_text()

	var json_result := JSON.parse(text)
	if json_result.error == OK:
		for p in json_result.result:
			_create_layer(p["texture"])

			for c in p["cells"]:
				_layers[p["texture"]]["tm"].set_cell(c[1], c[2], c[0])

	file.close()

func _on_FileDialogExportJson_file_selected(path: String) -> void:
	var file := File.new()
	file.open(path, File.WRITE)

	var data := []
	for lay in _layers.keys():
		var a := {
			"texture": lay,
			"cells": [],
		}
		var tm: TileMap = _layers[lay]["tm"]
		for c in tm.get_used_cells():
			a["cells"].push_back([tm.get_cellv(c), c.x, c.y])
		data.push_back(a)

	file.store_string(JSON.print(data))
	file.close()

func _on_FileDialogNewLayer_file_selected(path: String) -> void:
	_create_layer(path)

func _create_layer(path: String) -> void:
	var layer := preload("res://layer.tscn").instance()
	layer.set_meta("path", path)
	layer.get_node("MarginContainer/VBoxContainer/HBoxContainer/CheckBox").connect("toggled", self, "_on_Layer_toggled", [layer])
	layer.get_node("MarginContainer/VBoxContainer/HBoxContainer/Name").text = path.get_file()
	layer.get_node("MarginContainer/VBoxContainer/HBoxContainer/ButtonUp").connect("pressed", self, "_on_Layer_moved_up", [layer])
	layer.get_node("MarginContainer/VBoxContainer/HBoxContainer/ButtonDown").connect("pressed", self, "_on_Layer_moved_down", [layer])
	layer.get_node("MarginContainer/VBoxContainer/HBoxContainer/ButtonDelete").connect("pressed", self, "_on_Layer_deleted", [layer])
#	layer.get_node("MarginContainer/VBoxContainer/HBoxContainer2/HSliderSize").connect("value_changed", self, "_on_HSliderSize_value_changed", [layer])

	_layer_container.add_child(layer)
	_update_layers()

	var file := File.new()
	file.open(path, File.READ)
	var buffer := file.get_buffer(file.get_len())
	var img := Image.new()
	var data
	if path.ends_with(".png"):
		data = img.load_png_from_buffer(buffer)
	elif path.ends_with(".jpg") or path.ends_with(".jpeg"):
		data = img.load_jpg_from_buffer(buffer)
	var img_tex := ImageTexture.new()
	img_tex.create_from_image(img, 1 | 2)
	file.close()

	var tm := TileMap.new()
	tm.cell_size = Vector2(16, 16)

	var ts := TileSet.new()
	var idx := 0
	for x in range(img_tex.get_width() / 16):
		for y in range(img_tex.get_height() / 16):
			var at := AtlasTexture.new()
			at.atlas = img_tex
			at.region = Rect2(x * 16, y * 16, 16, 16)
			ts.create_tile(idx)
			ts.tile_set_texture(idx, at)
			idx += 1

	tm.tile_set = ts

	tm.scale = Vector2.ONE * 4
	_tm_container.add_child(tm)

	_layers[path] = {
		"tex": img_tex,
		"tm": tm,
		"size": 16
	}
	_selected_tile = 0

	layer.get_node("MarginContainer/VBoxContainer/HBoxContainer/CheckBox").emit_signal("toggled", true)
#	_update_cell_size()

#func _on_HSliderSize_value_changed(value: float, layer: Control) -> void:
#	layer.get_node("MarginContainer/VBoxContainer/HBoxContainer2/HSliderSize/Label").text = str(value)
#	_layers[layer.get_meta("path")]["size"] = int(value)
#	_update_cell_size()

#func _update_cell_size() -> void:
#	var tm: TileMap = _layers[_current_layer]["tm"]
#	var size: int = _layers[_current_layer]["size"]
##	tm.cell_size = Vector2(size, size)
#	print(size)
##	tm.tile_set.
##	tm.scale = Vector2.ONE * size / 4
#	_grid.scale = Vector2.ONE * (size / 16)
