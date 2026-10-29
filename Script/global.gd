extends Node

# ==========================================
# EKRAN BİLDİRİM SİSTEMİ
# ==========================================
var debug_yazisi: Label
var mesajlar: Array = []

func _ready():
	var katman = CanvasLayer.new()
	katman.layer = 100
	add_child(katman)
	debug_yazisi = Label.new()
	katman.add_child(debug_yazisi)
	var ekran_boyutu = get_viewport().get_visible_rect().size
	debug_yazisi.position = Vector2(20, ekran_boyutu.y - 160)
	debug_yazisi.add_theme_color_override("font_color", Color(1, 1, 1))
	debug_yazisi.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	debug_yazisi.add_theme_constant_override("outline_size", 4)
	debug_yazisi.add_theme_font_size_override("font_size", 16)

func bildirim_gonder(metin: String):
	print(metin)
	mesajlar.append(metin)
	if mesajlar.size() > 6:
		mesajlar.pop_front()
	var ekran_metni = ""
	for m in mesajlar:
		ekran_metni += m + "\n"
	if debug_yazisi:
		debug_yazisi.text = ekran_metni

# ==========================================
# ENVANTER VE TARİFLER
# ==========================================
var envanter = { "mantar": 0, "tas": 0, "odun": 0 }
var esya_ikonlari = { "mantar": "res://ikonlar/mantar.png", "tas": "res://ikonlar/tas.png" }
var tarifler = [
	{ "isim": "Keskin Balta (+5 Hasar)", "tas_bedeli": 5, "odun_bedeli": 0, "tip": "hasar", "deger": 5, "uretildi": false },
	{ "isim": "Saglam Sap (-2 Enerji Tuketimi)", "tas_bedeli": 2, "odun_bedeli": 3, "tip": "enerji_tasarrufu", "deger": 2, "uretildi": false },
	{ "isim": "Usta Isi Balta (+10 Hasar)", "tas_bedeli": 10, "odun_bedeli": 5, "tip": "hasar", "deger": 10, "uretildi": false }
]

@export_category("Karakter Degerleri")
@export var enerji: int = 100
@export var max_enerji: int = 100

@export_category("Balta ve Efor Degerleri")
@export var baslangic_balta_hasari: int = 1
@export var balta_hasari: int = 1
@export var vurus_enerji_bedeli: int = 10
@export var yemek_enerji_getirisi: int = 20

@export_category("Oyun Dunyasi")
@export var kok_baslangic_cani: int = 100
@export var kok_guncel_can: int = 100
@export var gece_suresi: int = 100

@export_category("Gelistirme ve Esyalar")
@export var balta_seviyesi: int = 1
@export var gelistirme_bedeli: int = 5

@export_category("Zaman ve Bahar")
@export var gun_sayisi: int = 1
@export var bahar_dongusu: int = 3
@export var iyilesme_miktari: int = 50

# Trait / hareket / mantar bonusları
var hareket_hizi_bonus: float = 0.0
var mantar_enerji_bonus: int = 0

# Durum
var uretim_acik: bool = false
var aktif_relicler: Array = []
var aktif_traitler: Array = []
var kozmetikler: Dictionary = { "sapka": null, "govde": null, "pantalon": null, "ayakkabi": null }
var yasam_ozu: int = 0
var event_aktif: bool = false
var ilk_cikis: bool = true
var bebek_sayisi: int = 0

# ==========================================
# KODEKSler
# ==========================================

# Düşman kodeksi: { "DusmanIsmi": karsılasma_sayisi }
# Her karşılaşmada CombatEvent artırır.
var dusman_kodeks: Dictionary = {}

# Eşya kodeksi: { "RelicIsmi": { "sahip": bool, "aciklama": str } }
# Relic görüldüğünde kok.gd kaydeder.
var esya_kodeks: Dictionary = {}

func dusman_goruldu(isim: String):
	dusman_kodeks[isim] = dusman_kodeks.get(isim, 0) + 1

func esya_goruldu(isim: String, aciklama: String, sahip: bool):
	# Sahiplik false iken true'ya geçebilir, ama true -> false olmaz
	if esya_kodeks.has(isim):
		if sahip:
			esya_kodeks[isim]["sahip"] = true
	else:
		esya_kodeks[isim] = { "sahip": sahip, "aciklama": aciklama }

func oyunu_sifirla():
	envanter["mantar"] = 0
	envanter["tas"] = 0
	envanter["odun"] = 0
	enerji = max_enerji
	balta_hasari = baslangic_balta_hasari
	balta_seviyesi = 1
	gelistirme_bedeli = 5
	gun_sayisi = 1
	ilk_cikis = true
	kok_guncel_can = kok_baslangic_cani
	bebek_sayisi = 0
	event_aktif = false
	yasam_ozu = 0
	hareket_hizi_bonus = 0.0
	mantar_enerji_bonus = 0
	# DUZELTME: trait node'lari artik Global'in cocugu — queue_free et
	for t in aktif_traitler:
		if is_instance_valid(t):
			t.queue_free()
	# DUZELTME: relic node'lari da Global'in cocugu
	for r in aktif_relicler:
		if is_instance_valid(r):
			r.queue_free()
	aktif_relicler.clear()
	aktif_traitler.clear()
	# DUZELTME: kozmetik node'lari da Global'in cocugu
	for slot in kozmetikler:
		var koz = kozmetikler[slot]
		if koz and is_instance_valid(koz):
			koz.queue_free()
	kozmetikler = { "sapka": null, "govde": null, "pantalon": null, "ayakkabi": null }
	for tarif in tarifler:
		tarif["uretildi"] = false
	# Kodeks run'lar arasında sıfırlanmaz (kalıcı bilgi)
	mesajlar.clear()
	if debug_yazisi: debug_yazisi.text = ""

# Düşman istatistik kodeksi (CombatEvent karşılaşmada doldurur)
# 3. karşılaşmada can, 5. saldırı, 7. açıklama görünür
var dusman_can_kodeks: Dictionary = {}       # { isim: max_can }
var dusman_saldiri_kodeks: Dictionary = {}   # { isim: saldiri }
var dusman_aciklama_kodeks: Dictionary = {}  # { isim: aciklama } (BaseDusman'da varsa)
