extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var sensitivity = 0.003
var onCooldown = false

var gold = 0
var hp = 50
var maxHP = 50
var damage = 10

var targets = []

@onready var camera =  $Camera3D
@onready var animationPlayer = $AnimationPlayer
@onready var cooldown = $AttackCooldown
@onready var hpBar = $HUD/HPBar
@onready var goldLabel = $HUD/GoldLabel

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
func _ready() -> void:
	hpBar.max_value = maxHP
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(70))

func attack():
	if Input.is_action_just_pressed("attack") and onCooldown == false:
		animationPlayer.play("PlayerLibrary/WeaponSwing")
		onCooldown = true
		cooldown.start()

func deal_damage():
	print(targets)
	for x in targets:
		print(x.hp)
		x.hp -= damage

func _process(delta: float) -> void:
	update_hud()
	attack()
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()

func _on_attack_cooldown_timeout() -> void:
	onCooldown = false

func update_hud() -> void:
	hpBar.value = hp
	goldLabel.text = str(gold) + " Gold"

# Just to check if they're a player
func player():
	pass


func _on_attack_zone_body_entered(body: Node3D) -> void:
	if body.has_method("enemy"):
		targets.append(body)
	


func _on_attack_zone_body_exited(body: Node3D) -> void:
	if body.has_method("enemy"):
		targets.erase(body)
