extends AnimatableBody2D

@export var velocidade: float = 70.0
@export var distancia_patrulha: float = 120.0

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_deteccao: Area2D = $AreaDeteccao

var ponto_inicial_x: float
var indo_para_direita: bool = true

func _ready() -> void:
	ponto_inicial_x = global_position.x
	if area_deteccao:
		area_deteccao.body_entered.connect(_on_area_body_entered)

func _physics_process(delta: float) -> void:
	var limite_dir = ponto_inicial_x + distancia_patrulha
	var limite_esq = ponto_inicial_x - distancia_patrulha
	
	# Movimentação e inversão de direção
	if indo_para_direita:
		global_position.x += velocidade * delta
		if global_position.x >= limite_dir:
			indo_para_direita = false
			atualizar_flip()
	else:
		global_position.x -= velocidade * delta
		if global_position.x <= limite_esq:
			indo_para_direita = true
			atualizar_flip()

func atualizar_flip() -> void:
	if sprite_2d:
		# Se a arte original da bruxa olha para a esquerda, inverta a condição:
		sprite_2d.flip_h = indo_para_direita

func _on_area_body_entered(body: Node2D) -> void:
	# Aplica a inversão de controle se colidir com o cubo do jogador
	if "controles_invertidos" in body:
		body.controles_invertidos = true
		print("Bruxa acertou o Jogador ", body.numero_jogador, "! Controles invertidos.")
