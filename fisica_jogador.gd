extends RigidBody2D

var is_pulling: bool = false
var click_start_pos: Vector2 = Vector2.ZERO

@export var launch_force_multiplier: float = 8.0 
@export var max_pull_distance: float = 150.0      

@onready var line_2d: Line2D = $Line2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D

# No topo do script do Jogador (RigidBody2D):
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

# Você pode arrastar a imagem da bolinha/círculo direto no Inspetor da Godot:
@export var textura_circulo: Texture2D
@export var textura_triangulo: Texture2D

func _ready() -> void:
	if line_2d:
		line_2d.clear_points()
		line_2d.width = 12.0 

func _physics_process(delta: float) -> void:
	# Percorre todos os corpos que estão encostando no cubo neste exato frame
	for body in get_colliding_bodies():
		if body.name == "TransformarCirculo":
			print("Olá mundo")
			
func esta_no_chao() -> bool:
	# Se a velocidade vertical for muito alta, ele está caindo/voando rápido
	if abs(linear_velocity.y) > 30.0:
		return false

	# get_colliding_bodies() retorna os corpos físicos que o cubo está tocando agora
	var corpos = get_colliding_bodies()
	return corpos.size() > 0
	
func transformar_em_triangulo() -> void:
	print("Transformando em triângulo!")
	
	# 1. Ajusta a escala do visual se necessário
	sprite_2d.scale = Vector2(0.25, 0.25)
	
	# 2. Carrega a textura do triângulo
	var textura_carregada = load("res://triangle.svg")
	if textura_carregada != null:
		sprite_2d.texture = textura_carregada
	elif textura_triangulo != null:
		sprite_2d.texture = textura_triangulo
	else:
		printerr("ERRO: Não encontrou o arquivo triangle.svg")

	# 3. Cria a colisão triangular usando ConvexPolygonShape2D
	var novo_shape = ConvexPolygonShape2D.new()
	
	# Definimos os 3 cantos do triângulo (Top, Inferior Direito, Inferior Esquerdo)
	# Supondo uma base e altura proporcionais a ~60-80 pixels ao redor do centro:
	var tamanho: float = 60.0 # Ajuste este valor para casar com o tamanho do seu sprite
	novo_shape.points = PackedVector2Array([
		Vector2(0, -tamanho),          # Vértice do topo (apontado para cima)
		Vector2(tamanho, tamanho),     # Canto inferior direito
		Vector2(-tamanho, tamanho)     # Canto inferior esquerdo
	])
	
	collision_shape_2d.shape = novo_shape
			 
func transformar_em_circulo() -> void:
	print("Transformando em círculo!")
	sprite_2d.scale = Vector2(0.8, 0.8) # Ou ajuste para o tamanho proporcional
	
	# 1. Carrega o png diretamente pelo caminho no seu projeto
	# Substitua pelo nome exato do arquivo que você colocou na pasta res://
	var textura_carregada = load("res://circle.png") 
	
	if textura_carregada != null:
		sprite_2d.texture = textura_carregada
	else:
		printerr("ERRO: Não encontrou o arquivo circle.png na pasta res://")

	# 2. Atualiza a colisão para círculo
	var novo_shape = CircleShape2D.new()
	novo_shape.radius =  80.0 # Altere aqui o tamanho real em pixels do raio
	collision_shape_2d.shape = novo_shape

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Verifica se o RayCast está a tocar em alguma coisa (chão)
			var esta_no_chao: bool = get_contact_count() > 0
			
			# O jogador só pode começar a puxar se clicar no cubo E estiver no chão!
			if esta_no_chao:
				var mouse_pos = get_global_mouse_position()
				if mouse_pos.distance_to(global_position) < 35.0:
					is_pulling = true
					click_start_pos = mouse_pos
					print("Começou a puxar o estilingue (está no chão)!")
			else:
				print("Não pode pular no ar!")
				
		elif not event.pressed and is_pulling:
			is_pulling = false
			
			var release_pos = get_global_mouse_position()
			var pull_vector = release_pos - click_start_pos
			pull_vector = pull_vector.limit_length(max_pull_distance)
			
			var final_impulse = -pull_vector * launch_force_multiplier
			apply_central_impulse(final_impulse)
			
			if line_2d:
				line_2d.clear_points()

func _process(delta: float) -> void:
	if is_pulling:
		var current_mouse_pos = get_global_mouse_position()
		var local_mouse_pos = to_local(current_mouse_pos)
		
		var pull_vector_visual = (local_mouse_pos - to_local(click_start_pos)).limit_length(max_pull_distance)
		
		var arrow_tip = Vector2.ZERO - (pull_vector_visual * 1.5)
		
		if line_2d:
			line_2d.clear_points()
			line_2d.add_point(Vector2.ZERO)
			line_2d.add_point(arrow_tip)
	else:
		if line_2d:
			line_2d.clear_points()
			
	
