extends Area2D

# 1 a 4 são poderes de inventário; 5 e 6 são armadilhas imediatas
enum TipoItem {
	INVERTER_CONTROLES = 1,
	PULO_EXTRA = 2,
	MID_AIR = 3,
	VER_TRAJETORIA = 4,
	ARMADILHA_FANTASMA = 5,
	ARMADILHA_BRUXA = 6
}

@export var tipo: TipoItem = TipoItem.PULO_EXTRA

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("coletar_habilidade"):
		return
	
	# CASO 1: Armadilhas (Aplicam na hora, não vão para o inventário)
	if tipo == TipoItem.ARMADILHA_BRUXA:
		body.controles_invertidos = true
		print("Bruxa atingiu o Jogador ", body.numero_jogador, "! Controles invertidos imediatamente.")
		queue_free()
		return
		
	elif tipo == TipoItem.ARMADILHA_FANTASMA:
		# Transforma a plataforma abaixo em fantasma
		var plataformas = get_tree().get_nodes_in_group("Plataformas")
		for plat in plataformas:
			if plat.global_position.distance_to(global_position) < 80.0:
				if plat.has_method("tornar_fantasma"):
					plat.tornar_fantasma()
		queue_free()
		return
	
	# CASO 2: Poderes de Inventário
	var coletou = body.coletar_habilidade(tipo)
	if coletou:
		queue_free()
