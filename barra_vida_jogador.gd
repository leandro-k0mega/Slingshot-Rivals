extends Node2D

@onready var hbox: HBoxContainer = $HBoxContainer

var coracoes: Array[TextureRect] = []

func _ready() -> void:
	coracoes.clear()
	if hbox:
		for child in hbox.get_children():
			if child is TextureRect:
				coracoes.append(child)
	print(">>> SUCESSO: Coracoes encontrados no HBoxContainer: ", coracoes.size())

func _process(_delta: float) -> void:
	global_rotation = 0.0

func atualizar_vida(vidas_restantes: int) -> void:
	var total_coracoes = coracoes.size()
	var coracoes_perdidos = total_coracoes - vidas_restantes
	
	print("--- ATUALIZANDO CORAÇÕES ---")
	print("Vidas restantes: ", vidas_restantes, " | Apagando os ", coracoes_perdidos, " primeiros da esquerda")
	
	for i in range(total_coracoes):
		if i < coracoes_perdidos:
			# Esconde tanto por visible quanto por transparência total
			coracoes[i].visible = false
			coracoes[i].modulate.a = 0.0
			print("Coração [", i, "] APAGADO!")
		else:
			coracoes[i].visible = true
			coracoes[i].modulate.a = 1.0
			print("Coração [", i, "] ATIVO!")
