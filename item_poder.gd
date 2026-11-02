extends Area2D

enum TipoItem {
	INVERTER_CONTROLES = 1,
	PULO_EXTRA = 2,
	MID_AIR = 3,
	VER_TRAJETORIA = 4,
	TRANSFORMAR_CIRCULO = 5,
	FANTASMAGORIFICAR = 6
}

@export var tipo: TipoItem = TipoItem.FANTASMAGORIFICAR

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("coletar_habilidade"):
		return
	
	var coletou = body.coletar_habilidade(tipo)
	if coletou:
		print("Poder coletado pelo Jogador ", body.numero_jogador, "! Tipo: ", tipo)
		queue_free()
