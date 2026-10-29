extends Node

var event_isim: String = "koy_baskini"
var tetikleme_zamani: int = 0

@export_group("Item Çalma")
@export var demir_balta_sansi: float = 0.40
@export var demir_balta_bonus: int = 8
@export var odun_sansi: float = 0.50
@export var min_odun: int = 3
@export var max_odun: int = 8
@export var tas_sansi: float = 0.40
@export var min_tas: int = 2
@export var max_tas: int = 6

@export_group("Bebek Çalma (Çok Düşük)")
@export var bebek_sansi: float = 0.03
@export var max_bebek: int = 10  # Global limit

func calistir():
	Global.bildirim_gonder("Köye baskın! Karakoncolos karanlıkta süzülüyor...")

	var bir_sey_calindi = false

	if randf() <= demir_balta_sansi:
		Global.balta_hasari += demir_balta_bonus
		Global.bildirim_gonder("Demir balta çalındı! +" + str(demir_balta_bonus) + " hasar.")
		bir_sey_calindi = true

	if randf() <= odun_sansi:
		var miktar = randi_range(min_odun, max_odun)
		Global.envanter["odun"] += miktar
		Global.bildirim_gonder("Odun çalındı! +" + str(miktar) + " Odun.")
		bir_sey_calindi = true

	if randf() <= tas_sansi:
		var miktar = randi_range(min_tas, max_tas)
		Global.envanter["tas"] += miktar
		Global.bildirim_gonder("Taş çalındı! +" + str(miktar) + " Taş.")
		bir_sey_calindi = true

	# Bebek çalma — limit kontrolü
	if randf() <= bebek_sansi:
		if Global.bebek_sayisi < max_bebek:
			Global.bebek_sayisi += 1
			Global.bildirim_gonder("Bir bebek çaldın! Kolonide: " + str(Global.bebek_sayisi) + " bebek.")
			bir_sey_calindi = true
		else:
			Global.bildirim_gonder("Koloni dolu! Daha fazla bebek sığmıyor.")

	if not bir_sey_calindi:
		Global.bildirim_gonder("Köyde kimse yoktu. Eli boş döndün.")
