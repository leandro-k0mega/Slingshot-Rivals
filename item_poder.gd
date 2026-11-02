extends Area2D

# 1 a 4 são os poderes que podem ser guardados no inventário
enum TipoItem {
	INVERTER_CONTROLES = 1,
	PULO_EXTRA = 2,
	MID_AIR = 3,
	VER_TRAJETORIA = 4
}

# Permite escolher qual poder este coletável representa direto no Inspetor
@export var tipo: TipoItem = TipoItem.PULO_EXTRA

func _ready() -> void:
	# Conecta o sinal nativo de colisão da Area2D
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verifica se o nó que colidiu possui o método de inventário do jogador
	if not body.has_method("coletar_habilidade"):
		return
	
	# Tenta coletar: retorna true apenas se o inventário do cubo estava vazio
	var coletou = body.coletar_habilidade(tipo)
	if coletou:
		print("Poder coletado pelo Jogador ", body.numero_jogador, "! Tipo: ", tipo)
		queue_free()
