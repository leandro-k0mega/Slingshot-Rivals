extends Node2D

enum estado_turno {jogador_1, jogador_2, processando_jogada, game_over}
var estado_atual: estado_turno = estado_turno.jogador_1

@onready var timer_turno: Timer = $Timer


func _ready() -> void:
	timer_turno.timeout.connect(_on_timer_timeout)
	iniciar_turno()


func iniciar_turno() -> void:
	if estado_atual == estado_turno.jogador_1:
		print("TURNO DO JOGADOR 1")
		
	elif estado_atual == estado_turno.jogador_2:
		print("TURNO DO JOGADOR 2")
		
	timer_turno.start(15.0)


func alterar_turno() -> void:
	timer_turno.stop()
	
	if estado_atual == estado_turno.jogador_1:
		estado_atual = estado_turno.jogador_2
	elif estado_atual == estado_turno.jogador_2:
		estado_atual = estado_turno.jogador_1
		
	iniciar_turno()


func _on_timer_timeout() -> void:
	print("TEMPO ESGOTADO! TROCANDO DE TURNO...")
	alterar_turno()
