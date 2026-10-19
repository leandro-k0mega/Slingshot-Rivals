extends Area2D

func _ready() -> void:
	# Conecta o sinal nativo de colisão da Area2D
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verifica se quem encostou tem a função de transformação (ou seja, é o jogador)
	if body.has_method("transformar_em_triangulo"):
		body.transformar_em_triangulo() # Manda o jogador se transformar
		queue_free()                  # Destrói o cubo coletável com segurança
