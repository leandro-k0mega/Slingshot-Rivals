extends Node2D

@export var camera_fantasma: Camera2D
@export var camera_principal: Camera2D # A câmera do jogo normal

var em_modo_fantasma: bool = false
var jogador_fantasma_ativo: RigidBody2D = null

var jogador_ativo_no_disparo: int = 1

var vida_p1: int = 3
var vida_p2: int = 3

enum estado_turno { jogador_1, jogador_2, processando_jogada, game_over }
var estado_atual: estado_turno = estado_turno.jogador_1
var proximo_turno: estado_turno = estado_turno.jogador_2

@onready var timer_turno: Timer = $Timer

@export var agua_node: Area2D # Arraste o nó da água aqui no Inspetor
@export var hud_vidas: Control # Arraste o nó HUD/Control aqui no Inspetor
@export var jogador_1_node: RigidBody2D
@export var jogador_2_node: RigidBody2D

func _ready() -> void:
	if timer_turno:
		# Conecta com a função correta
		timer_turno.timeout.connect(_on_timer_turno_timeout)
	iniciar_turno()

func is_modo_fantasma_ativo() -> bool:
	return em_modo_fantasma

func iniciar_fantasmagorificar(jogador: RigidBody2D) -> void:
	em_modo_fantasma = true
	jogador_fantasma_ativo = jogador
	if timer_turno:
		timer_turno.paused = true
	if camera_fantasma and camera_fantasma.has_method("ativar_modo_fantasma"):
		camera_fantasma.ativar_modo_fantasma(camera_principal)

func finalizar_uso_fantasmagorificar() -> void:
	em_modo_fantasma = false
	if timer_turno:
		timer_turno.paused = false
	print(">>> Plataforma selecionada com sucesso! Turno segue normalmente.")

func atualizar_plataformas_fantasmas() -> void:
	var plataformas = get_tree().get_nodes_in_group("Plataformas")
	for plat in plataformas:
		if plat.has_method("processar_passagem_turno"):
			plat.processar_passagem_turno()

# --- Comandos de teste de dano (K / L) ---
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			remover_vida(1)
		elif event.keycode == KEY_L:
			remover_vida(2)

func iniciar_turno() -> void:
	if estado_atual == estado_turno.game_over:
		return
	
	if estado_atual == estado_turno.jogador_1:
		if agua_node and agua_node.has_method("subir_agua"):
			agua_node.subir_agua()
	elif (vida_p1 == 0 or vida_p2 == 0) and agua_node and agua_node.has_method("subir_agua"):
		agua_node.subir_agua()
	
	if vida_p1 == 0 and vida_p2 > 0:
		estado_atual = estado_turno.jogador_2
		proximo_turno = estado_turno.jogador_2
	elif vida_p2 == 0 and vida_p1 > 0:
		estado_atual = estado_turno.jogador_1
		proximo_turno = estado_turno.jogador_1
	else:
		if estado_atual == estado_turno.jogador_1:
			proximo_turno = estado_turno.jogador_2
		elif estado_atual == estado_turno.jogador_2:
			proximo_turno = estado_turno.jogador_1

	if estado_atual == estado_turno.jogador_1:
		print("--- TURNO DO JOGADOR 1 ---")
	elif estado_atual == estado_turno.jogador_2:
		print("--- TURNO DO JOGADOR 2 ---")
		
	if timer_turno:
		timer_turno.start(15.0)

func registrar_disparo() -> void:
	if timer_turno:
		timer_turno.stop()
	
	if estado_atual == estado_turno.jogador_1:
		jogador_ativo_no_disparo = 1
	elif estado_atual == estado_turno.jogador_2:
		jogador_ativo_no_disparo = 2
		
	estado_atual = estado_turno.processando_jogada

func finalizar_jogada() -> void:
	if estado_atual == estado_turno.game_over:
		return
	
	var autor_do_tiro = jogador_1_node if jogador_ativo_no_disparo == 1 else jogador_2_node
	
	if autor_do_tiro and is_instance_valid(autor_do_tiro) and autor_do_tiro.pulo_extra_ativo:
		autor_do_tiro.pulo_extra_ativo = false
		estado_atual = estado_turno.jogador_1 if jogador_ativo_no_disparo == 1 else estado_turno.jogador_2
		if timer_turno:
			timer_turno.start(15.0)
		return

	if autor_do_tiro and is_instance_valid(autor_do_tiro):
		autor_do_tiro.limpar_efeitos_do_turno()
	
	if vida_p1 == 0 and vida_p2 > 0:
		estado_atual = estado_turno.jogador_2
	elif vida_p2 == 0 and vida_p1 > 0:
		estado_atual = estado_turno.jogador_1
	else:
		estado_atual = proximo_turno
		
	iniciar_turno()

func alterar_turno() -> void:
	if timer_turno:
		timer_turno.stop()
	if estado_atual == estado_turno.game_over:
		return
	
	var quem_jogou = jogador_ativo_no_disparo if estado_atual == estado_turno.processando_jogada else (1 if estado_atual == estado_turno.jogador_1 else 2)
	var autor_node = jogador_1_node if quem_jogou == 1 else jogador_2_node
	
	if autor_node and is_instance_valid(autor_node):
		autor_node.limpar_efeitos_do_turno()
	
	if vida_p1 > 0 and vida_p2 > 0:
		estado_atual = estado_turno.jogador_2 if quem_jogou == 1 else estado_turno.jogador_1
	elif vida_p1 == 0 and vida_p2 > 0:
		estado_atual = estado_turno.jogador_2
	elif vida_p2 == 0 and vida_p1 > 0:
		estado_atual = estado_turno.jogador_1
		
	iniciar_turno()

func limpar_efeitos_jogadores() -> void:
	if jogador_1_node and is_instance_valid(jogador_1_node):
		jogador_1_node.limpar_efeitos_do_turno()
	if jogador_2_node and is_instance_valid(jogador_2_node):
		jogador_2_node.limpar_efeitos_do_turno()

# --- Timeout de 15s: Apenas passa a vez sem matar ---
func _on_timer_turno_timeout() -> void:
	print("Tempo de 15s esgotado! Nenhuma ação realizada. Passando a vez...")
	
	# Cancela mira caso estivesse puxando o estilingue
	if jogador_1_node and is_instance_valid(jogador_1_node) and jogador_1_node.is_pulling:
		jogador_1_node.is_pulling = false
		if jogador_1_node.line_2d:
			jogador_1_node.line_2d.clear_points()
			
	if jogador_2_node and is_instance_valid(jogador_2_node) and jogador_2_node.is_pulling:
		jogador_2_node.is_pulling = false
		if jogador_2_node.line_2d:
			jogador_2_node.line_2d.clear_points()

	# Limpa efeitos de turno do jogador atual
	if estado_atual == estado_turno.jogador_1 and jogador_1_node and is_instance_valid(jogador_1_node):
		jogador_1_node.limpar_efeitos_do_turno()
	elif estado_atual == estado_turno.jogador_2 and jogador_2_node and is_instance_valid(jogador_2_node):
		jogador_2_node.limpar_efeitos_do_turno()

	alterar_turno()

func remover_vida(jogador: int, posicao_morte: Vector2 = Vector2.ZERO) -> void:
	if estado_atual == estado_turno.game_over:
		return
		
	if jogador == 1:
		vida_p1 = maxi(0, vida_p1 - 1)
		print("Jogador 1 perdeu vida! Restam: ", vida_p1)
		
		if hud_vidas and hud_vidas.has_method("atualizar_vidas"):
			hud_vidas.atualizar_vidas("azul", vida_p1)
			
		if vida_p1 == 0:
			print("Jogador 1 foi eliminado!")
			if jogador_1_node and is_instance_valid(jogador_1_node):
				jogador_1_node.ser_eliminado()
			verificar_condicao_vitoria()
			if estado_atual != estado_turno.game_over:
				alterar_turno()
		else:
			respawn_jogador(1, posicao_morte)
			processar_pos_queda_agua(jogador_1_node)
	
	elif jogador == 2:
		vida_p2 = maxi(0, vida_p2 - 1)
		print("Jogador 2 perdeu vida! Restam: ", vida_p2)
		
		if hud_vidas and hud_vidas.has_method("atualizar_vidas"):
			hud_vidas.atualizar_vidas("vermelho", vida_p2)
			
		if vida_p2 == 0:
			print("Jogador 2 foi eliminado!")
			if jogador_2_node and is_instance_valid(jogador_2_node):
				jogador_2_node.ser_eliminado()
			verificar_condicao_vitoria()
			if estado_atual != estado_turno.game_over:
				alterar_turno()
		else:
			respawn_jogador(2, posicao_morte)
			processar_pos_queda_agua(jogador_2_node)

func processar_pos_queda_agua(jogador_node: RigidBody2D) -> void:
	if jogador_node and is_instance_valid(jogador_node) and jogador_node.pulo_extra_ativo:
		jogador_node.pulo_extra_ativo = false
		print(">>> Pulo extra consumido após cair na água! Turno MANTIDO para o Jogador ", jogador_node.numero_jogador)
		
		estado_atual = estado_turno.jogador_1 if jogador_node.numero_jogador == 1 else estado_turno.jogador_2
		if timer_turno:
			timer_turno.start(15.0)
	else:
		print(">>> Jogador caiu na água sem pulo extra. Passando o turno...")
		alterar_turno()

func aplicar_circulo_no_oponente(jogador_que_usou: int) -> void:
	var alvo = jogador_2_node if jogador_que_usou == 1 else jogador_1_node
	
	if alvo and is_instance_valid(alvo):
		if alvo.has_method("transformar_em_circulo"):
			alvo.transformar_em_circulo(true)
			print(">>> GERENCIADOR: Jogador ", alvo.numero_jogador, " virou CÍRCULO!")
		else:
			push_error("ERRO: O nó do jogador alvo não tem o método transformar_em_circulo!")
	else:
		push_error("ERRO: jogador_1_node ou jogador_2_node está VAZIO no Inspetor do Gerenciador!")

func verificar_condicao_vitoria() -> void:
	if vida_p1 == 0 and vida_p2 == 0:
		estado_atual = estado_turno.game_over
		if timer_turno:
			timer_turno.stop()
		print("GAME OVER - EMPATE!")
	elif vida_p1 == 0:
		if vida_p2 > 0:
			estado_atual = estado_turno.jogador_2
			proximo_turno = estado_turno.jogador_2
	elif vida_p2 == 0:
		if vida_p1 > 0:
			estado_atual = estado_turno.jogador_1
			proximo_turno = estado_turno.jogador_1

func respawn_jogador(jogador: int, posicao_queda: Vector2) -> void:
	var plataformas = get_tree().get_nodes_in_group("Plataformas")
	
	if plataformas.is_empty():
		push_warning("ATENÇÃO: Nenhuma plataforma foi encontrada no grupo 'Plataformas'!")
		return
	
	var plataforma_segura: Node2D = null
	var menor_distancia: float = INF
	
	var outro_jogador = jogador_2_node if jogador == 1 else jogador_1_node
	var pos_outro_jogador = Vector2.INF
	if outro_jogador and is_instance_valid(outro_jogador) and outro_jogador.visible:
		pos_outro_jogador = outro_jogador.global_position
	
	for plat in plataformas:
		if plat.has_method("is_fantasma") and plat.is_fantasma():
			continue
			
		if plat.global_position.y < posicao_queda.y:
			if pos_outro_jogador != Vector2.INF:
				if plat.global_position.distance_to(pos_outro_jogador) < 60.0:
					continue
			
			var dist = posicao_queda.distance_to(plat.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				plataforma_segura = plat
				
	var alvo_player: RigidBody2D = jogador_1_node if jogador == 1 else jogador_2_node
	
	if alvo_player and is_instance_valid(alvo_player):
		var nova_pos: Vector2
		if plataforma_segura != null:
			nova_pos = plataforma_segura.global_position + Vector2(0, -45)
			print(">>> Teleportando Jogador ", jogador, " para plataforma em: ", nova_pos)
		else:
			nova_pos = Vector2(posicao_queda.x, posicao_queda.y - 150)
			print(">>> Nenhuma plataforma livre encontrada. Usando ponto de emergência.")

		var transform_atual = alvo_player.global_transform
		transform_atual.origin = nova_pos
		
		PhysicsServer2D.body_set_state(alvo_player.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, transform_atual)
		PhysicsServer2D.body_set_state(alvo_player.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
		PhysicsServer2D.body_set_state(alvo_player.get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
		
		alvo_player.linear_velocity = Vector2.ZERO
		alvo_player.angular_velocity = 0.0
		alvo_player.ja_disparou = false
		alvo_player.tempo_parado = 0.0

func aplicar_inversao_no_oponente(jogador_que_usou: int) -> void:
	var oponente = jogador_2_node if jogador_que_usou == 1 else jogador_1_node
	if oponente and is_instance_valid(oponente):
		oponente.controles_invertidos = true
		print(">>> Controles do Jogador ", oponente.numero_jogador, " FORAM INVERTIDOS para o próximo turno!")
