extends Node

# ==========================================
# CAN KAYBI OLAYı (NEGATİF)
# Player çok zarar görür — kök az zarar görür.
# ==========================================

var event_isim: String = "can_kaybi"
var tetikleme_zamani: int = 0

@export_group("Karakoncolos Hasarı (Çok)")
@export var min_enerji_kaybi: int = 20
@export var max_enerji_kaybi: int = 45

@export_group("Kök Hasarı (Az)")
@export var min_kok_hasar: int = 3
@export var max_kok_hasar: int = 10

func calistir():
	var enerji_kaybi = randi_range(min_enerji_kaybi, max_enerji_kaybi)
	Global.enerji = max(Global.enerji - enerji_kaybi, 0)
	Global.bildirim_gonder("Kötü bir his... -" + str(enerji_kaybi) + " enerji!")

	var kok_hasar = randi_range(min_kok_hasar, max_kok_hasar)
	Global.kok_guncel_can = max(Global.kok_guncel_can - kok_hasar, 0)
	Global.bildirim_gonder("Kök hafifçe sarsıldı. -" + str(kok_hasar) + " can.")

	# Kök ölünce oyun biter — ama önce tree kontrolü
	if Global.kok_guncel_can <= 0:
		Global.bildirim_gonder("Kök yıkıldı!")
		if is_inside_tree():
			get_tree().call_deferred("change_scene_to_file", "res://Scene/kazandin_ekrani.tscn")
