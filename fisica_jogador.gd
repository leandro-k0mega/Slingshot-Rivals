extends RigidBody2D

# --- Identificação e Referências ---
@export var numero_jogador: int = 1
@export var gerenciador: Node2D

@export_group("Força do Estilingue")
@export var launch_force_multiplier: float = 8.0
@export var max_pull_distance: float = 150.0

@export_group("Vida e Status")
@export var vida_maxima: int = 3
var vida_atual: int = 3

@export_group("Visual e Colisões")
@export var textura_quadrado: Texture2D
@export var textura_circulo: Texture2D = preload("res://sprites_oficiais/bola-blue.png")
@export var tamanho_quadrado: Vector2 = Vector2(32, 32)
@export var raio_circulo: float = 16.0

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var line_2d: Line2D = $Line2D
@onready var container_coracoes: Node2D = $Node2D

# --- Variáveis do Estilingue ---
var is_pulling: bool = false
var click_start_pos: Vector2 = Vector2.ZERO
var ja_disparou: bool = false
var tempo_parado: float = 0.0
var ultimo_vetor_impulso: Vector2 = Vector2.ZERO

# --- Inventário e Habilidades ---
enum Habilidade {
	NENHUMA = 0,
	INVERTER_CONTROLES = 1,
	PULO_EXTRA = 2,
	MID_AIR = 3,
	VER_TRAJETORIA = 4,
	TRANSFORMAR_CIRCULO = 5,
	FANTASMAGORIFICAR = 6
}

var habilidade_armazenada: int = Habilidade.NENHUMA
var controles_invertidos: bool = false
var pulo_extra_ativo: bool = false
var mid_air_ativo: bool = false
var ver_trajetoria: bool = false
var esta_em_circulo: bool = false

var shape_quadrado: RectangleShape2D
var shape_circulo: CircleShape2D

func _ready() -> void:
	# Inicializa e notifica corações
	vida_atual = vida_maxima
	if container_coracoes and container_coracoes.has_method("atualizar_vida"):
		container_coracoes.atualizar_vida(vida_atual)

	# Ajusta as formas de colisão aproveitando a da cena ou os valores exportados
	if collision_shape_2d and collision_shape_2d.shape is RectangleShape2D:
		shape_quadrado = collision_shape_2d.shape
		shape_circulo = CircleShape2D.new()
		shape_circulo.radius = shape_quadrado.size.x * 0.5
	else:
		shape_quadrado = RectangleShape2D.new()
		shape_quadrado.size = tamanho_quadrado
		shape_circulo = CircleShape2D.new()
		shape_circulo.radius = raio_circulo
		if collision_shape_2d:
			collision_shape_2d.shape = shape_quadrado

	# Textura padrão inicial
	if sprite_2d and textura_quadrado:
		sprite_2d.texture = textura_quadrado

func _process(_delta: float) -> void:
	if is_pulling:
		desenhar_mira_ou_trajetoria()
	else:
		if line_2d and line_2d.get_point_count() > 0:
			line_2d.clear_points()

func _physics_process(delta: float) -> void:
	if ja_disparou:
		if linear_velocity.length() < 10.0:
			tempo_parado += delta
			if tempo_parado >= 0.5:
				ja_disparou = false
				tempo_parado = 0.0
				if gerenciador and gerenciador.has_method("finalizar_jogada"):
					gerenciador.finalizar_jogada()
		else:
			tempo_parado = 0.0

func _input(event: InputEvent) -> void:
	# 1. Ativação de Habilidade e Teclas de Teste
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			if e_minha_vez():
				usar_habilidade_guardada()
			return
		elif event.keycode == KEY_K:
			print(">>> TECLA K PRESSIONADA: Forçando 1 de dano no Jogador ", numero_jogador)
			receber_dano(1)
			return

	# 2. Mecânica do Estilingue com o Mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not e_minha_vez():
				return
			
			# Se a câmera fantasma estiver ativa, bloqueia o estilingue
			if gerenciador and gerenciador.has_method("is_modo_fantasma_ativo") and gerenciador.is_modo_fantasma_ativo():
				return
			
			# Tolerância: contato com superfície OU repouso físico OU habilidade mid-air
			var esta_parado = linear_velocity.length() < 20.0
			var pode_pular = (get_contact_count() > 0) or esta_parado or mid_air_ativo
			
			if pode_pular:
				var mouse_pos = get_global_mouse_position()
				if mouse_pos.distance_to(global_position) < 80.0:
					is_pulling = true
					click_start_pos = mouse_pos
					
		elif not event.pressed and is_pulling:
			is_pulling = false
			
			var release_pos = get_global_mouse_position()
			var pull_vector = (release_pos - click_start_pos).limit_length(max_pull_distance)
			
			var direcao_lancamento = pull_vector if controles_invertidos else -pull_vector
			var final_impulse = direcao_lancamento * launch_force_multiplier
			
			ultimo_vetor_impulso = final_impulse
			apply_central_impulse(final_impulse)
			
			if mid_air_ativo and get_contact_count() == 0:
				mid_air_ativo = false
				
			if line_2d:
				line_2d.clear_points()
			
			ja_disparou = true
			tempo_parado = 0.0
			if gerenciador and gerenciador.has_method("registrar_disparo"):
				gerenciador.registrar_disparo()

func desenhar_mira_ou_trajetoria() -> void:
	if not line_2d:
		return
		
	line_2d.clear_points()
	var current_mouse = get_global_mouse_position()
	var pull_vector = (current_mouse - click_start_pos).limit_length(max_pull_distance)
	var direcao_lancamento = pull_vector if controles_invertidos else -pull_vector

	if ver_trajetoria:
		var gravidade = ProjectSettings.get_setting("physics/2d/default_gravity") * gravity_scale
		var vel_inicial = direcao_lancamento * launch_force_multiplier
		var simulated_pos = Vector2.ZERO
		var step_time = 0.04
		
		for i in range(20):
			line_2d.add_point(simulated_pos)
			simulated_pos += vel_inicial * step_time
			vel_inicial.y += gravidade * step_time
	else:
		var local_target = to_local(global_position + (direcao_lancamento.normalized() * pull_vector.length() * 1.2))
		line_2d.add_point(Vector2.ZERO)
		line_2d.add_point(local_target)

# --- Gerenciamento de Turnos e Habilidades ---

func e_minha_vez() -> bool:
	if not gerenciador:
		return false
	return (gerenciador.estado_atual == gerenciador.estado_turno.jogador_1 and numero_jogador == 1) or \
		   (gerenciador.estado_atual == gerenciador.estado_turno.jogador_2 and numero_jogador == 2)

func coletar_habilidade(tipo: int) -> bool:
	if habilidade_armazenada == Habilidade.NENHUMA:
		habilidade_armazenada = tipo
		print("Jogador ", numero_jogador, " coletou e guardou poder: ", tipo)
		return true
	return false

func usar_habilidade_guardada() -> void:
	if habilidade_armazenada == Habilidade.NENHUMA:
		print(">>> Nenhuma habilidade para usar!")
		return
		
	print(">>> USANDO HABILIDADE ID: ", habilidade_armazenada, " (Nome: ", Habilidade.keys()[habilidade_armazenada], ")")
	
	match habilidade_armazenada:
		Habilidade.INVERTER_CONTROLES:
			if gerenciador and gerenciador.has_method("aplicar_inversao_no_oponente"):
				gerenciador.aplicar_inversao_no_oponente(numero_jogador)
		Habilidade.PULO_EXTRA:
			pulo_extra_ativo = true
			print("Jogador ", numero_jogador, " ativou Pulo Extra!")
		Habilidade.MID_AIR:
			mid_air_ativo = true
			print("Jogador ", numero_jogador, " ativou Mid-Air!")
		Habilidade.VER_TRAJETORIA:
			ver_trajetoria = true
			print("Jogador ", numero_jogador, " ativou Ver Trajetória!")
		Habilidade.TRANSFORMAR_CIRCULO:
			if gerenciador and gerenciador.has_method("aplicar_circulo_no_oponente"):
				gerenciador.aplicar_circulo_no_oponente(numero_jogador)
		Habilidade.FANTASMAGORIFICAR:
			print(">>> Ativou modo fantasma! Câmera liberada, estilingue pausado.")
			if gerenciador and gerenciador.has_method("iniciar_fantasmagorificar"):
				gerenciador.iniciar_fantasmagorificar(self)
			
	habilidade_armazenada = Habilidade.NENHUMA

func transformar_em_circulo(ativo: bool) -> void:
	esta_em_circulo = ativo
	if ativo:
		print(">>> Jogador ", numero_jogador, " virou CÍRCULO!")
		if collision_shape_2d:
			collision_shape_2d.shape = shape_circulo
		if sprite_2d and textura_circulo:
			sprite_2d.texture = textura_circulo
	else:
		print(">>> Jogador ", numero_jogador, " voltou a ser QUADRADO!")
		if collision_shape_2d:
			collision_shape_2d.shape = shape_quadrado
		if sprite_2d and textura_quadrado:
			sprite_2d.texture = textura_quadrado

func limpar_efeitos_do_turno() -> void:
	controles_invertidos = false
	pulo_extra_ativo = false
	mid_air_ativo = false
	ver_trajetoria = false
	if esta_em_circulo:
		transformar_em_circulo(false)

func receber_dano(quantidade: int = 1) -> void:
	vida_atual = clampi(vida_atual - quantidade, 0, vida_maxima)
	print("Jogador ", numero_jogador, " tomou dano! Vida restante: ", vida_atual)
	
	if container_coracoes and container_coracoes.has_method("atualizar_vida"):
		container_coracoes.atualizar_vida(vida_atual)
		
	if vida_atual <= 0:
		ser_eliminado()

func ser_eliminado() -> void:
	visible = false
	set_physics_process(false)
	set_process_input(false)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
