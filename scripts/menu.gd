extends VBoxContainer

@onready var start_button = $StartButton
@onready var exit_button = $ExitButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	
	# Lock the mouse inside the screen of the game but stay visible
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_on_start_button_pressed()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	# Hide the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _on_exit_button_pressed() -> void:
	get_tree().quit()
