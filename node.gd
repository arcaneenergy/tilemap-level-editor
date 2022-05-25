extends Node

onready var _camera: Camera2D = $Node2D/Camera2D
onready var _tm: TileMap = $Node2D/TileMap
onready var _cl: CanvasLayer = $CanvasLayer
onready var _ts_container: Control = $"%TilesetContainer"
onready var _layers: Control = $"%Layers"
onready var _fd_import: FileDialog = $"%FileDialogImportJson"
onready var _fd_export: FileDialog = $"%FileDialogExportJson"

var _initial_drag_pos: Vector2

const CAMERA_MOVE_SPEED := 100

func _process(delta: float) -> void:
	if Input.is_action_pressed("move_up"):
		_camera.position.y -= CAMERA_MOVE_SPEED * delta

	if Input.is_action_pressed("move_down"):
		_camera.position.y += CAMERA_MOVE_SPEED * delta

	if Input.is_action_pressed("move_left"):
		_camera.position.x -= CAMERA_MOVE_SPEED * delta

	if Input.is_action_pressed("move_right"):
		_camera.position.x += CAMERA_MOVE_SPEED * delta

	if Input.is_action_pressed("drag"):
		_camera.position += _initial_drag_pos - _tm.get_global_mouse_position()

func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_pressed("place"):
		var pos = _tm.get_global_mouse_position() / 16
		_tm.set_cell(pos.x, pos.y, 0)

	if Input.is_action_pressed("delete"):
		var pos = _tm.get_global_mouse_position() / 16
		_tm.set_cell(pos.x, pos.y, -1)

	if Input.is_action_just_pressed("toggle_gui"):
		_cl.visible = !_cl.visible

	if Input.is_action_just_pressed("drag"):
		_initial_drag_pos = _tm.get_global_mouse_position()

	if Input.is_action_just_pressed("zoom_in"):
		_camera.zoom -= Vector2.ONE * 0.01

	if Input.is_action_just_pressed("zoom_out"):
		_camera.zoom += Vector2.ONE * 0.01

func _on_ButtonNewLayer_pressed() -> void:
	pass # Replace with function body.

func _on_ButtonImport_pressed() -> void:
	pass # Replace with function body.

func _on_ButtonExport_pressed() -> void:
	pass # Replace with function body.

func _on_FileDialogImportJson_file_selected(path: String) -> void:
	pass # Replace with function body.

func _on_FileDialogExportJson_file_selected(path: String) -> void:
	pass # Replace with function body.
