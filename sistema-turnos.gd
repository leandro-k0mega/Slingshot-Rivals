extends Node2D

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
		timer_turno.timeout.connect(_on_timer_timeout)
	iniciar_turno()

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
	
	# Verifica se uma rodada completa começou (ex: vez do Jogador 1)
	if estado_atual == estado_turno.jogador_1:
		if agua_node and agua_node.has_method("subir_agua"):
			agua_node.subir_agua()
	
	# (Se um dos jogadores estiver morto e jogando sozinho, a água sobe a cada pulo dele)
	elif (vida_p1 == 0 or vida_p2 == 0) and agua_node and agua_node.has_method("subir_agua"):
		agua_node.subir_agua()
	
	# Redireciona caso alguém tenha sido eliminado
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
	
	# Memoriza com certeza quem acabou de atirar antes de virar "processando_jogada"
	if estado_atual == estado_turno.jogador_1:
		jogador_ativo_no_disparo = 1
	elif estado_atual == estado_turno.jogador_2:
		jogador_ativo_no_disparo = 2
		
	estado_atual = estado_turno.processando_jogada

func finalizar_jogada() -> void:
	if estado_atual == estado_turno.game_over:
		return
	
	var autor_do_tiro = jogador_1_node if jogador_ativo_no_disparo == 1 else jogador_2_node
	
	# Pulo Extra
	if autor_do_tiro and is_instance_valid(autor_do_tiro) and autor_do_tiro.pulo_extra_ativo:
		autor_do_tiro.pulo_extra_ativo = false
		estado_atual = estado_turno.jogador_1 if jogador_ativo_no_disparo == 1 else estado_turno.jogador_2
		if timer_turno:
			timer_turno.start(15.0)
		return

	# LIMPEZA CORRETA: Limpa apenas os efeitos de quem acabou de disparar!
	# (Não mexemos no adversário para não remover a inversão de controle dele antes da hora)
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
	
	limpar_efeitos_jogadores()
	
	if vida_p1 > 0 and vida_p2 > 0:
		if estado_atual == estado_turno.jogador_1:
			estado_atual = estado_turno.jogador_2
		elif estado_atual == estado_turno.jogador_2:
			estado_atual = estado_turno.jogador_1
	iniciar_turno()

func limpar_efeitos_jogadores() -> void:
	if jogador_1_node and is_instance_valid(jogador_1_node):
		jogador_1_node.limpar_efeitos_do_turno()
	if jogador_2_node and is_instance_valid(jogador_2_node):
		jogador_2_node.limpar_efeitos_do_turno()

func _on_timer_timeout() -> void:
	print("TEMPO ESGOTADO!")
	if estado_atual == estado_turno.jogador_1:
		remover_vida(1)
	elif estado_atual == estado_turno.jogador_2:
		remover_vida(2)
	alterar_turno()

func remover_vida(jogador: int, posicao_morte: Vector2 = Vector2.ZERO) -> void:
	if estado_atual == estado_turno.game_over:
		return
		
	if jogador == 1:
		vida_p1 = maxi(0, vida_p1 - 1)
		print("Jogador 1 perdeu vida! Vidas restantes: ", vida_p1)
		
		if hud_vidas and hud_vidas.has_method("atualizar_vidas"):
			hud_vidas.atualizar_vidas("azul", vida_p1)
			
		if vida_p1 == 0:
			print("Jogador 1 foi eliminado!")
			if jogador_1_node and is_instance_valid(jogador_1_node):
				jogador_1_node.ser_eliminado()
			verificar_condicao_vitoria()
			if estado_atual == estado_turno.jogador_1:
				alterar_turno()
		else:
			# AINDA ESTÁ VIVO: Teleporta para a plataforma segura e livre!
			respawn_jogador(1, posicao_morte)
			# Se caiu no próprio turno, encerra o tiro e passa a vez
			if estado_atual == estado_turno.processando_jogada or estado_atual == estado_turno.jogador_1:
				alterar_turno()
	
	elif jogador == 2:
		vida_p2 = maxi(0, vida_p2 - 1)
		print("Jogador 2 perdeu vida! Vidas restantes: ", vida_p2)
		
		if hud_vidas and hud_vidas.has_method("atualizar_vidas"):
			hud_vidas.atualizar_vidas("vermelho", vida_p2)
			
		if vida_p2 == 0:
			print("Jogador 2 foi eliminado!")
			if jogador_2_node and is_instance_valid(jogador_2_node):
				jogador_2_node.ser_eliminado()
			verificar_condicao_vitoria()
			if estado_atual == estado_turno.jogador_2:
				alterar_turno()
		else:
			# AINDA ESTÁ VIVO: Teleporta para a plataforma segura e livre!
			respawn_jogador(2, posicao_morte)
			if estado_atual == estado_turno.processando_jogada or estado_atual == estado_turno.jogador_2:
				alterar_turno()

func verificar_condicao_vitoria() -> void:
	if vida_p1 == 0 and vida_p2 == 0:
		estado_atual = estado_turno.game_over
		if timer_turno:
			timer_turno.stop()
		print("GAME OVER!")
	elif vida_p1 == 0:
		estado_atual = estado_turno.jogador_2
		proximo_turno = estado_turno.jogador_2
	elif vida_p2 == 0:
		estado_atual = estado_turno.jogador_1
		proximo_turno = estado_turno.jogador_1

func respawn_jogador(jogador: int, posicao_queda: Vector2) -> void:
	var plataformas = get_tree().get_nodes_in_group("Plataforma")
	var plataforma_segura: Node2D = null
	var menor_distancia: float = INF
	
	# Identifica o oponente para checar se uma plataforma já está ocupada
	var outro_jogador = jogador_2_node if jogador == 1 else jogador_1_node
	var pos_outro_jogador = Vector2.INF
	if outro_jogador and is_instance_valid(outro_jogador) and outro_jogador.visible:
		pos_outro_jogador = outro_jogador.global_position
	
	for plat in plataformas:
		# 1. Ignora plataformas fantasmas (sem colisão física)
		if plat.has_method("is_fantasma") and plat.is_fantasma():
			continue
			
		# 2. Deve estar acima do ponto onde o jogador caiu
		# (Lembre-se: no 2D da Godot, Y menor = mais alto na tela)
		if plat.global_position.y < posicao_queda.y:
			# 3. Verifica se o adversário NÃO está ocupando essa plataforma
			if pos_outro_jogador != Vector2.INF:
				var dist_ao_outro = plat.global_position.distance_to(pos_outro_jogador)
				if dist_ao_outro < 55.0: # Raio de ocupação da plataforma
					continue # Pula esta plataforma pois o outro player está lá
			
			# 4. Encontra a mais próxima do ponto da queda
			var dist = posicao_queda.distance_to(plat.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				plataforma_segura = plat
				
	# Aplica o teleporte no cubo correto
	var alvo_player = jogador_1_node if jogador == 1 else jogador_2_node
	if alvo_player and is_instance_valid(alvo_player):
		if plataforma_segura != null:
			print("Teleportando Jogador ", jogador, " para plataforma livre em: ", plataforma_segura.global_position)
			alvo_player.global_position = plataforma_segura.global_position + Vector2(0, -45)
		else:
			# Fallback: Se nenhuma plataforma foi encontrada, sobe 120 pixels acima do ponto da queda
			print("Aviso: Nenhuma plataforma livre encontrada acima da água. Usando posição segura de emergência.")
			alvo_player.global_position = Vector2(posicao_queda.x, posicao_queda.y - 120)
		
		# Zera completamente a física para ele nascer sem impulso
		alvo_player.linear_velocity = Vector2.ZERO
		alvo_player.angular_velocity = 0.0
		alvo_player.ja_disparou = false
		alvo_player.tempo_parado = 0.0

# Aplica efeito ofensivo no oponente
func aplicar_inversao_no_oponente(jogador_que_usou: int) -> void:
	var oponente = jogador_2_node if jogador_que_usou == 1 else jogador_1_node
	if oponente and is_instance_valid(oponente):
		oponente.controles_invertidos = true
		print(">>> Controles do Jogador ", oponente.numero_jogador, " FORAM INVERTIDOS para o próximo turno!")
