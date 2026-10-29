extends Node

@export_group("Sahne")
@export var savas_sahnesi: PackedScene
@export var karakoncolos_sahnesi: PackedScene

@export_group("Esik 75 - İlk Dalga")
@export var esik_75_dusmanlari: Array[PackedScene] = []

@export_group("Esik 50 - İkinci Dalga")
@export var esik_50_dusmanlari: Array[PackedScene] = []

@export_group("Esik 25 - Son Dalga")
@export var esik_25_dusmanlari: Array[PackedScene] = []

func tetikle(esik: int) -> void:
	var liste: Array[PackedScene]
	var mesaj: String
	match esik:
		75:
			liste = esik_75_dusmanlari
			mesaj = "💢 Köylüler gürültüyü duydu! İlk dalga geliyor!"
		50:
			liste = esik_50_dusmanlari
			mesaj = "💢 Ağaç sarsıldı! Köylüler öfkeli!"
		25:
			liste = esik_25_dusmanlari
			mesaj = "💢 Son direnç! Köylüler çılgına döndü!"
		_:
			return

	if liste.is_empty():
		Global.bildirim_gonder("UYARI: Esik " + str(esik) + " icin dusman atanmamis!")
		return

	Global.bildirim_gonder(mesaj)

	# Tüm listedeki düşmanları instantiate et — hepsi aynı anda savaşır
	var dusmanlar: Array = []
	for sahne in liste:
		var d = sahne.instantiate()
		dusmanlar.append(d)
		Global.dusman_goruldu(d.dusman_isim)
		Global.dusman_can_kodeks[d.dusman_isim] = d.max_can
		Global.dusman_saldiri_kodeks[d.dusman_isim] = d.saldiri
		var aciklama = d.get("dusman_aciklama")
		if aciklama != null and aciklama != "":
			Global.dusman_aciklama_kodeks[d.dusman_isim] = aciklama

	var sonuc = _savasi_hesapla(dusmanlar)

	for d in dusmanlar:
		d.queue_free()

	# Görsel için ilk düşman sahnesini kullan
	var gorsel_sahne = liste[0] if not liste.is_empty() else null

	if not savas_sahnesi or not gorsel_sahne:
		_sonucu_uygula(sonuc)
		return

	var katman = CanvasLayer.new()
	katman.layer = 10
	get_tree().current_scene.add_child(katman)

	var savas = savas_sahnesi.instantiate()
	katman.add_child(savas)
	savas.position = Vector2.ZERO
	savas.baslat(sonuc, gorsel_sahne, karakoncolos_sahnesi)

	await katman.tree_exited

func _savasi_hesapla(dusmanlar: Array) -> Dictionary:
	var savas_log: Array = []
	var k_can: int = Global.enerji
	var k_saldiri: int = max(Global.balta_hasari, 1)
	var tur: int = 1
	var kazandi: bool = false

	# Her düşmanın canını ayrı tut
	var d_canlar: Array = []
	for d in dusmanlar:
		d_canlar.append(d.max_can)

	# Trait bonusları
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

	# Başlık
	var isimler = []
	for d in dusmanlar:
		isimler.append(d.dusman_isim)
	savas_log.append("⚔ KOK RAIDI — " + ", ".join(isimler))
	savas_log.append("Sen: " + str(k_can) + " enerji | " + str(k_saldiri + toplam_ekstra_hasar) + " saldiri")
	for i in range(dusmanlar.size()):
		savas_log.append(dusmanlar[i].dusman_isim + ": " + str(d_canlar[i]) + " can | " + str(dusmanlar[i].saldiri) + " saldiri")
	savas_log.append("─────────────")

	while k_can > 0:
		# Tur başı efektler
		for t in Global.aktif_traitler:
			if t.has_method("tur_basi_efekti_uygula"):
				t.tur_basi_efekti_uygula()
		for relic in Global.aktif_relicler:
			if relic.has_method("tur_basi_efekti_uygula"):
				relic.tur_basi_efekti_uygula()
		if Global.enerji > k_can:
			k_can = Global.enerji

		# --- OYUNCU SALDIRISI — tüm yaşayan düşmanlara aynı anda ---
		var hepsi_oldu = true
		if toplam_isabet_kaybi > 0.0 and randf() < toplam_isabet_kaybi:
			savas_log.append("Tur " + str(tur) + " → Iskaladin!")
			hepsi_oldu = false
		else:
			var verilen_hasar = k_saldiri + toplam_ekstra_hasar
			var log_parcalar = []
			for i in range(dusmanlar.size()):
				if d_canlar[i] > 0:
					d_canlar[i] -= verilen_hasar
					log_parcalar.append(dusmanlar[i].dusman_isim + " can: " + str(max(d_canlar[i], 0)))
					if d_canlar[i] > 0:
						hepsi_oldu = false
				# ölü düşman zaten hepsi_oldu'ya katkı yapmaz — üstteki if zaten geçer
			savas_log.append("Tur " + str(tur) + " → Sen -" + str(verilen_hasar) + " | " + ", ".join(log_parcalar))

		if hepsi_oldu:
			kazandi = true
			if kan_tadi_aktif and kan_tadi_enerji > 0:
				Global.enerji += kan_tadi_enerji
				k_can = Global.enerji
				savas_log.append("🩸 Kan tadi! +" + str(kan_tadi_enerji) + " enerji")
			break

		# --- DÜŞMAN SALDIRISI — tüm yaşayanlar aynı anda vurur ---
		var toplam_gelen: int = 0
		var saldiran_isimler = []
		for i in range(dusmanlar.size()):
			if d_canlar[i] > 0:
				saldiran_isimler.append(dusmanlar[i].dusman_isim)
				toplam_gelen += dusmanlar[i].saldiri

		if toplam_gelen > 0:
			if toplam_dodge > 0.0 and randf() < toplam_dodge:
				savas_log.append("Tur " + str(tur) + " → Kacindın! (" + ", ".join(saldiran_isimler) + ")")
			else:
				if toplam_hasar_degisim != 0.0:
					toplam_gelen = max(int(toplam_gelen * (1.0 - toplam_hasar_degisim)), 1)
				k_can -= toplam_gelen
				savas_log.append("Tur " + str(tur) + " → " + ", ".join(saldiran_isimler) + " toplam -" + str(toplam_gelen) + " | Senin enerji: " + str(max(k_can, 0)))

		tur += 1
		if tur > 50:
			savas_log.append("Savas cok uzadi — kactin!")
			break

	savas_log.append("─────────────")
	savas_log.append("KAZANDIN!" if kazandi else "KAYBETTIN!")

	# Tüm düşmanların ödüllerini birleştir
	var birlesik_odul: Array = []
	var birlesik_relic: Array = []
	var toplam_enerji_cezasi: int = 0
	for d in dusmanlar:
		var odul = d.get("odul_listesi")
		if odul != null:
			birlesik_odul.append_array(odul)
		var relic_s = d.get("odul_relic_sahneleri")
		if relic_s != null:
			birlesik_relic.append_array(relic_s)
		toplam_enerji_cezasi += d.enerji_cezasi

	return {
		"kazandi": kazandi,
		"savas_log": savas_log,
		"odul_listesi": birlesik_odul,
		"odul_relic_sahneleri": birlesik_relic,
		"enerji_cezasi": toplam_enerji_cezasi
	}

func _sonucu_uygula(sonuc: Dictionary):
	if sonuc["kazandi"]:
		for item in sonuc.get("odul_listesi", []):
			var kaynak = item.get("kaynak", "")
			var min_m = item.get("min", 0)
			var max_m = item.get("max", 0)
			if kaynak == "" or max_m == 0:
				continue
			var miktar = randi_range(min_m, max_m)
			if miktar <= 0:
				continue
			match kaynak:
				"odun":    Global.envanter["odun"] += miktar;   Global.bildirim_gonder("  + " + str(miktar) + " Odun")
				"tas":     Global.envanter["tas"] += miktar;    Global.bildirim_gonder("  + " + str(miktar) + " Tas")
				"mantar":  Global.envanter["mantar"] += miktar; Global.bildirim_gonder("  + " + str(miktar) + " Mantar")
				"yasam_ozu": Global.yasam_ozu += miktar;        Global.bildirim_gonder("  + " + str(miktar) + " Yasam Ozu")
				"enerji":  Global.enerji += miktar;             Global.bildirim_gonder("  + " + str(miktar) + " Enerji")
		var relic_sahneleri = sonuc.get("odul_relic_sahneleri", [])
		if not relic_sahneleri.is_empty():
			var secilen: PackedScene = relic_sahneleri[randi() % relic_sahneleri.size()]
			var yeni_relic = secilen.instantiate()
			get_tree().current_scene.add_child(yeni_relic)
			Global.aktif_relicler.append(yeni_relic)
			Global.bildirim_gonder("✦ [" + str(yeni_relic.get("relic_isim")) + "] dustu!")
	else:
		Global.enerji = max(Global.enerji - sonuc["enerji_cezasi"], 0)
		Global.bildirim_gonder("Enerji cezasi: -" + str(sonuc["enerji_cezasi"]))
