extends Node2D

signal game_over
signal pause
signal resume

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

var platform = preload("res://scenes/platform.tscn")
var platform_collectible_single = preload("res://scenes/platform_collectible_single.tscn")
var platform_collectible_row = preload("res://scenes/platform_collectible_row.tscn")
var platform_collectible_rainbow = preload("res://scenes/platform_collectible_rainbow.tscn")
var platform_enemy = preload("res://scenes/platform_enemy.tscn")
var platform_collectible_ammo = preload("res://scenes/platform_collectible_ammo.tscn")

var rng = RandomNumberGenerator.new()
var last_platform_position = Vector2.ZERO
var next_spawn_time = 0
var score = 0
var collectible_pitch = 1.0
var reset_collectible_pitch_time = 0
var pause_status = false

#Called when the node enters the scene tree for the first time
func _ready() -> void:
	rng.randomize()
	player.player_died.connect(_on_player_died)
	ground.body_entered.connect(_on_ground_body_entered)
	
#Called every frame. Delta is the elapsed time since the previous
func _process(delta: float) -> void:
	if not player.active:
		#Reload the game if we are not player and the user hit space
		if Input.is_action_just_pressed("jump"):
			get_tree().reload_current_scene()
		return
	#else:
	#	if Input.is_action_just_pressed("pause"):
	#		black_bg.set_visible(!black_bg.is_visible())
	#		pause_label.set_visible(!pause_label.is_visible())
	#		pause_status = !pause_status
			
	#	if pause_status:
	#		emit_signal("pause")
	#	else:
	#		emit_signal("resume")
		
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
		platform_collectible_ammo
	]
	var random_platform = available_platforms.pick_random()
	var new_platform = random_platform.instantiate()
		
	#Set the position of the new platform
	if last_platform_position == Vector2.ZERO:
		new_platform.position = Vector2(400, 0)
	else:
		var x = last_platform_position.x + rng.randi_range(550, 800)
		var y = clamp(last_platform_position.y + rng.randi_range(-200, 200), 200, 1000)
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
	#print(world_speed, " ", Time.get_datetime_string_from_system() )

#Handle score
func add_score(value: int) -> void:
	score += value
	collect_sound.set_pitch_scale(collectible_pitch)
	collect_sound.play()
	collectible_pitch += 0.1
	reset_collectible_pitch_time = Time.get_ticks_msec() + collectible_pitch_reset_interval

func _on_player_died() -> void:
	emit_signal("game_over")
	game_over_label.text = game_over_label.text % score
	game_over_label.set_visible(true)
	black_bg.set_visible(true)
	exit_button.set_visible(true)
	exit_button.pressed.connect(_on_exit_button_pressed)
	
func _on_ground_body_entered(body) -> void:
	if body.is_in_group("player"):
		player.die()

func _on_exit_button_pressed() -> void:
	get_tree().quit()
