extends Node2D

var vida_p1: int = 3
var vida_p2: int = 3

enum estado_turno {jogador_1, jogador_2, processando_jogada, game_over}
var estado_atual: estado_turno = estado_turno.jogador_1
var proximo_turno: estado_turno = estado_turno.jogador_2

@onready var timer_turno: Timer = $Timer

# Referências aos nós físicos dos jogadores na cena para poder dar queue_free()
@export var jogador_1_node: RigidBody2D
@export var jogador_2_node: RigidBody2D

func _ready() -> void:
	if timer_turno:
		timer_turno.timeout.connect(_on_timer_timeout)
	iniciar_turno()

# --- TESTE VIA TECLADO: K (Jogador 1) e L (Jogador 2) ---
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			print("[TESTE] Tecla K pressionada: Removendo vida do Jogador 1")
			remover_vida(1)
		elif event.keycode == KEY_L:
			print("[TESTE] Tecla L pressionada: Removendo vida do Jogador 2")
			remover_vida(2)

func remover_vida(jogador: int, posicao_morte: Vector2 = Vector2.ZERO) -> void:
	if estado_atual == estado_turno.game_over:
		return
		
	if jogador == 1:
		vida_p1 = maxi(0, vida_p1 - 1)
		print("Jogador 1 perdeu 1 vida! Vidas restantes: ", vida_p1)
		if vida_p1 == 0:
			print(">>> Jogador 1 foi ELIMINADO!")
			if jogador_1_node and is_instance_valid(jogador_1_node):
				if jogador_1_node.has_method("ser_eliminado"):
					jogador_1_node.ser_eliminado()
				else:
					jogador_1_node.queue_free()
			verificar_condicao_vitoria()
			if estado_atual == estado_turno.jogador_1:
				alterar_turno()
		else:
			respawn_jogador(1, posicao_morte)
	
	elif jogador == 2:
		vida_p2 = maxi(0, vida_p2 - 1)
		print("Jogador 2 perdeu 1 vida! Vidas restantes: ", vida_p2)
		if vida_p2 == 0:
			print(">>> Jogador 2 foi ELIMINADO!")
			if jogador_2_node and is_instance_valid(jogador_2_node):
				if jogador_2_node.has_method("ser_eliminado"):
					jogador_2_node.ser_eliminado()
				else:
					jogador_2_node.queue_free()
			verificar_condicao_vitoria()
			if estado_atual == estado_turno.jogador_2:
				alterar_turno()

func verificar_condicao_vitoria() -> void:
	if vida_p1 == 0 and vida_p2 == 0:
		estado_atual = estado_turno.game_over
		if timer_turno:
			timer_turno.stop()
		print("GAME OVER: AMBOS OS JOGADORES FORAM ELIMINADOS!")
	elif vida_p1 == 0:
		print("Jogador 2 agora está jogando sozinho!")
		estado_atual = estado_turno.jogador_2
		proximo_turno = estado_turno.jogador_2
	elif vida_p2 == 0:
		print("Jogador 1 agora está jogando sozinho!")
		estado_atual = estado_turno.jogador_1
		proximo_turno = estado_turno.jogador_1

func iniciar_turno() -> void:
	if estado_atual == estado_turno.game_over:
		return
	
	# Se alguém estiver morto, força o turno para quem sobreviveu
	if vida_p1 == 0 and vida_p2 > 0:
		estado_atual = estado_turno.jogador_2
		proximo_turno = estado_turno.jogador_2
	elif vida_p2 == 0 and vida_p1 > 0:
		estado_atual = estado_turno.jogador_1
		proximo_turno = estado_turno.jogador_1
	else:
		# Ambos vivos: alterna normalmente
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
	estado_atual = estado_turno.processando_jogada

func finalizar_jogada() -> void:
	if estado_atual == estado_turno.game_over:
		return
	
	# Se o outro jogador estiver morto, a próxima jogada continua sendo do sobrevivente!
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
		
	if vida_p1 > 0 and vida_p2 > 0:
		if estado_atual == estado_turno.jogador_1:
			estado_atual = estado_turno.jogador_2
		elif estado_atual == estado_turno.jogador_2:
			estado_atual = estado_turno.jogador_1
	iniciar_turno()

func _on_timer_timeout() -> void:
	print("TEMPO ESGOTADO!")
	if estado_atual == estado_turno.jogador_1:
		remover_vida(1)
	elif estado_atual == estado_turno.jogador_2:
		remover_vida(2)
	alterar_turno()

func respawn_jogador(jogador: int, posicao_morte: Vector2) -> void:
	var plataformas = get_tree().get_nodes_in_group("Plataformas")
	var plataforma_segura: Node2D = null
	var menor_distancia: float = INF
	
	for plat in plataformas:
		if plat.has_method("is_fantasma") and plat.is_fantasma():
			continue
		if plat.global_position.y < posicao_morte.y:
			var dist = posicao_morte.distance_to(plat.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				plataforma_segura = plat
				
	if plataforma_segura != null:
		var target_player = jogador_1_node if jogador == 1 else jogador_2_node
		if target_player and is_instance_valid(target_player):
			target_player.global_position = plataforma_segura.global_position + Vector2(0, -50)
			target_player.linear_velocity = Vector2.ZERO
			target_player.angular_velocity = 0.0
			print("Jogador ", jogador, " teleportado com sucesso!")
