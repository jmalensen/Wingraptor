extends Node2D

signal game_over
signal pause
signal resume
signal change_effects_sound(value)

@export var world_speed = 300
@export var collectible_pitch_reset_interval = 2000

@onready var moving_environment = $"/root/World/Environment/Moving"
@onready var collect_sound = $"/root/World/Sounds/CollectSound"
@onready var score_label = $"/root/World/HUD/UI/Score"
@onready var player = $"/root/World/Player"
@onready var ground = $"/root/World/Environment/Static/Ground"
@onready var game_over_label = $"/root/World/HUD/UI/GameOver"
@onready var black_bg = $"/root/World/HUD/UI/BlackBg"
@onready var exit_button = $"/root/World/HUD/UI/ExitButton"
@onready var ammo_label = $"/root/World/HUD/UI/Ammo"
@onready var pause_label = $"/root/World/HUD/UI/Pause"
@onready var check_music_button = $"/root/World/HUD/UI/MusicCheck"
@onready var check_effects_button = $"/root/World/HUD/UI/EffectsCheck"

var platform = preload("res://scenes/platform.tscn")
var platform_collectible_single = preload("res://scenes/platform_collectible_single.tscn")
var platform_collectible_row = preload("res://scenes/platform_collectible_row.tscn")
var platform_collectible_rainbow = preload("res://scenes/platform_collectible_rainbow.tscn")
var platform_enemy = preload("res://scenes/platform_enemy.tscn")
var platform_plant = preload("res://scenes/platform_plant.tscn")
var platform_collectible_ammo = preload("res://scenes/platform_collectible_ammo.tscn")

@onready var music_node = get_node("/root/Music/AudioStreamPlayer")

var rng = RandomNumberGenerator.new()
var last_platform_position = Vector2.ZERO
var next_spawn_time = 0
var score = 0
var collectible_pitch = 1.0
var reset_collectible_pitch_time = 0
var pause_status = false
var sounds_effects_enabled = true

#Called when the node enters the scene tree for the first time
func _ready() -> void:
	rng.randomize()
	player.player_died.connect(_on_player_died)
	ground.body_entered.connect(_on_ground_body_entered)
	check_music_button.toggled.connect(_on_checkmusic_toggled)
	check_effects_button.toggled.connect(_on_checkeffects_toggled)
	exit_button.pressed.connect(_on_exit_button_pressed)
	
#Called every frame. Delta is the elapsed time since the previous
func _process(delta: float) -> void:
	
	#Handling player not active (died or pause)
	if not player.active and not pause_status:
		#Reload the game if we are not player and the user hit space
		if Input.is_action_just_pressed("jump"):
			get_tree().reload_current_scene()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return
		
	#Handling pause/resume menu
	if Input.is_action_just_pressed("pause"):
		black_bg.set_visible(!black_bg.is_visible())
		pause_label.set_visible(!pause_label.is_visible())
		check_music_button.set_visible(!check_music_button.is_visible())
		check_effects_button.set_visible(!check_effects_button.is_visible())
		pause_status = !pause_status

	if pause_status and player.active:
		emit_signal("pause")
		exit_button.set_visible(true)
		# Show mouse
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	elif not pause_status and not player.active:
		emit_signal("resume")
		exit_button.set_visible(false)
		# Hide mouse
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	#Reset the collectible sound pitch after a time
	if Time.get_ticks_msec() > reset_collectible_pitch_time:
		collectible_pitch = 1.0
	
	#Spawn new platform
	if Time.get_ticks_msec() > next_spawn_time:
		_spawn_next_platform()
		
	#Update the UI labels
	score_label.text = "Score: %s" % score
	ammo_label.text = "Ammo: %s" % player.ammo
		
func _spawn_next_platform() -> void:
	var available_platforms = [
		platform,
		platform_collectible_single,
		platform_collectible_row,
		platform_collectible_rainbow,
		platform_enemy,
		platform_plant,
		platform_collectible_ammo
	]
	var random_platform = available_platforms.pick_random()
	var new_platform = random_platform.instantiate()
		
	#Set the position of the new platform
	if last_platform_position == Vector2.ZERO:
		new_platform.position = Vector2(400, 0)
	else:
		var x = last_platform_position.x + rng.randi_range(450, 660)
		var y = clamp(last_platform_position.y + rng.randi_range(-200, 150), 200, 900)
		new_platform.position = Vector2(x, y)
		
	#Add the platform to the moving environment
	moving_environment.add_child(new_platform)
	
	#Update the last platform position and increase the next spawn
	last_platform_position = new_platform.position
	next_spawn_time += world_speed

func _physics_process(delta: float) -> void:
	if not player.active:
		return
	
	#Move the platform to the left
	moving_environment.position.x -= world_speed * delta
	
	#Increase world speed as game progress
	world_speed += 1 * delta

#Handle score
func add_score(value: int) -> void:
	score += value
	collect_sound.set_pitch_scale(collectible_pitch)
	if sounds_effects_enabled:
		collect_sound.play()
	collectible_pitch += 0.1
	reset_collectible_pitch_time = Time.get_ticks_msec() + collectible_pitch_reset_interval

func _on_player_died() -> void:
	emit_signal("game_over")
	game_over_label.text = game_over_label.text % score
	game_over_label.set_visible(true)
	black_bg.set_visible(true)
	exit_button.set_visible(true)
	
func _on_ground_body_entered(body) -> void:
	if body.is_in_group("player"):
		player.die()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

#Handle music enabled or not
func _on_checkmusic_toggled(p_state) -> void:
	if p_state and not music_node.playing:
		music_node.play()
	else:
		music_node.stop()

#Handle effects sounds enabled or not
func _on_checkeffects_toggled(p_state) -> void:
	if p_state and not sounds_effects_enabled:
		sounds_effects_enabled = true
		#Need a signal to enable effects sound
		change_effects_sound.emit(true)
		pass
	else:
		sounds_effects_enabled = false
		#Need a signal to shut down effects sound
		change_effects_sound.emit(false)
		pass
