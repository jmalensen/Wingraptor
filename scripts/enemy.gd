extends CharacterBody2D

@export var movement_speed = 50

@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $Hitbox
@onready var player = $"/root/World/Player"
@onready var death_sound = $DeathSound

var active = false
var gravity = 1600

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hitbox.body_entered.connect(_on_body_entered)
	player.player_died.connect(_on_player_died)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not active:
		return

	velocity.x = -movement_speed
	velocity.y = gravity * delta
	move_and_slide()

func set_active(value: bool) -> void:
	active = value
	if active:
		sprite.play("walk")

func _on_body_entered(body) -> void:
	if body.is_in_group("player") and active:
		player.die()

func _on_player_died() -> void:
	set_active(false)
	sprite.play("idle")

func die() -> void:
	death_sound.play()
	sprite.play("death")
	active = false
	sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	queue_free()
