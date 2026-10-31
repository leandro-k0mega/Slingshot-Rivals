extends Control

# Listas de corações expostas para arrastar no Inspetor
@export var coracoes_vermelho: Array[CanvasItem] = []
@export var coracoes_azul: Array[CanvasItem] = []

func _ready() -> void:
	# Garante que todos iniciem visíveis
	atualizar_exibicao(coracoes_vermelho, 3)
	atualizar_exibicao(coracoes_azul, 3)

# Atualiza a quantidade de corações visíveis do jogador
func atualizar_vidas(cor_jogador: String, vida_atual: int) -> void:
	if cor_jogador == "vermelho":
		atualizar_exibicao(coracoes_vermelho, vida_atual)
	elif cor_jogador == "azul":
		atualizar_exibicao(coracoes_azul, vida_atual)

func atualizar_exibicao(lista_coracoes: Array[CanvasItem], vidas: int) -> void:
	for i in range(lista_coracoes.size()):
		if lista_coracoes[i]:
			# Se o índice for menor que as vidas restantes, mantém visível
			lista_coracoes[i].visible = (i < vidas)
