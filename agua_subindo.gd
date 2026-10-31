extends Area2D

@export var pixels_por_rodada: float = 40.0
@export var duracao_subida: float = 1.0
@export var gerenciador: Node2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func subir_agua() -> void:
	var nova_posicao_y = position.y - pixels_por_rodada
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", nova_posicao_y, duracao_subida)
	print(">>> A água subiu! Novo nível Y: ", nova_posicao_y)

func _on_body_entered(body: Node2D) -> void:
	# Verifica se é um dos cubos dos jogadores
	if "numero_jogador" in body:
		print("Jogador ", body.numero_jogador, " tocou na água!")
		if gerenciador and gerenciador.has_method("remover_vida"):
			# Passa o número e a coordenada global de onde ele caiu
			gerenciador.remover_vida(body.numero_jogador, body.global_position)
