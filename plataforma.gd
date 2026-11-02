extends StaticBody2D # ou AnimatableBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var turnos_restantes: int = 0
var e_fantasma: bool = false

func _ready() -> void:
	add_to_group("Plataformas")

func is_fantasma() -> bool:
	return e_fantasma

func tornar_fantasma(duracao_turnos: int = 2) -> void:
	e_fantasma = true
	turnos_restantes = duracao_turnos
	
	# Desativa a colisão fisicamente (o jogador em cima cai na hora!)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	# Efeito visual translúcido
	if sprite:
		sprite.modulate.a = 0.35
		
	print(">>> Plataforma ", name, " FANTASMAGORIFICADA por ", duracao_turnos, " turnos!")

func processar_passagem_turno() -> void:
	if not e_fantasma:
		return
		
	turnos_restantes -= 1
	if turnos_restantes <= 0:
		restaurar_plataforma()

func restaurar_plataforma() -> void:
	e_fantasma = false
	turnos_restantes = 0
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if sprite:
		sprite.modulate.a = 1.0
	print(">>> Plataforma ", name, " restaurou sua solidez!")
