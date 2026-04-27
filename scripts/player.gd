extends CharacterBody3D

var SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

var on_cooldown := false
var gold := 0
var hp := 50
var max_hp := 50
var damage := 10
var targets: Array[Node3D] = []

@onready var camera: Camera3D = $Camera3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var hp_bar: TextureProgressBar = $HUD/HPBar
@onready var gold_label: Label = $HUD/GoldLabel
@onready var shop = $Control


func _ready() -> void:
	hp_bar.max_value = max_hp
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(70))

	if event.is_action_pressed("escape"):
		get_tree().quit()

	if event.is_action_pressed("attack") and not on_cooldown:
		_attack()
	
	if event.is_action_pressed("shop"):
		if shop.visible:
			shop.hide()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			shop.open(self)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _process(_delta: float) -> void:
	_update_hud()
	# Kill the enemy if hp drops to 0 or below
	if hp <= 0:
		die()


func _attack() -> void:
	animation_player.play("PlayerLibrary/WeaponSwing")
	on_cooldown = true
	attack_cooldown.start()
	_deal_damage()


func _deal_damage() -> void:
	for target in targets:
		target.hp -= damage


func _update_hud() -> void:
	hp_bar.value = hp
	gold_label.text = "%d Gold" % gold


func die() -> void:
	# Placeholder — add game-over logic here
	get_tree().quit()


# Used as a duck-typing tag so enemies can detect this node as a player
func is_player() -> bool:
	return true


func _on_attack_cooldown_timeout() -> void:
	on_cooldown = false


func _on_attack_zone_body_entered(body: Node3D) -> void:
	if body.has_method("is_enemy"):
		targets.append(body)


func _on_attack_zone_body_exited(body: Node3D) -> void:
	if body.has_method("is_enemy"):
		targets.erase(body)
