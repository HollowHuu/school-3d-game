extends Control

var player: Node = null

# Each upgrade is a dictionary — easy to extend
var upgrades := [
	{
		"name": "Sharp Sword",
		"description": "+5 damage",
		"cost": 50,
		"action": func(p): p.damage += 5
	},
	{
		"name": "Iron Skin",
		"description": "+25 max HP",
		"cost": 75,
		"action": func(p):
	p.max_hp += 25
	p.hp += 25
	p.hp_bar.max_value = p.max_hp
	},
	{
		"name": "Speed Boots",
		"description": "+2 move speed",
		"cost": 60,
		"action": func(p): p.SPEED += 2  # Make SPEED a var instead of const
	},
	{
		"name": "Full Heal",
		"description": "Restore all HP",
		"cost": 40,
		"action": func(p): p.hp = p.max_hp
	},
]

@onready var item_container: VBoxContainer = $VBoxContainer/ItemContainer
@onready var gold_label: Label = $VBoxContainer/GoldLabel
@onready var close_button: Button = $VBoxContainer/CloseButton


func open(p: Node) -> void:
	player = p
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_populate_shop()
	_refresh_gold()


func _populate_shop() -> void:
	# Clear old buttons first
	for child in item_container.get_children():
		child.queue_free()

	for upgrade in upgrades:
		var btn := Button.new()
		btn.text = "%s — %d Gold\n%s" % [upgrade["name"], upgrade["cost"], upgrade["description"]]
		btn.pressed.connect(_on_upgrade_pressed.bind(upgrade))
		item_container.add_child(btn)


func _on_upgrade_pressed(upgrade: Dictionary) -> void:
	if player.gold >= upgrade["cost"]:
		player.gold -= upgrade["cost"]
		upgrade["action"].call(player)
		_refresh_gold()
		_populate_shop()  # Refresh so you could grey out unaffordable items later


func _refresh_gold() -> void:
	gold_label.text = "Gold: %d" % player.gold


func _on_close_pressed() -> void:
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
