extends Node

var event_isim: String = "dusman"
var tetikleme_zamani: int = 0

@export_group("Sahne")
@export var savas_sahnesi: PackedScene
@export var karakoncolos_sahnesi: PackedScene
@export var dusman_sahneleri: Array[PackedScene]

@export_group("Düşman Sayısı")
@export var max_dusman: int = 1

func calistir():
	if dusman_sahneleri.is_empty():
		Global.bildirim_gonder("HATA: Düşman sahnesi atanmamış!")
		return

	var secilen_sahne = dusman_sahneleri[randi() % dusman_sahneleri.size()]
	var dusman_temp = secilen_sahne.instantiate()
	Global.bildirim_gonder("Yolda bir " + dusman_temp.dusman_isim + " belirdi!")
	Global.dusman_goruldu(dusman_temp.dusman_isim)
	Global.dusman_can_kodeks[dusman_temp.dusman_isim] = dusman_temp.max_can
	Global.dusman_saldiri_kodeks[dusman_temp.dusman_isim] = dusman_temp.saldiri
	var aciklama = dusman_temp.get("dusman_aciklama")
	if aciklama != null and aciklama != "":
		Global.dusman_aciklama_kodeks[dusman_temp.dusman_isim] = aciklama
	var sonuc = _savasi_hesapla(dusman_temp)
	dusman_temp.queue_free()

	if not savas_sahnesi:
		_sonucu_uygula(sonuc)
		return

	var katman = CanvasLayer.new()
	katman.layer = 10
	get_tree().current_scene.add_child(katman)

	var savas = savas_sahnesi.instantiate()
	katman.add_child(savas)
	savas.position = Vector2.ZERO
	savas.baslat(sonuc, secilen_sahne, karakoncolos_sahnesi)

	await katman.tree_exited

func _savasi_hesapla(dusman: Node) -> Dictionary:
	var savas_log: Array = []
	var k_can: int = Global.enerji
	var k_saldiri: int = max(Global.balta_hasari, 1)
	var d_can: int = dusman.max_can
	var tur: int = 1
	var kazandi: bool = false

	# ==========================================
	# AKTİF TRAİTLERDEN SAVAŞ BONUSLARINI TOPLA
	# ==========================================
	var toplam_ekstra_hasar: int = 0
	var toplam_hasar_degisim: float = 0.0
	var toplam_dodge: float = 0.0
	var toplam_isabet_kaybi: float = 0.0
	var kan_tadi_aktif: bool = false
	var kan_tadi_enerji: int = 0

	for t in Global.aktif_traitler:
		var ekstra = t.get("savas_ekstra_hasar")
		if ekstra != null and ekstra != 0:
			toplam_ekstra_hasar += ekstra
		var hasar_deg = t.get("hasar_degisim_yuzde")
		if hasar_deg != null and hasar_deg != 0.0:
			toplam_hasar_degisim += hasar_deg
		var dodge = t.get("dodge_sansi")
		if dodge != null and dodge > 0.0:
			toplam_dodge += dodge
		var isabet = t.get("isabet_kaybi_sansi")
		if isabet != null and isabet > 0.0:
			toplam_isabet_kaybi += isabet
		if t.get("kan_tadi_aktif") == true:
			kan_tadi_aktif = true
			var kt_enerji = t.get("kan_tadi_enerji")
			if kt_enerji != null:
				kan_tadi_enerji += kt_enerji

	toplam_dodge = clamp(toplam_dodge, 0.0, 0.75)
	toplam_isabet_kaybi = clamp(toplam_isabet_kaybi, 0.0, 0.75)

	# ==========================================
	# SAVAŞ LOGU BAŞLIĞI
	# ==========================================
	savas_log.append("⚔ " + dusman.dusman_isim)
	savas_log.append("Sen: " + str(k_can) + " enerji | " + str(k_saldiri + toplam_ekstra_hasar) + " saldırı")
	savas_log.append("Düşman: " + str(d_can) + " can | " + str(dusman.saldiri) + " saldırı")
	if toplam_dodge > 0.0:
		savas_log.append("Dodge şansı: %" + str(int(toplam_dodge * 100)))
	if toplam_hasar_degisim > 0.0:
		savas_log.append("Hasar emilimi: %" + str(int(toplam_hasar_degisim * 100)))
	elif toplam_hasar_degisim < 0.0:
		savas_log.append("Hasar açığı: %" + str(int(-toplam_hasar_degisim * 100)))
	savas_log.append("─────────────")

	# ==========================================
	# SAVAŞ DÖNGÜSÜ
	# ==========================================
	while k_can > 0 and d_can > 0:
		for t in Global.aktif_traitler:
			if t.has_method("tur_basi_efekti_uygula"):
				t.tur_basi_efekti_uygula()
		for relic in Global.aktif_relicler:
			if relic.has_method("tur_basi_efekti_uygula"):
				relic.tur_basi_efekti_uygula()
		if Global.enerji > k_can:
			k_can = Global.enerji

		# --- KARAKONCOLOS SALDIRISI ---
		if toplam_isabet_kaybi > 0.0 and randf() < toplam_isabet_kaybi:
			savas_log.append("Tur " + str(tur) + " → Iskaladin! | Düşman can: " + str(max(d_can, 0)))
		else:
			var verilen_hasar = k_saldiri + toplam_ekstra_hasar
			d_can -= verilen_hasar
			savas_log.append("Tur " + str(tur) + " → Sen: -" + str(verilen_hasar) + " | Düşman can: " + str(max(d_can, 0)))
			if d_can <= 0:
				kazandi = true
				if kan_tadi_aktif and kan_tadi_enerji > 0:
					Global.enerji += kan_tadi_enerji
					k_can = Global.enerji
					savas_log.append("🩸 Kan tadı! +" + str(kan_tadi_enerji) + " enerji")
				break

		# --- DÜŞMAN SALDIRISI ---
		if toplam_dodge > 0.0 and randf() < toplam_dodge:
			savas_log.append("Tur " + str(tur) + " → Kaçındın! | Senin enerji: " + str(max(k_can, 0)))
		else:
			var gelen_hasar = dusman.saldiri
			if toplam_hasar_degisim != 0.0:
				gelen_hasar = max(int(gelen_hasar * (1.0 - toplam_hasar_degisim)), 1)
			k_can -= gelen_hasar
			savas_log.append("Tur " + str(tur) + " → Düşman: -" + str(gelen_hasar) + " | Senin enerji: " + str(max(k_can, 0)))

		tur += 1
		if tur > 50:
			savas_log.append("Savaş çok uzadı — kaçtın!")
			break

	savas_log.append("─────────────")
	savas_log.append("KAZANDIN!" if kazandi else "KAYBETTİN!")

	# odul_listesi ve relic sahneleri sonuca paktle
	var odul_listesi = dusman.get("odul_listesi")
	var relic_sahneleri = dusman.get("odul_relic_sahneleri")

	return {
		"kazandi": kazandi,
		"savas_log": savas_log,
		"odul_listesi": odul_listesi if odul_listesi != null else [],
		"odul_relic_sahneleri": relic_sahneleri if relic_sahneleri != null else [],
		"enerji_cezasi": dusman.enerji_cezasi
	}

func _sonucu_uygula(sonuc: Dictionary):
	if sonuc["kazandi"]:
		# ==========================================
		# KAYNAK ÖDÜLLERİ — scrap_listesi mantığıyla
		# ==========================================
		var liste = sonuc.get("odul_listesi", [])
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

		# ==========================================
		# RELİC DROP — liste doluysa rastgele biri seç
		# ==========================================
		var relic_sahneleri = sonuc.get("odul_relic_sahneleri", [])
		if not relic_sahneleri.is_empty():
			var secilen: PackedScene = relic_sahneleri[randi() % relic_sahneleri.size()]
			var yeni_relic = secilen.instantiate()
			get_tree().current_scene.add_child(yeni_relic)
			Global.aktif_relicler.append(yeni_relic)
			var isim = yeni_relic.get("relic_isim") if yeni_relic.get("relic_isim") else "Relic"
			Global.bildirim_gonder("✦ [" + isim + "] düştü!")
	else:
		Global.enerji = max(Global.enerji - sonuc["enerji_cezasi"], 0)
		Global.bildirim_gonder("Enerji cezası: -" + str(sonuc["enerji_cezasi"]))
