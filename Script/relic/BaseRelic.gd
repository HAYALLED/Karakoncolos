extends Node2D

# ==========================================
# BASE RELİC
# BaseDusman gibi C+D ile yeni relic yap.
# Her değer Inspector'dan ayarlanabilir.
# ==========================================

@export_group("Relic Kimliği")
@export var relic_isim: String = "Relic"
@export var relic_aciklama: String = "Açıklama buraya."

# ==========================================
# SCRAP SİSTEMİ
# ScrapItem sahnelerini buraya ekle.
# Örn: ScrapOdun.tscn, ScrapTas.tscn
# ==========================================
@export_group("Scrap - Reddedince Ne Çıkar")
@export var scrap_listesi: Array[Dictionary] = [
	{"kaynak": "odun", "min": 1, "max": 2}
]

# ==========================================
# SAVAŞ ETKİLERİ
# ==========================================
@export_group("Savaş - Tur Başına Enerji")
@export var tur_basi_enerji_aktif: bool = false
@export var tur_basi_enerji: int = 0

@export_group("Yüzey - Çıkış/Dönüş Enerjisi")
@export var yuzey_enerji_aktif: bool = false
@export var yuzey_cikista_enerji: int = 0
@export var yuzey_donuste_enerji: int = 0

@export_group("Kök - Vuruş Enerji Maliyeti")
@export var vurus_maliyet_aktif: bool = false
@export var vurus_maliyet_degisim: int = 0

@export_group("Saldırı Gücü")
@export var saldiri_aktif: bool = false
@export var saldiri_degisim: int = 0

@export_group("Artifact Effect (Manuel)")
@export var artifact_effect_aktif: bool = false

func _ready():
	_etkileri_uygula()

func _etkileri_uygula():
	if saldiri_aktif and saldiri_degisim != 0:
		Global.balta_hasari += saldiri_degisim
		print("Relic [" + relic_isim + "]: Saldırı " + str(saldiri_degisim))

	if vurus_maliyet_aktif and vurus_maliyet_degisim != 0:
		Global.vurus_enerji_bedeli = max(Global.vurus_enerji_bedeli + vurus_maliyet_degisim, 1)
		print("Relic [" + relic_isim + "]: Vuruş maliyeti " + str(vurus_maliyet_degisim))

func _etkileri_geri_al():
	if saldiri_aktif and saldiri_degisim != 0:
		Global.balta_hasari -= saldiri_degisim
	if vurus_maliyet_aktif and vurus_maliyet_degisim != 0:
		Global.vurus_enerji_bedeli = max(Global.vurus_enerji_bedeli - vurus_maliyet_degisim, 1)

# ==========================================
# SCRAP — her PackedScene'i instantiate edip
# kaynak_adi ve min/max değerlerini okur
# ==========================================
func scrap_et():
	Global.bildirim_gonder("[" + relic_isim + "] hurda edildi.")
	for item in scrap_listesi:
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

func tur_basi_efekti_uygula():
	if tur_basi_enerji_aktif and tur_basi_enerji != 0:
		Global.enerji += tur_basi_enerji
		var isaret = "+" if tur_basi_enerji > 0 else ""
		Global.bildirim_gonder("[" + relic_isim + "] " + isaret + str(tur_basi_enerji) + " enerji")

func yuzey_cikis_efekti():
	if yuzey_enerji_aktif and yuzey_cikista_enerji != 0:
		Global.enerji += yuzey_cikista_enerji
		var isaret = "+" if yuzey_cikista_enerji > 0 else ""
		Global.bildirim_gonder("[" + relic_isim + "] Çıkışta: " + isaret + str(yuzey_cikista_enerji) + " enerji")

func yuzey_donus_efekti():
	if yuzey_enerji_aktif and yuzey_donuste_enerji != 0:
		Global.enerji += yuzey_donuste_enerji
		var isaret = "+" if yuzey_donuste_enerji > 0 else ""
		Global.bildirim_gonder("[" + relic_isim + "] Dönüşte: " + isaret + str(yuzey_donuste_enerji) + " enerji")
