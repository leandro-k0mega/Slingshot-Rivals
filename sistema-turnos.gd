extends Node2D

var vida_p2: int = 3
var vida_p1: int = 3
enum estado_turno {jogador_1, jogador_2, processando_jogada, game_over}
var estado_atual: estado_turno = estado_turno.jogador_1
@onready var timer_turno: Timer = $Timer


func respawn_jogador(jogador: int, posicao_morte: Vector2) -> void:
	var plataformas = get_tree().get_nodes_in_group("Plataformas")
	var plataforma_segura: Node2D = null
	var menor_distancia: float = INF
	
	for plat in plataformas:
		if plat.has.method("is_fantasma") and plat.is_fantasma():
			continue
			
		if plat.global_position.y < posicao_morte.y:
			var dist = posicao_morte.distance_to(plat.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				plataforma_segura = plat
				
	if plataforma_segura != null:
		print("Teleportando Jogador ", jogador, " para plataforma segura em: ", plataforma_segura.global_position)
	else:
		print("Nenhuma plataforma segura encontrada acima da água!")


func remover_vida(jogador: int, posicao_morte: Vector2 = Vector2.ZERO) -> void:
	if estado_atual == estado_turno.game_over:
		return
		
	if jogador == 1:
		vida_p1 = maxi(0, vida_p1 - 1)
		print("Jogador 1 perdeu 1 vida! Vidas restantes: ", vida_p1)
		if vida_p1 == 0:
			print("Jogador 1 foi eliminado!")
			verificar_condicao_vitoria()
		else:
			respawn_jogador(1, posicao_morte)
	
	elif jogador == 2:
		vida_p2 = maxi(0, vida_p2 - 1)
		print("Jogador 2 perdeu 1 vida! Vidas restantes: ", vida_p2)
		if vida_p2 == 0:
			print("Jogador 2 foi eliminado!")
			verificar_condicao_vitoria()
		else:
			respawn_jogador(2, posicao_morte)


func verificar_condicao_vitoria() -> void:
	if  vida_p1 == 0 and vida_p2 == 0:
		estado_atual = estado_turno.game_over
		timer_turno.stop()
		print("GAME OVER: AMBOS OS JOGADORES FORAM ELIMINADOS!")
		
	elif vida_p1 == 0:
		print("Jogador 2 agora está jogando sozinho para alcançar o topo!")
		estado_atual = estado_turno.jogador_2
		
	elif vida_p2 == 0:
		print("Jogador 1 agora está jogando sozinho para alcanãr o topo!")
		estado_atual = estado_turno.jogador_1


func _ready() -> void:
	timer_turno.timeout.connect(_on_timer_timeout)
	iniciar_turno()


func iniciar_turno() -> void:
	if estado_atual == estado_turno.game_over:
		return
	
	if estado_atual == estado_turno.jogador_1 and vida_p1 == 0:
		estado_atual = estado_turno.jogador_2
	elif estado_atual == estado_turno.jogador_2 and vida_p2 == 0:
		estado_atual = estado_turno.jogador_1
	
	if estado_atual == estado_turno.jogador_1:
		print("TURNO DO JOGADOR 1")
		
	elif estado_atual == estado_turno.jogador_2:
		print("TURNO DO JOGADOR 2")
		
	timer_turno.start(15.0)


func alterar_turno() -> void:
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
	print("TEMPO ESGOTADO! TROCANDO DE TURNO...")
	if estado_atual == estado_turno.jogador_1:
		remover_vida(1)
	elif estado_atual == estado_turno.jogador_2:
		remover_vida(2)
	alterar_turno()
