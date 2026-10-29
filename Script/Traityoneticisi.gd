extends Node
# ==========================================
# TRAİT YÖNETİCİSİ
# player.tscn'e child olarak eklenir.
# Her 3 günde bir 2 trait teklifi gelir.
# ==========================================

@export_group("Pozitif Slot Bedelleri")
@export var slot1_bedel: int = 5
@export var slot2_bedel: int = 10
@export var slot3_bedel: int = 20

@export_group("Negatif Trait")
@export var normal_cikarma_bedeli: int = 15
@export var yapisik_cikarma_bedeli: int = 30
@export var yapis_gun_esigi: int = 3

@export_group("Trait Teklif Sistemi")
@export var teklif_gun_araligi: int = 3          # Her kaç günde bir teklif gelir
@export var teklif_basi_adet: int = 2            # Her teklifte kaç trait çıkar
@export var trait_havuzu: Array[PackedScene] = [] # Inspector'dan doldur

const MAX_POZITIF = 3
const MAX_NEGATIF = 3

# ==========================================
# GÜN BAZLI KONTROL
# yeryuzune_cikis.gd -> mekana_git() her gün bunu çağırır.
# ==========================================
func gun_basi_kontrol():
	# Yapışma kontrolü
	for t in Global.aktif_traitler:
		t.yapis_kontrol_et()

	# Trait teklifi — her teklif_gun_araligi günde bir
	if Global.gun_sayisi % teklif_gun_araligi == 0:
		_trait_tekliflerini_sun()

func _trait_tekliflerini_sun():
	if trait_havuzu.is_empty():
		Global.bildirim_gonder("Trait havuzu bos! Inspector'dan ekle.")
		return

	Global.bildirim_gonder("=== TRAIT TEKLİFİ ===")

	for _i in range(teklif_basi_adet):
		# Rastgele bir trait sahnesini seç
		var sahne = trait_havuzu[randi() % trait_havuzu.size()]
		var yeni = sahne.instantiate()
		_teklifi_isle(yeni, sahne)

func _teklifi_isle(yeni: Node, sahne: PackedScene):
	if yeni.pozitif_mi:
		_pozitif_teklifi_isle(yeni, sahne)
	else:
		_negatif_teklifi_isle(yeni, sahne)

# ==========================================
# POZİTİF TRAİT KURALLARI
# - Boş slot varsa: direkt ekle (kilitli)
# - Slotlar doluysa: kilitsiz birine overwrite et
# - Hepsi kilitliyse: hiçbir şey olmaz
# ==========================================
func _pozitif_teklifi_isle(yeni: Node, _sahne: PackedScene):
	var pozitifler = _pozitif_traitler()

	if pozitifler.size() < MAX_POZITIF:
		# Boş slot var — direkt ekle
		_ekle(yeni)
		Global.bildirim_gonder("+ Yeni pozitif trait: " + yeni.trait_isim + " [Aktif, korumasiz]")
	else:
		# kilitli_mi=false = korumasiz (overwrite olabilir)
		# kilitli_mi=true  = kilitli, korumalı (overwrite olmaz)
		var acik_olanlar = pozitifler.filter(func(t): return not t.kilitli_mi)
		if acik_olanlar.is_empty():
			# Hepsi kilitli (açılmış ve aktif) — hiçbir şey olmaz
			Global.bildirim_gonder("Tum pozitif slotlar aktif — " + yeni.trait_isim + " reddedildi.")
			yeni.queue_free()
		else:
			# Korumasiz (kilitli_mi=false) birine overwrite
			var hedef = acik_olanlar[randi() % acik_olanlar.size()]
			Global.bildirim_gonder("Overwrite: " + hedef.trait_isim + " -> " + yeni.trait_isim)
			_cikar_ve_sil(hedef)
			_ekle(yeni)

# ==========================================
# NEGATİF TRAİT KURALLARI
# - Boş slot varsa: direkt ekle
# - Slot doluysa: mevcut negatifi overwrite et
# ==========================================
func _negatif_teklifi_isle(yeni: Node, _sahne: PackedScene):
	var negatifler = _negatif_traitler()

	if negatifler.size() < MAX_NEGATIF:
		_ekle(yeni)
		Global.bildirim_gonder("- Yeni negatif trait: " + yeni.trait_isim)
	else:
		# 3 slot dolu — yapışık olmayanı overwrite et (yapışık = korumalı)
		var yapisik_olmayanlar = negatifler.filter(func(t): return not t.yapisik_mi)
		var hedef: Node
		if not yapisik_olmayanlar.is_empty():
			hedef = yapisik_olmayanlar[randi() % yapisik_olmayanlar.size()]
		else:
			# Hepsi yapışık — rastgele birini overwrite et
			hedef = negatifler[randi() % negatifler.size()]
		Global.bildirim_gonder("Overwrite: " + hedef.trait_isim + " -> " + yeni.trait_isim)
		_cikar_ve_sil(hedef)
		_ekle(yeni)

# ==========================================
# YARDIMCI FONKSİYONLAR
# ==========================================
func _ekle(yeni: Node):
	yeni.kilit_bedeli = _slot_bedeli(_pozitif_sayisi()) if yeni.pozitif_mi else 0
	yeni.normal_cikarma_bedeli = normal_cikarma_bedeli
	yeni.yapisik_cikarma_bedeli = yapisik_cikarma_bedeli
	yeni.yapis_gun_esigi = yapis_gun_esigi
	# DUZELTME: Global'e ekle — sahne degisince olmesin
	Global.add_child(yeni)
	Global.aktif_traitler.append(yeni)

func _cikar_ve_sil(t: Node):
	# Efektleri geri al (eğer aktifse)
	if t.has_method("_etkileri_geri_al"):
		t._etkileri_geri_al()  # Trait baslangicta hemen aktifti — her zaman geri al
	Global.aktif_traitler.erase(t)
	t.queue_free()

# ==========================================
# MEVCUT EL İLE MANUEL EKLEME (eski sistem)
# ==========================================
func trait_ekle(trait_sahnesi: PackedScene) -> bool:
	var yeni_trait = trait_sahnesi.instantiate()
	if yeni_trait.pozitif_mi:
		if _pozitif_sayisi() >= MAX_POZITIF:
			Global.bildirim_gonder("Pozitif trait slotu dolu!")
			yeni_trait.queue_free()
			return false
		yeni_trait.kilit_bedeli = _slot_bedeli(_pozitif_sayisi())
		yeni_trait.yapis_gun_esigi = yapis_gun_esigi
	else:
		if _negatif_sayisi() >= MAX_NEGATIF:
			Global.bildirim_gonder("Negatif trait slotu dolu!")
			yeni_trait.queue_free()
			return false
		yeni_trait.normal_cikarma_bedeli = normal_cikarma_bedeli
		yeni_trait.yapisik_cikarma_bedeli = yapisik_cikarma_bedeli
		yeni_trait.yapis_gun_esigi = yapis_gun_esigi
	# DUZELTME: Global'e ekle — sahne degisince olmesin
	Global.add_child(yeni_trait)
	Global.aktif_traitler.append(yeni_trait)
	Global.bildirim_gonder("Yeni trait: " + yeni_trait.trait_isim)
	return true

func pozitif_kilidi_ac(indeks: int) -> bool:
	var p = _pozitif_traitler()
	if indeks >= p.size(): return false
	return p[indeks].kilidi_ac()

func negatif_cikar(indeks: int) -> bool:
	var n = _negatif_traitler()
	if indeks >= n.size(): return false
	var yeni_trait = n[indeks]
	if yeni_trait.cikar():
		Global.aktif_traitler.erase(yeni_trait)
		yeni_trait.queue_free()
		return true
	return false

func _pozitif_traitler() -> Array:
	return Global.aktif_traitler.filter(func(t): return t.pozitif_mi)

func _negatif_traitler() -> Array:
	return Global.aktif_traitler.filter(func(t): return not t.pozitif_mi)

func _pozitif_sayisi() -> int:
	return _pozitif_traitler().size()

func _negatif_sayisi() -> int:
	return _negatif_traitler().size()

func _slot_bedeli(i: int) -> int:
	match i:
		0: return slot1_bedel
		1: return slot2_bedel
		_: return slot3_bedel
