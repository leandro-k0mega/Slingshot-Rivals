extends Area2D

# Força fixa alta para garantir um arremesso forte
@export var forca_lancamento: float = 850.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and "numero_jogador" in body:
		# 1. Zera completamente a velocidade linear e angular acumulada
		PhysicsServer2D.body_set_state(body.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
		PhysicsServer2D.body_set_state(body.get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
		body.linear_velocity = Vector2.ZERO
		body.angular_velocity = 0.0

		# 2. Sorteia 45° para cima e direita OU 45° para cima e esquerda
		# (No 2D do Godot, Y negativo é para cima!)
		var vai_para_direita: bool = randf() < 0.5
		var direcao: Vector2
		
		if vai_para_direita:
			# Vetor (1, -1) normalizado = 45 graus para cima e direita
			direcao = Vector2(1.0, -1.0).normalized()
		else:
			# Vetor (-1, -1) normalizado = 45 graus para cima e esquerda
			direcao = Vector2(-1.0, -1.0).normalized()

		# 3. Aplica o impulso imediato no cubo
		var impulso = direcao * forca_lancamento
		body.apply_central_impulse(impulso)

		print("Fantasma arremessou Jogador ", body.numero_jogador, " a 45 graus para ", ("DIREITA" if vai_para_direita else "ESQUERDA"), " com forca: ", forca_lancamento)

		# Destroi o fantasma após a ativação
		queue_free()
