extends Camera2D

@export var gerenciador: Node2D
@export var velocidade_suave: float = 5.0

# Alvo atual que a câmera deve seguir
var alvo_atual: Node2D = null

func _ready() -> void:
	# Centraliza inicialmente se já houver um alvo
	atualizar_alvo()

func _physics_process(delta: float) -> void:
	# 1. Verifica quem deve ser o alvo com base no turno
	atualizar_alvo()
	
	# 2. Desliza suavemente até a posição do jogador atual
	if alvo_atual and is_instance_valid(alvo_atual):
		global_position = global_position.lerp(alvo_atual.global_position, velocidade_suave * delta)

func atualizar_alvo() -> void:
	if gerenciador == null:
		return
		
	# Checa de quem é a vez (ou quem acabou de atirar)
	if gerenciador.estado_atual == gerenciador.estado_turno.jogador_1:
		alvo_atual = gerenciador.jogador_1_node
	elif gerenciador.estado_atual == gerenciador.estado_turno.jogador_2:
		alvo_atual = gerenciador.jogador_2_node
	elif gerenciador.estado_atual == gerenciador.estado_turno.processando_jogada:
		# Durante o voo/tiro, a câmera continua seguindo quem fez o disparo!
		alvo_atual = gerenciador.jogador_1_node if gerenciador.jogador_ativo_no_disparo == 1 else gerenciador.jogador_2_node
