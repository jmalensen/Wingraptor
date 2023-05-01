extends CharacterBody2D

class_name EntityEnemy

@export var movement_speed = 50

@onready var sprite = $AnimatedSprite2D
@onready var collisionshape = $CollisionShape2D
@onready var hitbox = $Hitbox
@onready var player = $"/root/World/Player"
@onready var death_sound = $DeathSound
@onready var game = $"/root/World/"

var active = false
var gravity = 1600
var visible_on_screen = false
var effects_sound_enabled = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hitbox.body_entered.connect(_on_body_entered)
	player.player_died.connect(_on_player_died)

	game.pause.connect(_on_pause)
	game.resume.connect(_on_resume)
	
	game.change_effects_sound.connect(_on_change_effects_sounds)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not active:
		return

	velocity.x = -movement_speed
	velocity.y = gravity * delta
	move_and_slide()

func set_active(value: bool) -> void:
	active = value
	visible_on_screen = true
	if active:
		sprite.play("walk")

func _on_body_entered(body) -> void:
	
	# Get the position of the player and the enemy
	var player_pos = player.global_position
	var enemy_pos = sprite.global_position

#	# Kill from jump on it (+6.0 is for the hitbox of the player to be correctly placed)
#	if ((player_pos.y+16.0) < enemy_pos.y) and player.was_jumping:
#
#		die()
#		return
		
	if body.is_in_group("player") and active:
		player.die()

func _on_player_died() -> void:
	set_active(false)
	sprite.play("idle")

func die() -> void:
	if effects_sound_enabled:
		death_sound.play()
	sprite.play("death")
	active = false
	sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	queue_free()

func _on_pause() -> void:
	active = false

func _on_resume() -> void:
	if visible_on_screen:
		active = true

func _on_change_effects_sounds(value) -> void:
	effects_sound_enabled = value
