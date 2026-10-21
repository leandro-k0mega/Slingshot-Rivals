# Script de física do jogador 1
# Adendo, a maioria, se não, TUDO que for alterado em um script precisa ser alterado no outro

extends RigidBody2D

# Verificação de clique e puxada
var is_pulling: bool = false
var click_start_pos: Vector2 = Vector2.ZERO

var ja_disparou: bool = false
var tempo_parado: float = 0.0

# Referência de ID do jogador
@export var numero_jogador: int = 1 # No fisica_jogador2.gd, mude este valor para 2!

@export var gerenciador: Node2D # Referência ao sistema de turnos

# Estes valores ficam perfeitos para um jogo balançaado
@export var launch_force_multiplier: float = 8.0 
@export var max_pull_distance: float = 150.0      

# Referência às linhas e raycasts dos cubinhos
@onready var line_2d: Line2D = $Line2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

# Texturas para triângulo e círculo
@export var textura_circulo: Texture2D
@export var textura_triangulo: Texture2D

# "void start()"
func _ready() -> void:
	if line_2d:
		line_2d.clear_points()
		line_2d.width = 12.0 

# Função relacionada a física dos cubinhos
func _physics_process(delta: float) -> void:
	# Se acabou de atirar, esperamos ele encostar no chão e parar quase completamente
	if ja_disparou:
	# Na Godot, não é possível criar uma checagem para quando algo está 100% parado, então tive que fazer com que a checagem ocorresse perto
	# Aumentamos um pouco a tolerância para garantir que ele detecte a parada com folga:
		var quase_parado: bool = linear_velocity.length() < 25.0 and abs(angular_velocity) < 2.0
	
		if quase_parado:
			tempo_parado += delta
			if tempo_parado >= 0.2:
				ja_disparou = false
				tempo_parado = 0.0
				print(">>> JOGADOR 1 NOTIFICOU PARADA!")
				if gerenciador:
					gerenciador.finalizar_jogada()
		else:
			tempo_parado = 0.0
			
			
# Isso funciona pois o chão tem muito atrito
func esta_no_chao() -> bool:
	# Se a velocidade vertical for muito alta, ele está caindo/voando rápido
	if abs(linear_velocity.y) > 30.0:
		return false

	# get_colliding_bodies() retorna os corpos físicos que o cubo está tocando agora
	var corpos = get_colliding_bodies()
	return corpos.size() > 0
	
func transformar_em_triangulo() -> void:
	print("Transformando em triângulo!")
	
	# Ajusta a escala do visual se necessário
	sprite_2d.scale = Vector2(0.25, 0.25)
	
	# Carrega a textura do triângulo
	var textura_carregada = load("res://triangle.svg")
	if textura_carregada != null:
		sprite_2d.texture = textura_carregada
	elif textura_triangulo != null:
		sprite_2d.texture = textura_triangulo
	else:
		printerr("ERRO: Não encontrou o arquivo triangle.svg")

	# Não existe colisor triângular na Godot, tivemos que improvisar
	# Cria a colisão triangular usando ConvexPolygonShape2D
	var novo_shape = ConvexPolygonShape2D.new()
	
	# Definimos os 3 cantos do triângulo (Top, Inferior Direito, Inferior Esquerdo)
	# Supondo uma base e altura proporcionais a ~60-80 pixels ao redor do centro:
	var tamanho: float = 60.0 # Ajuste este valor para casar com o tamanho do seu sprite
	# Quase como um dicionário
	novo_shape.points = PackedVector2Array([
		Vector2(0, -tamanho),          # Vértice do topo (apontado para cima)
		Vector2(tamanho, tamanho),     # Canto inferior direito
		Vector2(-tamanho, tamanho)     # Canto inferior esquerdo
	])
	
	collision_shape_2d.shape = novo_shape
			 
func transformar_em_circulo() -> void:
	print("Transformando em círculo!")
	sprite_2d.scale = Vector2(0.8, 0.8) # Ou ajuste para o tamanho proporcional
	
	# Carrega o png diretamente pelo caminho no seu projeto
	# Substitua pelo nome exato do arquivo que você colocou na pasta res://
	# Estas referências terão que mudar caso fomos criando pastas
	var textura_carregada = load("res://circle.png") 
	
	if textura_carregada != null:
		sprite_2d.texture = textura_carregada
	else:
		printerr("ERRO: Não encontrou o arquivo circle.png na pasta res://")

	# Atualiza a colisão para círculo
	var novo_shape = CircleShape2D.new()
	novo_shape.radius =  80.0 # Altere aqui o tamanho real em pixels do raio
	collision_shape_2d.shape = novo_shape

# Função para eventos de I/O
func _input(event: InputEvent) -> void:
	# Se o evento for um botão do mouse e o index ser esquerdo...
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if gerenciador:
				# Turno de 1 ou 2
				var turno_esperado = gerenciador.estado_turno.jogador_1 if numero_jogador == 1 else gerenciador.estado_turno.jogador_2
				if gerenciador.estado_atual != turno_esperado:
					return
			
			var esta_no_chao: bool = get_contact_count() > 0
			# Só pode pular se estiver no chão
			if esta_no_chao:
				var mouse_pos = get_global_mouse_position()
				if mouse_pos.distance_to(global_position) < 45.0:
					is_pulling = true
					click_start_pos = mouse_pos
					print("Jogador ", numero_jogador, " puxando estilingue!")
					
		# Efeito estilingue
		elif not event.pressed and is_pulling:
			is_pulling = false
			
			var release_pos = get_global_mouse_position()
			var pull_vector = release_pos - click_start_pos
			pull_vector = pull_vector.limit_length(max_pull_distance)
			
			var final_impulse = -pull_vector * launch_force_multiplier
			apply_central_impulse(final_impulse)
			
			if line_2d:
				line_2d.clear_points()
			
			ja_disparou = true
			tempo_parado = 0.0
			if gerenciador:
				gerenciador.registrar_disparo()
				
				
# Remove sprite e linha caso morto
func ser_eliminado() -> void:
	# 1. Some visualmente de imediato
	visible = false
	if sprite_2d:
		sprite_2d.visible = false
	if line_2d:
		line_2d.clear_points()
		line_2d.visible = false
		
	# Desativa colisores e física
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)
	freeze = true  # Trava o RigidBody2D
	
	# 3. Remove completamente da cena
	queue_free()

# "void loop()"
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
			
	
