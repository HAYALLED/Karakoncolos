extends Node2D

@onready var baslik_yazisi = get_node_or_null("BaslikYazisi")
@onready var log_yazisi = get_node_or_null("LogYazisi")
@onready var dusman_container = get_node_or_null("DusmanContainer")
@onready var karakoncolos_container = get_node_or_null("KarakoncolosContainer")

@export var tur_suresi: float = 0.6
@export var saldiri_hizi: float = 0.15

var _sonuc: Dictionary = {}

func _ready():
	if log_yazisi: log_yazisi.text = ""
	if baslik_yazisi: baslik_yazisi.text = "⚔ SAVAŞ"

func baslat(sonuc: Dictionary, dusman_sahnesi: PackedScene, karakoncolos_sahnesi: PackedScene):
	_sonuc = sonuc

	await get_tree().process_frame

	if karakoncolos_container and karakoncolos_sahnesi:
		var k_gorsel = karakoncolos_sahnesi.instantiate()
		karakoncolos_container.add_child(k_gorsel)
		if k_gorsel is CharacterBody2D:
			k_gorsel.set_physics_process(false)
			k_gorsel.velocity = Vector2.ZERO
	else:
		print("UYARI: karakoncolos_sahnesi atanmamış")

	if dusman_container and dusman_sahnesi:
		var d_gorsel = dusman_sahnesi.instantiate()
		dusman_container.add_child(d_gorsel)

	_turlari_oynat()

func _turlari_oynat():
	for satir in _sonuc["savas_log"]:
		if log_yazisi:
			log_yazisi.text += satir + "\n"
		if "Sen: -" in satir:
			await _saldiri_animasyonu(karakoncolos_container, Vector2(80, 0))
		elif "Düşman: -" in satir:
			await _saldiri_animasyonu(dusman_container, Vector2(-80, 0))
		else:
			await get_tree().create_timer(tur_suresi * 0.5).timeout
	_sonucu_goster()

func _saldiri_animasyonu(hedef: Node, yon: Vector2) -> void:
	if not hedef:
		await get_tree().create_timer(tur_suresi).timeout
		return
	var baslangic = hedef.position
	var tween = create_tween()
	tween.tween_property(hedef, "position", baslangic + yon, saldiri_hizi)
	tween.tween_interval(0.05)
	tween.tween_property(hedef, "position", baslangic, saldiri_hizi)
	await tween.finished
	var kalan = tur_suresi - saldiri_hizi * 2
	if kalan > 0:
		await get_tree().create_timer(kalan).timeout

func _sonucu_goster():
	if baslik_yazisi:
		baslik_yazisi.text = "KAZANDIN!" if _sonuc["kazandi"] else "KAYBETTİN!"

	if _sonuc["kazandi"]:
		# ==========================================
		# KAYNAK ÖDÜLLERİ — odul_listesi formatı
		# ==========================================
		var liste = _sonuc.get("odul_listesi", [])
		for item in liste:
			var kaynak = item.get("kaynak", "")
			var min_m = item.get("min", 0)
			var max_m = item.get("max", 0)
			if kaynak == "" or max_m == 0:
				continue
			var miktar = randi_range(min_m, max_m)
			if miktar <= 0:
				continue
			match kaynak:
				"odun":
					Global.envanter["odun"] += miktar
					Global.bildirim_gonder("  + " + str(miktar) + " Odun")
				"tas":
					Global.envanter["tas"] += miktar
					Global.bildirim_gonder("  + " + str(miktar) + " Taş")
				"mantar":
					Global.envanter["mantar"] += miktar
					Global.bildirim_gonder("  + " + str(miktar) + " Mantar")
				"yasam_ozu":
					Global.yasam_ozu += miktar
					Global.bildirim_gonder("  + " + str(miktar) + " Yaşam Özü")
				"enerji":
					Global.enerji += miktar
					Global.bildirim_gonder("  + " + str(miktar) + " Enerji")

		# ==========================================
		# RELİC DROP
		# ==========================================
		var relic_sahneleri = _sonuc.get("odul_relic_sahneleri", [])
		if not relic_sahneleri.is_empty():
			var secilen: PackedScene = relic_sahneleri[randi() % relic_sahneleri.size()]
			var yeni_relic = secilen.instantiate()
			get_tree().current_scene.add_child(yeni_relic)
			Global.aktif_relicler.append(yeni_relic)
			var isim = yeni_relic.get("relic_isim") if yeni_relic.get("relic_isim") else "Relic"
			Global.bildirim_gonder("✦ [" + isim + "] düştü!")
	else:
		Global.enerji = max(Global.enerji - _sonuc["enerji_cezasi"], 0)
		Global.bildirim_gonder("Enerji cezası: -" + str(_sonuc["enerji_cezasi"]))

	await get_tree().create_timer(2.5).timeout
	get_parent().queue_free()
