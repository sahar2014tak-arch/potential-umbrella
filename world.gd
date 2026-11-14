extends Node3D

const MOVE_SPEED := 5.0
const JUMP_SPEED := 7.0
const GRAVITY := 18.0

var player: CharacterBody3D
var coins := 0
var hud: Label
var message: Label
var coin_nodes: Array[Node3D] = []
var move_left := false
var move_right := false
var move_forward := false
var move_back := false
var jump_requested := false

func _ready() -> void:
    randomize()
    _make_world()
    _make_player()
    _make_ui()
    _spawn_coins()

func _make_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.65, 0.75, 0.85)
    environment.ambient_light_energy = 0.8
    env.environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.light_energy = 1.2
    add_child(sun)

    _static_box(Vector3(0, -0.5, 0), Vector3(42, 1, 42), Color(0.18, 0.36, 0.19))
    _static_box(Vector3(0, 0.02, -7), Vector3(5, 0.08, 25), Color(0.48, 0.34, 0.2))
    _static_box(Vector3(0, 1.2, -17), Vector3(9, 2.4, 3), Color(0.55, 0.53, 0.43))

    for x in [-3.2, 0.0, 3.2]:
        _static_box(Vector3(x, 2.2, -15.4), Vector3(0.7, 4.4, 0.7), Color(0.68, 0.64, 0.52))

    for i in range(30):
        var x := randf_range(-18, 18)
        var z := randf_range(-18, 18)
        if abs(x) < 4.5:
            continue
        _static_box(Vector3(x, 1.0, z), Vector3(0.45, 2.0, 0.45), Color(0.28, 0.16, 0.08))
        var crown := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 1.3
        mesh.height = 2.4
        crown.mesh = mesh
        crown.position = Vector3(x, 2.6, z)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.08, randf_range(0.25, 0.42), 0.12)
        crown.material_override = mat
        add_child(crown)

func _make_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 0.1, 8)
    add_child(player)

    var body := _box(Vector3(0, 0.7, 0), Vector3(0.8, 1.4, 0.5), Color(0.15, 0.35, 0.75))
    player.add_child(body)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.4
    shape.height = 1.6
    collision.shape = shape
    collision.position.y = 0.8
    player.add_child(collision)

    var camera := Camera3D.new()
    camera.position = Vector3(0, 4.2, 7)
    camera.rotation_degrees = Vector3(-22, 0, 0)
    player.add_child(camera)
    camera.current = true

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    hud = Label.new()
    hud.position = Vector2(24, 18)
    hud.add_theme_font_size_override("font_size", 28)
    layer.add_child(hud)

    message = Label.new()
    message.position = Vector2(24, 58)
    message.add_theme_font_size_override("font_size", 20)
    layer.add_child(message)
    _update_hud()

    var help := Label.new()
    help.text = "حرکت با دکمه‌های لمسی | رایانه: WASD و Space"
    help.position = Vector2(24, 680)
    help.add_theme_font_size_override("font_size", 18)
    layer.add_child(help)

    _add_control(layer, "▲", Vector2(110, 520), "forward")
    _add_control(layer, "▼", Vector2(110, 620), "back")
    _add_control(layer, "◀", Vector2(10, 570), "left")
    _add_control(layer, "▶", Vector2(210, 570), "right")
    _add_control(layer, "پرش", Vector2(1080, 570), "jump")

func _add_control(layer: CanvasLayer, caption: String, pos: Vector2, action: String) -> void:
    var button := Button.new()
    button.text = caption
    button.position = pos
    button.size = Vector2(88, 76)
    button.add_theme_font_size_override("font_size", 25)
    button.modulate = Color(1, 1, 1, 0.82)
    layer.add_child(button)
    match action:
        "forward":
            button.button_down.connect(func(): move_forward = true)
            button.button_up.connect(func(): move_forward = false)
        "back":
            button.button_down.connect(func(): move_back = true)
            button.button_up.connect(func(): move_back = false)
        "left":
            button.button_down.connect(func(): move_left = true)
            button.button_up.connect(func(): move_left = false)
        "right":
            button.button_down.connect(func(): move_right = true)
            button.button_up.connect(func(): move_right = false)
        "jump":
            button.button_down.connect(func(): jump_requested = true)

func _spawn_coins() -> void:
    for i in range(8):
        var coin := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.35
        mesh.height = 0.12
        coin.mesh = mesh
        coin.position = Vector3(randf_range(-2.0, 2.0), 0.8, 5.0 - i * 2.8)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(1.0, 0.72, 0.08)
        mat.metallic = 0.65
        coin.material_override = mat
        add_child(coin)
        coin_nodes.append(coin)

func _physics_process(delta: float) -> void:
    if player == null:
        return

    var x_axis := float(move_right) - float(move_left)
    var z_axis := float(move_back) - float(move_forward)
    if Input.is_key_pressed(KEY_A): x_axis -= 1.0
    if Input.is_key_pressed(KEY_D): x_axis += 1.0
    if Input.is_key_pressed(KEY_W): z_axis -= 1.0
    if Input.is_key_pressed(KEY_S): z_axis += 1.0
    if Input.is_action_pressed("ui_left"): x_axis -= 1.0
    if Input.is_action_pressed("ui_right"): x_axis += 1.0
    if Input.is_action_pressed("ui_up"): z_axis -= 1.0
    if Input.is_action_pressed("ui_down"): z_axis += 1.0

    var direction := Vector2(x_axis, z_axis).normalized()
    player.velocity.x = direction.x * MOVE_SPEED
    player.velocity.z = direction.y * MOVE_SPEED

    if not player.is_on_floor():
        player.velocity.y -= GRAVITY * delta
    elif jump_requested or Input.is_key_pressed(KEY_SPACE):
        player.velocity.y = JUMP_SPEED
    jump_requested = false

    player.move_and_slide()

    for coin in coin_nodes.duplicate():
        if is_instance_valid(coin) and player.global_position.distance_to(coin.global_position) < 1.2:
            coin_nodes.erase(coin)
            coin.queue_free()
            coins += 1
            _update_hud()
            if coins >= 8:
                message.text = "آفرین! همه سکه‌ها را پیدا کردی."

func _update_hud() -> void:
    if hud:
        hud.text = "راز سرزمین گمشده   |   سکه‌ها: %d / 8" % coins

func _static_box(pos: Vector3, size: Vector3, color: Color) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    var mesh_node := _box(Vector3.ZERO, size, color)
    body.add_child(mesh_node)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)

func _box(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    node.mesh = mesh
    node.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    node.material_override = mat
    return node
