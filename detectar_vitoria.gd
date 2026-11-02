extends Area2D

@export var tempo_espera_recomeco: float = 2.0

var jogo_finalizado: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if jogo_finalizado:
		return

	# Verifica se quem tocou é um jogador
	if body is RigidBody2D and body.has_method("e_minha_vez"):
		declarar_vitoria_e_recarregar(body)

func declarar_vitoria_e_recarregar(vencedor: RigidBody2D) -> void:
	jogo_finalizado = true
	
	# Salva a referência da árvore da cena antes do await
	var arvore = get_tree()
	if not arvore:
		return

	print("========================================")
	print(">>> PARABÉNS! JOGADOR ", vencedor.numero_jogador, " ENCOSTOU NO OBJETIVO E VENCEU! <<<")
	print("========================================")
	
	# Trava o movimento dos jogadores
	for jogador in arvore.get_nodes_in_group("Jogadores"):
		if jogador is RigidBody2D:
			jogador.linear_velocity = Vector2.ZERO
			jogador.angular_velocity = 0.0
			jogador.freeze = true

	# Espera o tempo configurado usando a árvore salva
	await arvore.create_timer(tempo_espera_recomeco).timeout

	# Recarrega a cena de forma segura e adiada
	if is_instance_valid(arvore):
		arvore.call_deferred("reload_current_scene")
