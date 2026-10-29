extends Area2D

@onready var event_yoneticisi = get_node_or_null("EventYoneticisi")

var _giriliyor: bool = false

func _on_body_entered(body):
	if body.name != "Karakoncolos":
		return
	if _giriliyor:
		return
	_giriliyor = true

	Global.bildirim_gonder("Yer altina iniliyor...")

	if Global.envanter["mantar"] > 0:
		var mantar_basi_enerji = Global.yemek_enerji_getirisi + Global.mantar_enerji_bonus
		mantar_basi_enerji = max(mantar_basi_enerji, 1)
		var kazanilan_enerji = Global.envanter["mantar"] * mantar_basi_enerji
		Global.enerji += kazanilan_enerji
		Global.bildirim_gonder("Magaraya inildi! " + str(Global.envanter["mantar"]) + " mantar yendi.")
		Global.bildirim_gonder("Kazanilan Enerji: " + str(kazanilan_enerji) + " | Toplam Enerji: " + str(Global.enerji))
		Global.envanter["mantar"] = 0

	# DUZELTME: queue_free edilmis instance'lari onceden temizle
	Global.aktif_relicler = Global.aktif_relicler.filter(func(r): return is_instance_valid(r))
	Global.aktif_traitler = Global.aktif_traitler.filter(func(t): return is_instance_valid(t))

	for relic in Global.aktif_relicler:
		if relic.has_method("yuzey_donus_efekti"):
			relic.yuzey_donus_efekti()
	for t in Global.aktif_traitler:
		if t.has_method("yuzey_donus_efekti"):
			t.yuzey_donus_efekti()

	if event_yoneticisi:
		await event_yoneticisi.eventleri_tetikle(event_yoneticisi.Zaman.YER_ALTINA_INIS)

	if not is_inside_tree():
		return

	get_tree().call_deferred("change_scene_to_file", "res://Scene/yer_alti.tscn")
