extends Node

var event_isim: String = "can_verme"
var tetikleme_zamani: int = 0

@export_group("Karakoncolos İyileşme (Az)")
@export var min_enerji: int = 5
@export var max_enerji: int = 15

@export_group("Kök İyileşme (Çok)")
@export var kok_iyilesme_aktif: bool = true
@export var min_kok_can: int = 20
@export var max_kok_can: int = 50

func calistir():
	var enerji_kazanim = randi_range(min_enerji, max_enerji)
	# Mevcut enerjinin üstüne ekle — max_enerji ile kesme
	Global.enerji += enerji_kazanim
	Global.bildirim_gonder("Neşeli bir his! +" + str(enerji_kazanim) + " enerji.")

	if kok_iyilesme_aktif:
		var kok_kazanim = randi_range(min_kok_can, max_kok_can)
		Global.kok_guncel_can = min(Global.kok_guncel_can + kok_kazanim, Global.kok_baslangic_cani)
		Global.bildirim_gonder("Kök güçlendi! +" + str(kok_kazanim) + " can.")
