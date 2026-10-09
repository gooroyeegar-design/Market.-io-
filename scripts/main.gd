extends Node3D

const START_CASH := 85
const RESTOCK_COST := 12
const PRODUCT_PRICE := 8
const CUSTOMER_INTERVAL := 5.5

var cash := START_CASH
var stock := 8
var sold := 0
var day_time := 0.0
var customer_timer := 1.0
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var cash_label: Label
var stock_label: Label
var hint_label: Label
var status_label: Label
var customers: Array[Node3D] = []
var customer_targets: Array[Vector3] = []
var customers_served := 0
var key_up := false
var key_down := false
var key_left := false
var key_right := false
var interaction_cooldown := 0.0
var shelf_root: Node3D
var checkout_position := Vector3(3.0, 0.0, -2.0)
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_build_world()
	_build_player()
	_build_customers()
	_build_hud()
	_refresh_hud()
	status_label.text = "Welcome! Stock your shelves and serve your first customers."

func _process(delta: float) -> void:
	day_time += delta
	customer_timer -= delta
	interaction_cooldown = maxf(0.0, interaction_cooldown - delta)
	if customer_timer <= 0.0 and customers.size() < 5:
		customer_timer = CUSTOMER_INTERVAL + rng.randf_range(0.0, 2.0)
		_spawn_customer()
	_update_customers(delta)
	_update_camera(delta)
	_update_hint()

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var input_vec := Vector2.ZERO
	input_vec.x = float(key_right) - float(key_left)
	input_vec.y = float(key_down) - float(key_up)
	if Input.is_action_pressed("ui_right"):
		input_vec.x += 1.0
	if Input.is_action_pressed("ui_left"):
		input_vec.x -= 1.0
	if Input.is_action_pressed("ui_down"):
		input_vec.y += 1.0
	if Input.is_action_pressed("ui_up"):
		input_vec.y -= 1.0
	input_vec = input_vec.limit_length()
	var direction := Vector3(input_vec.x, 0.0, input_vec.y)
	player.velocity.x = direction.x * 5.2
	player.velocity.z = direction.z * 5.2
	player.velocity.y = 0.0
	player.move_and_slide()
	player.global_position.x = clampf(player.global_position.x, -9.0, 9.0)
	player.global_position.z = clampf(player.global_position.z, -6.5, 6.5)
	if direction.length() > 0.1:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(direction.x, direction.z), 0.18)

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.73, 0.81)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.83, 0.88, 0.94)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	_make_box("Warm shop floor", Vector3(0, -0.25, 0), Vector3(20, 0.5, 15), Color(0.88, 0.82, 0.70))
	_make_box("Back wall", Vector3(0, 2.0, -7.4), Vector3(20, 4.5, 0.5), Color(0.96, 0.91, 0.82))
	_make_box("Left wall", Vector3(-9.8, 2.0, 0), Vector3(0.4, 4.5, 15), Color(0.93, 0.86, 0.76))
	_make_box("Right wall", Vector3(9.8, 2.0, 0), Vector3(0.4, 4.5, 15), Color(0.93, 0.86, 0.76))
	_make_box("Front awning", Vector3(0, 3.7, 7.15), Vector3(7.0, 0.25, 0.6), Color(0.18, 0.57, 0.49))
	_make_text_sign("MARKET", Vector3(0, 3.95, 6.95))
	shelf_root = Node3D.new()
	shelf_root.name = "Shelves"
	add_child(shelf_root)
	_build_shelf(Vector3(-4.6, 0, -2.2), 0)
	_build_shelf(Vector3(-1.2, 0, -2.2), 1)
	_build_shelf(Vector3(-4.6, 0, 2.0), 2)
	_build_shelf(Vector3(-1.2, 0, 2.0), 3)
	_make_box("Checkout counter", checkout_position + Vector3(0, 0.65, 0), Vector3(2.4, 1.3, 1.1), Color(0.21, 0.37, 0.34))
	_make_box("Counter top", checkout_position + Vector3(0, 1.34, 0), Vector3(2.55, 0.12, 1.2), Color(0.95, 0.76, 0.43))
	_make_box("Cash register", checkout_position + Vector3(0.0, 1.55, -0.1), Vector3(0.55, 0.28, 0.42), Color(0.13, 0.18, 0.20))
	_make_box("Front welcome mat", Vector3(0, 0.02, 6.2), Vector3(4.5, 0.08, 1.0), Color(0.20, 0.52, 0.43))
	_make_box("Storage door", Vector3(7.8, 1.2, -7.1), Vector3(2.2, 2.5, 0.15), Color(0.47, 0.31, 0.22))
	_make_box("Window left", Vector3(-7.4, 2.0, 7.12), Vector3(2.5, 1.7, 0.12), Color(0.51, 0.77, 0.83))
	_make_box("Window right", Vector3(7.4, 2.0, 7.12), Vector3(2.5, 1.7, 0.12), Color(0.51, 0.77, 0.83))

func _build_shelf(pos: Vector3, index: int) -> void:
	var root := Node3D.new()
	root.position = pos
	root.name = "Shelf_%d" % index
	shelf_root.add_child(root)
	var wood := Color(0.56, 0.34, 0.22)
	_make_box_child(root, "Shelf backing", Vector3(0, 1.0, 0), Vector3(2.4, 2.1, 0.18), wood)
	for level in range(3):
		_make_box_child(root, "Shelf board", Vector3(0, 0.35 + level * 0.62, 0.28), Vector3(2.5, 0.1, 0.72), Color(0.79, 0.65, 0.48))
	var colors: Array[Color] = [Color(0.90, 0.31, 0.24), Color(0.97, 0.69, 0.23), Color(0.24, 0.62, 0.43), Color(0.30, 0.53, 0.82), Color(0.76, 0.42, 0.69), Color(0.93, 0.84, 0.63)]
	for i in range(6):
		for level in range(3):
			_make_box_child(root, "Product", Vector3(-0.92 + float(i % 3) * 0.92, 0.62 + level * 0.62, 0.32 + float(i / 3) * 0.16), Vector3(0.36, 0.43, 0.30), colors[i])
	_make_box_child(root, "Shelf foot", Vector3(0, 0.14, 0.0), Vector3(2.6, 0.25, 0.8), wood)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0.0, 0.1, 4.2)
	add_child(player)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.55
	body.mesh = capsule
	body.position.y = 0.82
	body.material_override = _material(Color(0.20, 0.52, 0.85))
	player.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.56
	head.mesh = sphere
	head.position = Vector3(0, 1.72, 0)
	head.material_override = _material(Color(0.94, 0.70, 0.52))
	player.add_child(head)
	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.29
	hair_mesh.height = 0.24
	hair.mesh = hair_mesh
	hair.position = Vector3(0, 1.91, 0)
	hair.material_override = _material(Color(0.20, 0.15, 0.12))
	player.add_child(hair)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.65
	collision.shape = shape
	collision.position.y = 0.83
	player.add_child(collision)
	camera = Camera3D.new()
	camera.name = "ThirdPersonCamera"
	camera.current = true
	camera.position = player.position + Vector3(0, 6.7, 9.0)
	add_child(camera)
	camera.look_at(player.position + Vector3(0, 0.8, 0), Vector3.UP)

func _build_customers() -> void:
	for _i in range(2):
		_spawn_customer()

func _spawn_customer() -> void:
	var customer := Node3D.new()
	customer.name = "Customer"
	customer.position = Vector3(rng.randf_range(-7.0, 7.0), 0.0, -5.7)
	add_child(customer)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.32
	capsule.height = 1.35
	body.mesh = capsule
	body.position.y = 0.7
	var outfits: Array[Color] = [Color(0.91, 0.48, 0.32), Color(0.43, 0.62, 0.88), Color(0.62, 0.45, 0.75), Color(0.28, 0.65, 0.50)]
	body.material_override = _material(outfits[rng.randi_range(0, outfits.size() - 1)])
	customer.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.23
	sphere.height = 0.46
	head.mesh = sphere
	head.position.y = 1.5
	head.material_override = _material(Color(0.94, 0.72, 0.56))
	customer.add_child(head)
	customers.append(customer)
	customer_targets.append(Vector3(rng.randf_range(-5.5, 1.5), 0.0, rng.randf_range(-3.0, 2.5)))

func _update_customers(delta: float) -> void:
	for i in range(customers.size() - 1, -1, -1):
		var c := customers[i]
		if not is_instance_valid(c):
			customers.remove_at(i)
			customer_targets.remove_at(i)
			continue
		var target: Vector3 = customer_targets[i]
		var offset := target - c.position
		if offset.length() > 0.25:
			c.position += offset.normalized() * delta * 1.15
			c.look_at(Vector3(target.x, c.position.y, target.z), Vector3.UP)
		else:
			if stock > 0 and rng.randf() < delta * 0.13:
				stock -= 1
				cash += PRODUCT_PRICE
				sold += 1
				customers_served += 1
				status_label.text = "Sale! +$%d — a customer bought a product." % PRODUCT_PRICE
				_refresh_hud()
				customer_targets[i] = checkout_position + Vector3(0, 0, 1.4)
			elif stock <= 0 and rng.randf() < delta * 0.04:
				status_label.text = "A customer left disappointed. Restock your shelves!"
				customer_targets[i] = Vector3(rng.randf_range(-7.0, 7.0), 0, 6.5)
		if c.position.z > 5.8 or c.position.length() > 20.0:
			c.queue_free()
			customers.remove_at(i)
			customer_targets.remove_at(i)

func _update_camera(delta: float) -> void:
	if camera == null or player == null:
		return
	var target := player.global_position + Vector3(0, 6.7, 9.0)
	camera.global_position = camera.global_position.lerp(target, clampf(delta * 4.0, 0.0, 1.0))
	camera.look_at(player.global_position + Vector3(0, 0.8, 0), Vector3.UP)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(root)
	var top := PanelContainer.new()
	top.position = Vector2(18, 16)
	top.custom_minimum_size = Vector2(370, 94)
	root.add_child(top)
	var top_box := VBoxContainer.new()
	top.add_child(top_box)
	var title := Label.new()
	title.text = "MARKET.IO   /   DAY 1"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.13, 0.35, 0.31))
	top_box.add_child(title)
	cash_label = Label.new()
	cash_label.add_theme_font_size_override("font_size", 18)
	top_box.add_child(cash_label)
	stock_label = Label.new()
	stock_label.add_theme_font_size_override("font_size", 16)
	top_box.add_child(stock_label)
	var status_panel := PanelContainer.new()
	status_panel.anchor_left = 0.5
	status_panel.anchor_right = 0.5
	status_panel.offset_left = -250
	status_panel.offset_right = 250
	status_panel.offset_top = 18
	status_panel.offset_bottom = 62
	root.add_child(status_panel)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_panel.add_child(status_label)
	hint_label = Label.new()
	hint_label.anchor_left = 0.5
	hint_label.anchor_right = 0.5
	hint_label.anchor_top = 1.0
	hint_label.anchor_bottom = 1.0
	hint_label.offset_left = -250
	hint_label.offset_right = 250
	hint_label.offset_top = -78
	hint_label.offset_bottom = -48
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color(0.12, 0.19, 0.18))
	root.add_child(hint_label)
	var restock := Button.new()
	restock.text = "RESTOCK  -$12"
	restock.position = Vector2(18, 125)
	restock.custom_minimum_size = Vector2(170, 54)
	restock.pressed.connect(_restock)
	root.add_child(restock)
	var interact := Button.new()
	interact.text = "INTERACT"
	interact.anchor_left = 1.0
	interact.anchor_right = 1.0
	interact.anchor_top = 1.0
	interact.anchor_bottom = 1.0
	interact.offset_left = -180
	interact.offset_right = -18
	interact.offset_top = -104
	interact.offset_bottom = -28
	interact.custom_minimum_size = Vector2(162, 76)
	interact.pressed.connect(_interact)
	root.add_child(interact)
	var controls := GridContainer.new()
	controls.columns = 3
	controls.position = Vector2(20, 455)
	controls.add_theme_constant_override("h_separation", 5)
	controls.add_theme_constant_override("v_separation", 5)
	root.add_child(controls)
	_add_spacer(controls)
	_add_move_button(controls, "▲", "up")
	_add_spacer(controls)
	_add_move_button(controls, "◀", "left")
	_add_move_button(controls, "▼", "down")
	_add_move_button(controls, "▶", "right")

func _add_spacer(parent: GridContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(54, 46)
	parent.add_child(spacer)

func _add_move_button(parent: GridContainer, caption: String, direction: String) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(54, 46)
	button.button_down.connect(func(): _set_move(direction, true))
	button.button_up.connect(func(): _set_move(direction, false))
	parent.add_child(button)

func _set_move(direction: String, pressed: bool) -> void:
	match direction:
		"up": key_up = pressed
		"down": key_down = pressed
		"left": key_left = pressed
		"right": key_right = pressed

func _restock() -> void:
	if cash < RESTOCK_COST:
		status_label.text = "Not enough cash. Serve a few customers first."
		return
	cash -= RESTOCK_COST
	stock += 10
	status_label.text = "Delivery arrived! +10 products for $%d." % RESTOCK_COST
	_refresh_hud()

func _interact() -> void:
	if interaction_cooldown > 0.0:
		return
	interaction_cooldown = 0.7
	var near_shelf := false
	for shelf in shelf_root.get_children():
		if player.global_position.distance_to(shelf.global_position) < 2.5:
			near_shelf = true
			break
	if near_shelf:
		_restock()
	elif player.global_position.distance_to(checkout_position) < 3.0:
		status_label.text = "Checkout is ready. Customers buy automatically when products are in stock."
	else:
		status_label.text = "Walk to a shelf to restock, or use the RESTOCK button to order a delivery."

func _update_hint() -> void:
	if player == null:
		return
	var near_shelf := false
	for shelf in shelf_root.get_children():
		if player.global_position.distance_to(shelf.global_position) < 2.5:
			near_shelf = true
			break
	if near_shelf:
		hint_label.text = "NEAR SHELF  •  Tap INTERACT to restock"
	elif player.global_position.distance_to(checkout_position) < 3.0:
		hint_label.text = "CHECKOUT  •  Customers pay automatically"
	else:
		hint_label.text = "WASD / arrows to move  •  Explore your shop"

func _refresh_hud() -> void:
	if cash_label == null:
		return
	cash_label.text = "Cash: $%d   |   Sales: %d" % [cash, sold]
	stock_label.text = "Products in stock: %d   |   Customers served: %d" % [stock, customers_served]

func _make_box(label: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var box := MeshInstance3D.new()
	box.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	box.mesh = mesh
	box.position = pos
	box.material_override = _material(color)
	add_child(box)
	return box

func _make_box_child(parent: Node3D, label: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var box := MeshInstance3D.new()
	box.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	box.mesh = mesh
	box.position = pos
	box.material_override = _material(color)
	parent.add_child(box)
	return box

func _make_text_sign(label: String, pos: Vector3) -> void:
	var sign := Label3D.new()
	sign.text = label
	sign.position = pos
	sign.font_size = 64
	sign.pixel_size = 0.006
	sign.modulate = Color(1.0, 0.92, 0.72)
	sign.outline_size = 8
	sign.outline_modulate = Color(0.12, 0.25, 0.22)
	add_child(sign)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat
