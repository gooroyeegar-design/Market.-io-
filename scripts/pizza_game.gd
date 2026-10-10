extends Node3D

const START_CASH := 65
const PIZZA_COST := 5
const PIZZA_PRICE := 14

var cash := START_CASH
var pizzas := 0
var sold := 0
var customers_served := 0
var tables := 0
var extra_ovens := 0
var workers := 0
var player: CharacterBody3D
var camera: Camera3D
var cash_label: Label
var stock_label: Label
var status_label: Label
var interact_button: Button
var movement := Vector2.ZERO
var customer_timer := 2.0
var sale_timer := 0.0
var upgrade_timer := 0.0
var customers: Array[Node3D] = []
var rng := RandomNumberGenerator.new()
var oven_pos := Vector3(-3.0, 0.0, -2.0)
var counter_pos := Vector3(3.0, 0.0, -2.0)
var shop_level := 1

func _ready() -> void:
	rng.randomize()
	_build_world()
	_build_player()
	_build_hud()
	_refresh_hud()
	_set_status("Welcome! Walk to the oven, cook a pizza, then serve a customer.")

func _process(delta: float) -> void:
	customer_timer -= delta
	sale_timer -= delta
	upgrade_timer -= delta
	if customer_timer <= 0.0 and customers.size() < 4:
		customer_timer = rng.randf_range(5.0, 8.0)
		_spawn_customer()
	if workers > 0 and sale_timer <= 0.0 and pizzas > 0:
		sale_timer = maxf(1.2, 4.0 / float(workers))
		_sell_pizza()
	_update_customers(delta)
	_update_camera(delta)
	_update_interaction_prompt()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var input_vec := Vector2.ZERO
	input_vec.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left") + movement.x
	input_vec.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up") + movement.y
	input_vec = input_vec.limit_length()
	var direction := Vector3(input_vec.x, 0.0, input_vec.y)
	player.velocity.x = direction.x * 5.0
	player.velocity.z = direction.z * 5.0
	if not player.is_on_floor():
		player.velocity.y -= 20.0 * delta
	else:
		player.velocity.y = 0.0
	player.move_and_slide()
	player.global_position.x = clampf(player.global_position.x, -8.2, 8.2)
	player.global_position.z = clampf(player.global_position.z, -5.8, 5.7)
	if direction.length() > 0.1:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(direction.x, direction.z), 0.2)

func _build_world() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.63, 0.72)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.92, 0.86, 0.75)
	env.ambient_light_energy = 0.8
	env_node.environment = env
	add_child(env_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	_box("Restaurant floor", Vector3(0, -0.25, 0), Vector3(18, 0.5, 13), Color(0.82, 0.69, 0.52))
	_box("Back wall", Vector3(0, 2.0, -6.4), Vector3(18, 4.5, 0.35), Color(0.98, 0.87, 0.70))
	_box("Left wall", Vector3(-8.9, 2, 0), Vector3(0.35, 4.5, 13), Color(0.95, 0.80, 0.63))
	_box("Right wall", Vector3(8.9, 2, 0), Vector3(0.35, 4.5, 13), Color(0.95, 0.80, 0.63))
	_box("Front teal awning", Vector3(0, 3.5, 6.15), Vector3(7.5, 0.25, 0.6), Color(0.13, 0.48, 0.43))
	_box("Front welcome mat", Vector3(0, 0.03, 5.5), Vector3(4.5, 0.06, 1.0), Color(0.16, 0.43, 0.37))
	_sign("PIZZA HOUSE", Vector3(0, 3.1, 5.93))
	_build_oven(oven_pos)
	_build_counter(counter_pos)
	_build_prep_table(Vector3(-3.0, 0, 1.0))
	_add_decor()

func _add_decor() -> void:
	for i in range(3):
		_box("Warm ceiling pendant", Vector3(-5.0 + i * 5.0, 3.7, -0.5), Vector3(0.12, 0.7, 0.12), Color(0.34, 0.25, 0.18), false)
		_sphere("Pendant glow", Vector3(-5.0 + i * 5.0, 3.25, -0.5), 0.22, Color(1.0, 0.76, 0.35))
	_box("Window left", Vector3(-7.0, 2.0, 6.0), Vector3(1.8, 1.6, 0.1), Color(0.48, 0.77, 0.82), false)
	_box("Window right", Vector3(7.0, 2.0, 6.0), Vector3(1.8, 1.6, 0.1), Color(0.48, 0.77, 0.82), false)

func _build_oven(pos: Vector3) -> void:
	_box("Brick oven base", pos + Vector3(0, 0.65, 0), Vector3(2.4, 1.3, 1.5), Color(0.69, 0.27, 0.17))
	_box("Oven dark mouth", pos + Vector3(0, 1.0, 0.79), Vector3(1.25, 0.65, 0.06), Color(0.12, 0.10, 0.09), false)
	_box("Oven fire", pos + Vector3(0, 0.98, 0.84), Vector3(0.45, 0.18, 0.04), Color(1.0, 0.43, 0.08), false)
	_box("Oven chimney", pos + Vector3(0.7, 1.75, -0.35), Vector3(0.35, 1.0, 0.35), Color(0.55, 0.23, 0.17))
	_box("Oven stone top", pos + Vector3(0, 1.34, 0), Vector3(2.5, 0.12, 1.6), Color(0.91, 0.73, 0.51))

func _build_counter(pos: Vector3) -> void:
	_box("Serving counter", pos + Vector3(0, 0.62, 0), Vector3(2.5, 1.24, 1.15), Color(0.36, 0.20, 0.13))
	_box("Counter marble", pos + Vector3(0, 1.28, 0), Vector3(2.65, 0.12, 1.25), Color(0.94, 0.84, 0.67))
	_box("Pizza display", pos + Vector3(0, 1.55, -0.15), Vector3(1.1, 0.35, 0.7), Color(0.20, 0.31, 0.28))
	_pizza(pos + Vector3(0, 1.78, -0.1), 0.38)

func _build_prep_table(pos: Vector3) -> void:
	_box("Prep table legs", pos + Vector3(0, 0.45, 0), Vector3(1.8, 0.9, 0.9), Color(0.48, 0.29, 0.18))
	_box("Prep table top", pos + Vector3(0, 0.94, 0), Vector3(1.95, 0.12, 1.0), Color(0.95, 0.82, 0.63))
	for i in range(3):
		_sphere("Tomato", pos + Vector3(-0.5 + i * 0.5, 1.08, 0.0), 0.13, Color(0.86, 0.17, 0.12))

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 0.2, 3.6)
	add_child(player)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.34
	capsule.height = 1.45
	body.mesh = capsule
	body.position.y = 0.75
	body.material_override = _mat(Color(0.13, 0.48, 0.77))
	player.add_child(body)
	var apron := MeshInstance3D.new()
	var apron_mesh := BoxMesh.new()
	apron_mesh.size = Vector3(0.48, 0.62, 0.12)
	apron.mesh = apron_mesh
	apron.position = Vector3(0, 0.72, 0.28)
	apron.material_override = _mat(Color(0.96, 0.82, 0.57))
	player.add_child(apron)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.25
	head_mesh.height = 0.5
	head.mesh = head_mesh
	head.position.y = 1.62
	head.material_override = _mat(Color(0.91, 0.67, 0.49))
	player.add_child(head)
	var hat := MeshInstance3D.new()
	var hat_mesh := CylinderMesh.new()
	hat_mesh.top_radius = 0.23
	hat_mesh.bottom_radius = 0.3
	hat_mesh.height = 0.18
	hat.mesh = hat_mesh
	hat.position.y = 1.91
	hat.material_override = _mat(Color(0.96, 0.91, 0.78))
	player.add_child(hat)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.5
	collision.shape = shape
	collision.position.y = 0.76
	player.add_child(collision)
	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.current = true
	camera.position = Vector3(0, 7.8, 10.5)
	add_child(camera)
	camera.look_at(player.global_position + Vector3(0, 0.4, 0), Vector3.UP)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(300, 112)
	layer.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "MARKET.IO  •  PIZZA TYCOON"
	title.add_theme_font_size_override("font_size", 19)
	vbox.add_child(title)
	cash_label = Label.new()
	stock_label = Label.new()
	vbox.add_child(cash_label)
	vbox.add_child(stock_label)
	status_label = Label.new()
	status_label.anchor_left = 0.5
	status_label.anchor_right = 0.5
	status_label.offset_left = -280
	status_label.offset_right = 280
	status_label.offset_top = 18
	status_label.offset_bottom = 58
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(status_label)

	var controls := HBoxContainer.new()
	controls.anchor_left = 0.0
	controls.anchor_top = 1.0
	controls.anchor_bottom = 1.0
	controls.offset_left = 18
	controls.offset_top = -142
	controls.offset_right = 270
	controls.offset_bottom = -18
	controls.add_theme_constant_override("separation", 8)
	layer.add_child(controls)
	var left_col := VBoxContainer.new()
	controls.add_child(left_col)
	var up := _make_button("▲", Vector2(68, 48))
	left_col.add_child(up)
	var horizontal := HBoxContainer.new()
	left_col.add_child(horizontal)
	var left := _make_button("◀", Vector2(68, 48))
	var down := _make_button("▼", Vector2(68, 48))
	horizontal.add_child(left)
	horizontal.add_child(down)
	left.button_down.connect(func(): movement.x = -1.0)
	left.button_up.connect(func(): movement.x = 0.0)
	down.button_down.connect(func(): movement.y = 1.0)
	down.button_up.connect(func(): movement.y = 0.0)
	up.button_down.connect(func(): movement.y = -1.0)
	up.button_up.connect(func(): movement.y = 0.0)
	var right := _make_button("▶", Vector2(68, 48))
	horizontal.add_child(right)
	right.button_down.connect(func(): movement.x = 1.0)
	right.button_up.connect(func(): movement.x = 0.0)

	var actions := VBoxContainer.new()
	actions.anchor_left = 1.0
	actions.anchor_top = 1.0
	actions.anchor_right = 1.0
	actions.anchor_bottom = 1.0
	actions.offset_left = -218
	actions.offset_top = -142
	actions.offset_right = -18
	actions.offset_bottom = -18
	actions.add_theme_constant_override("separation", 7)
	layer.add_child(actions)
	interact_button = _make_button("COOK / SERVE", Vector2(196, 54))
	actions.add_child(interact_button)
	interact_button.pressed.connect(_interact)
	var upgrade := _make_button("SHOP UPGRADES", Vector2(196, 48))
	actions.add_child(upgrade)
	upgrade.pressed.connect(_buy_upgrade)
	var hire := _make_button("HIRE WORKER", Vector2(196, 48))
	actions.add_child(hire)
	hire.pressed.connect(_hire_worker)

func _make_button(text_value: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 16)
	return button

func _update_interaction_prompt() -> void:
	if player == null:
		return
	var oven_distance := player.global_position.distance_to(oven_pos)
	var counter_distance := player.global_position.distance_to(counter_pos)
	if oven_distance < 2.6:
		interact_button.text = "COOK PIZZA  ($%d)" % PIZZA_COST
	elif counter_distance < 2.8:
		interact_button.text = "SERVE CUSTOMER"
	else:
		interact_button.text = "COOK / SERVE"

func _interact() -> void:
	if player.global_position.distance_to(oven_pos) < 2.6:
		if cash < PIZZA_COST:
			_set_status("Not enough cash for ingredients. Serve a pizza first!")
			return
		cash -= PIZZA_COST
		pizzas += 1
		_pizza(oven_pos + Vector3(0, 1.48, 0.3), 0.34)
		_set_status("Fresh pizza baked! Head to the counter to serve it.")
	elif player.global_position.distance_to(counter_pos) < 2.8:
		_sell_pizza()
	else:
		_set_status("Walk close to the oven to cook, or the counter to serve.")

func _sell_pizza() -> void:
	if pizzas <= 0:
		_set_status("No pizzas ready. Bake one at the oven first!")
		return
	pizzas -= 1
	cash += PIZZA_PRICE
	sold += 1
	customers_served += 1
	_set_status("Pizza sold for $%d! Your shop is growing." % PIZZA_PRICE)
	_refresh_hud()
	if sold >= 5 and tables == 0:
		_set_status("Milestone! You can now buy your first dining table.")
	if sold >= 10 and extra_ovens == 0:
		_set_status("Great sales! A second oven is ready to unlock.")

func _buy_upgrade() -> void:
	if player.global_position.distance_to(Vector3(0, 0, 0)) > 12.0:
		_set_status("Come back inside to manage your shop.")
		return
	if tables == 0 and sold >= 5 and cash >= 60:
		cash -= 60
		tables = 1
		_box("Dining table", Vector3(4.6, 0.42, 2.1), Vector3(1.8, 0.16, 1.2), Color(0.62, 0.34, 0.20), false)
		for x in [-0.65, 0.65]:
			_box("Dining chair", Vector3(4.6 + x, 0.35, 2.1), Vector3(0.35, 0.7, 0.35), Color(0.16, 0.45, 0.39), false)
		shop_level += 1
		_set_status("Dining area unlocked! More customers will visit.")
	elif extra_ovens == 0 and sold >= 10 and cash >= 90:
		cash -= 90
		extra_ovens = 1
		_build_oven(Vector3(-5.8, 0, -2.2))
		shop_level += 1
		_set_status("Second oven installed. Your kitchen can grow faster!")
	elif cash >= 60:
		_set_status("Next upgrade: sell 5 pizzas for a table ($60), then 10 for another oven ($90).")
	else:
		_set_status("You need $60 and 5 sales to unlock your first table.")

func _hire_worker() -> void:
	if workers >= 3:
		_set_status("Your team is full for this shop level. Upgrade the restaurant first!")
		return
	var cost := 120 + workers * 80
	if cash < cost:
		_set_status("Hiring costs $%d. Keep selling pizzas!" % cost)
		return
	cash -= cost
	workers += 1
	var worker_pos := Vector3(2.0 + workers * 0.6, 0.1, 0.8)
	_make_character(worker_pos, Color(0.23, 0.62, 0.42))
	_set_status("Worker hired! They'll automatically serve ready pizzas.")
	_refresh_hud()

func _spawn_customer() -> void:
	var customer := Node3D.new()
	customer.name = "Customer"
	customer.position = Vector3(rng.randf_range(-5.0, 5.0), 0.0, 5.3)
	add_child(customer)
	_make_character(Vector3.ZERO, Color(rng.randf_range(0.25, 0.9), rng.randf_range(0.25, 0.8), rng.randf_range(0.25, 0.8)), customer)
	customers.append(customer)

func _make_character(pos: Vector3, shirt: Color, parent: Node3D = null) -> void:
	var root := Node3D.new()
	root.position = pos
	if parent == null:
		add_child(root)
	else:
		parent.add_child(root)
	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.28
	torso_mesh.height = 1.0
	torso.mesh = torso_mesh
	torso.position.y = 0.58
	torso.material_override = _mat(shirt)
	root.add_child(torso)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	head.position.y = 1.23
	head.material_override = _mat(Color(0.88, 0.65, 0.48))
	root.add_child(head)

func _update_customers(delta: float) -> void:
	for i in range(customers.size() - 1, -1, -1):
		var customer := customers[i]
		if not is_instance_valid(customer):
			customers.remove_at(i)
			continue
		var target := Vector3(3.0, 0.0, 0.25)
		var diff := target - customer.position
		if diff.length() > 0.2:
			customer.position += diff.normalized() * delta * 1.15
		if customer.position.distance_to(Vector3(3.0, 0.0, -0.5)) < 0.6 and pizzas > 0 and workers > 0:
			_sell_pizza()
			customer.queue_free()
			customers.remove_at(i)
		elif customer.position.z < -5.8:
			customer.queue_free()
			customers.remove_at(i)

func _update_camera(delta: float) -> void:
	if camera == null or player == null:
		return
	var target := player.global_position + Vector3(0, 7.8, 10.5)
	camera.global_position = camera.global_position.lerp(target, minf(1.0, delta * 4.0))
	camera.look_at(player.global_position + Vector3(0, 0.5, 0), Vector3.UP)

func _refresh_hud() -> void:
	if cash_label:
		cash_label.text = "Cash: $%d   |   Sales: %d" % [cash, sold]
	if stock_label:
		stock_label.text = "Ready pizzas: %d   |   Workers: %d   |   Level: %d" % [pizzas, workers, shop_level]

func _set_status(message: String) -> void:
	if status_label:
		status_label.text = message
	_refresh_hud()

func _box(label: String, pos: Vector3, size: Vector3, color: Color, collision := true) -> MeshInstance3D:
	var root: Node3D
	if collision:
		var body := StaticBody3D.new()
		body.name = label
		body.position = pos
		add_child(body)
		root = body
	else:
		root = Node3D.new()
		root.name = label
		root.position = pos
		add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _mat(color)
	root.add_child(mesh_instance)
	if collision and root is StaticBody3D:
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		root.add_child(shape_node)
	return mesh_instance

func _sphere(label: String, pos: Vector3, radius: float, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _mat(color)
	add_child(mesh_instance)

func _pizza(pos: Vector3, radius: float) -> void:
	var base := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.08
	base.mesh = mesh
	base.position = pos
	base.material_override = _mat(Color(0.92, 0.65, 0.28))
	add_child(base)
	for i in range(5):
		var angle := float(i) * TAU / 5.0
		_sphere("Pepperoni", pos + Vector3(cos(angle) * radius * 0.55, 0.06, sin(angle) * radius * 0.55), radius * 0.15, Color(0.76, 0.12, 0.10))

func _sign(text_value: String, pos: Vector3) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.position = pos
	label.font_size = 64
	label.pixel_size = 0.008
	label.modulate = Color(0.28, 0.12, 0.08)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material
