extends CharacterBody2D

@export var gravity = 1600
@export var jump_power = 500

@onready var sprite = $AnimatedSprite2D
@onready var jump_sound = $JumpSound
@onready var camera = $"/root/World/Camera2D"

var active = true
var jump_remaining = 2
var was_jumping = false
var jump_pitch = 1.0

func _ready() -> void:
	print("player start moving")

func _physics_process(delta: float) -> void:
	
	if active:
		#Update the camera position
		camera.position = position
		
		#Reset player after landing
		if was_jumping and is_on_floor():
			was_jumping = false
			jump_remaining = 2
			sprite.play("run")
			jump_pitch = 1.0
		
		#Handle jumping
		if Input.is_action_just_pressed("jump") and jump_remaining > 0:
			jump_remaining -= 1
			was_jumping = true
			velocity.y = -jump_power
			
			if jump_remaining == 1:
				sprite.play("jump")
			else:
				sprite.play("double jump")
				
			jump_sound.set_pitch_scale(jump_pitch)
			jump_sound.play()
			jump_pitch += 0.2
		
		#Handle floating
		elif Input.is_action_pressed("jump") and !is_on_floor() and jump_remaining == 0:
			sprite.play("float")
			velocity.y += (gravity * delta) * 0.5
		else:
			velocity.y += gravity * delta
		
	move_and_slide()
