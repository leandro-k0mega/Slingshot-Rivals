extends Camera2D

@export var velocidade_movimento: float = 400.0
@export var gerenciador: Node2D

var modo_fantasma_ativo: bool = false
var camera_original: Camera2D = null

func _ready() -> void:
	enabled = false

func ativar_modo_fantasma(camera_orig: Camera2D = null) -> void:
	camera_original = camera_orig
	if camera_original:
		global_position = camera_original.global_position
	
	enabled = true
	make_current()
	modo_fantasma_ativo = true
	print(">>> MODO FANTASMA ATIVADO: Use WASD para explorar e clique numa plataforma!")

func desativar_modo_fantasma() -> void:
	modo_fantasma_ativo = false
	enabled = false
	if camera_original:
		camera_original.make_current()

func _process(delta: float) -> void:
	if not modo_fantasma_ativo:
		return
		
	# Movimento livre com WASD
	var direcao = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		direcao.y -= 1
	if Input.is_key_pressed(KEY_S):
		direcao.y += 1
	if Input.is_key_pressed(KEY_A):
		direcao.x -= 1
	if Input.is_key_pressed(KEY_D):
		direcao.x += 1
		
	global_position += direcao.normalized() * velocidade_movimento * delta

func _unhandled_input(event: InputEvent) -> void:
	if not modo_fantasma_ativo:
		return
		
	# Clique esquerdo do mouse para escolher a plataforma
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		
		# Dispara um raycast 2D pontual no local do clique
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = mouse_pos
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		var resultados = space_state.intersect_point(query)
		for res in resultados:
			var objeto = res.collider
			if objeto and objeto.is_in_group("Plataformas") and objeto.has_method("tornar_fantasma"):
				# Transforma por 2 turnos (a rodada atual + a próxima)
				objeto.tornar_fantasma(2)
				desativar_modo_fantasma()
				if gerenciador and gerenciador.has_method("finalizar_uso_fantasmagorificar"):
					gerenciador.finalizar_uso_fantasmagorificar()
				get_viewport().set_input_as_handled()
				break
