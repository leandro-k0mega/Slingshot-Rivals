# Script de física do jogador 2
extends RigidBody2D

var ultimo_vetor_impulso: Vector2 = Vector2.ZERO

enum Habilidade { NENHUMA, INVERTER_CONTROLES, PULO_EXTRA, MID_AIR, VER_TRAJETORIA }

var habilidade_guardada: Habilidade = Habilidade.NENHUMA
var controles_invertidos: bool = false
var pulo_extra_ativo: bool = false
var pulos_restantes: int = 0
var mid_air_ativo: bool = false
var ver_trajetoria: bool = false

var is_pulling: bool = false
var click_start_pos: Vector2 = Vector2.ZERO
var ja_disparou: bool = false
var tempo_parado: float = 0.0

@export var numero_jogador: int = 2
@export var gerenciador: Node2D

@export var launch_force_multiplier: float = 8.0 
@export var max_pull_distance: float = 150.0      

@onready var line_2d: Line2D = $Line2D_Jogador2
@onready var sprite_2d: Sprite2D = $Sprite2D_Jogador2
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D_Jogador2

@export var textura_circulo: Texture2D
@export var textura_triangulo: Texture2D

func _ready() -> void:
	if line_2d:
		line_2d.clear_points()
		line_2d.width = 10.0

func coletar_habilidade(nova_hab: Habilidade) -> bool:
	if habilidade_guardada != Habilidade.NENHUMA:
		print("Jogador ", numero_jogador, " já possui uma habilidade guardada!")
		return false
	habilidade_guardada = nova_hab
	print("Jogador ", numero_jogador, " guardou a habilidade: ", Habilidade.keys()[nova_hab])
	return true

func ativar_habilidade_guardada() -> void:
	if habilidade_guardada == Habilidade.NENHUMA:
		print("Jogador ", numero_jogador, " tentou usar habilidade, mas o inventário está vazio!")
		return
		
	match habilidade_guardada:
		Habilidade.INVERTER_CONTROLES:
			if gerenciador:
				gerenciador.aplicar_inversao_no_oponente(numero_jogador)
		Habilidade.PULO_EXTRA:
			pulo_extra_ativo = true
			print(">>> Jogador ", numero_jogador, " ativou com sucesso o Pulo Extra!")
		Habilidade.MID_AIR:
			mid_air_ativo = true
			print("Jogador ", numero_jogador, " ativou Mid-Air!")
		Habilidade.VER_TRAJETORIA:
			ver_trajetoria = true
			print("Jogador ", numero_jogador, " ativou Ver Trajetória!")
			
	habilidade_guardada = Habilidade.NENHUMA

func limpar_efeitos_do_turno() -> void:
	controles_invertidos = false
	pulo_extra_ativo = false
	pulos_restantes = 0
	mid_air_ativo = false
	ver_trajetoria = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			# CASO 1: Está voando e possui a habilidade MID_AIR guardada
			if ja_disparou and get_contact_count() == 0:
				if habilidade_guardada == Habilidade.MID_AIR:
					executar_impulso_mid_air()
					return
			
			# CASO 2: Uso normal das outras habilidades no chão
			if e_minha_vez():
				ativar_habilidade_guardada()
				
func executar_impulso_mid_air() -> void:
	print(">>> JOGADOR ", numero_jogador, " EXECUTOU PULO MID-AIR NO AR!")
	habilidade_guardada = Habilidade.NENHUMA # Consome o item do inventário
	
	# Zera a gravidade e inércia de queda atual antes do impulso para não anular a força
	linear_velocity = Vector2.ZERO
	
	# Aplica o impulso na mesma direção e intensidade do disparo anterior
	# (Se quiser um turbo mais forte ou mais fraco, multiplique por 1.2 ou 0.8)
	apply_central_impulse(ultimo_vetor_impulso * 1.1)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not e_minha_vez():
				return
			
			var pode_pular = (get_contact_count() > 0) or mid_air_ativo
			if pode_pular:
				var mouse_pos = get_global_mouse_position()
				if mouse_pos.distance_to(global_position) < 45.0:
					is_pulling = true
					click_start_pos = mouse_pos
					if controles_invertidos:
						print("Aviso: Seus controles estão INVERTIDOS neste turno!")
					
		elif not event.pressed and is_pulling:
			is_pulling = false
			
			var release_pos = get_global_mouse_position()
			var pull_vector = release_pos - click_start_pos
			pull_vector = pull_vector.limit_length(max_pull_distance)
			
			# Se invertido: inverte a direção de lançamento
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
			if gerenciador:
				gerenciador.registrar_disparo()

func e_minha_vez() -> bool:
	if gerenciador == null:
		return false
	var turno_esperado = gerenciador.estado_turno.jogador_1 if numero_jogador == 1 else gerenciador.estado_turno.jogador_2
	return gerenciador.estado_atual == turno_esperado

func _physics_process(delta: float) -> void:
	if ja_disparou:
		var quase_parado: bool = linear_velocity.length() < 25.0 and abs(angular_velocity) < 2.0
		if quase_parado:
			tempo_parado += delta
			if tempo_parado >= 0.2:
				ja_disparou = false
				tempo_parado = 0.0
				print(">>> Jogador ", numero_jogador, " parou no chão.")
				if gerenciador:
					gerenciador.finalizar_jogada()
		else:
			tempo_parado = 0.0

func _process(_delta: float) -> void:
	if is_pulling and line_2d:
		desenhar_mira_ou_trajetoria()
	elif line_2d:
		line_2d.clear_points()

func desenhar_mira_ou_trajetoria() -> void:
	line_2d.clear_points()
	var current_mouse = get_global_mouse_position()
	var pull_vector = (current_mouse - click_start_pos).limit_length(max_pull_distance)
	
	var direcao_lancamento = pull_vector if controles_invertidos else -pull_vector

	if ver_trajetoria:
		var gravidade = ProjectSettings.get_setting("physics/2d/default_gravity") * gravity_scale
		var vel_inicial = direcao_lancamento * launch_force_multiplier
		var simulated_pos = Vector2.ZERO
		var step_time = 0.04
		
		for i in range(25):
			line_2d.add_point(simulated_pos)
			simulated_pos += vel_inicial * step_time
			vel_inicial.y += gravidade * step_time
	else:
		# Desenha a linha apontando para onde o cubo realmente vai voar
		var local_target = to_local(global_position + (direcao_lancamento.normalized() * pull_vector.length() * 1.2))
		line_2d.add_point(Vector2.ZERO)
		line_2d.add_point(local_target)

func ser_eliminado() -> void:
	visible = false
	if line_2d:
		line_2d.clear_points()
		line_2d.visible = false
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)
	freeze = true
	queue_free()
