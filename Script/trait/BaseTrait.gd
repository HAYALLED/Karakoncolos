extends Node

# ==========================================
# BASE TRAİT — C+D ile yeni trait yap
# Tüm hook'lar burada — sahne dosyasında
# Inspector'dan değerleri ayarla.
# ==========================================

@export_group("Kimlik")
@export var trait_isim: String = "Trait"
@export var trait_aciklama: String = "Açıklama."
@export var pozitif_mi: bool = true

@export_group("Pozitif - Kilit Bedeli")
@export var kilit_bedeli: int = 5

@export_group("Negatif - Çıkarma")
@export var normal_cikarma_bedeli: int = 15
@export var yapisik_cikarma_bedeli: int = 30
@export var yapis_gun_esigi: int = 3

# ==========================================
# SAVAŞ ETKİLERİ
# ==========================================

@export_group("Savaş - Tur Başına Enerji")
@export var tur_basi_enerji_aktif: bool = false
@export var tur_basi_enerji: int = 0
# Pozitif değer = enerji kazan, negatif = kaybet (EnerjiSizintisi)

@export_group("Savaş - Saldırı Gücü (Kalıcı)")
@export var saldiri_aktif: bool = false
@export var saldiri_degisim: int = 0
# Kalıcı Global.balta_hasari değişimi. KeskinSaldiri=+5, DonukSaldiri=-3

@export_group("Savaş - Ekstra Hasar (Sadece Savaşta)")
@export var savas_ekstra_hasar: int = 0
# Savaş hesabında k_saldiri'ye eklenir — kalıcı değil. KanOfkesi=+5, Korkak=-3

@export_group("Savaş - Gelen Hasar Değişimi")
@export var hasar_degisim_yuzde: float = 0.0
# +0.25 = %25 daha az hasar alırsın (CelikDeri)
# -0.25 = %25 daha fazla hasar alırsın (CamKemik)
# CombatEvent bu değeri okur, Global'e yazmaz

@export_group("Savaş - Dodge (Kaçınma Şansı)")
@export var dodge_sansi: float = 0.0
# 0.20 = %20 kaçınma şansı. CombatEvent okur. DodgeSanatcisi=0.20

@export_group("Savaş - İsabet Kaybı (Negatif)")
@export var isabet_kaybi_sansi: float = 0.0
# 0.20 = %20 ıskalama şansı. CombatEvent okur. Hantal=0.20

@export_group("Savaş - Kan Tadı")
@export var kan_tadi_aktif: bool = false
@export var kan_tadi_enerji: int = 0
# Düşmanı öldürünce enerji kazan. KanTadi=true, kan_tadi_enerji=20

# ==========================================
# YÜZEY ETKİLERİ
# ==========================================

@export_group("Yüzey - Çıkış/Dönüş Enerjisi")
@export var yuzey_enerji_aktif: bool = false
@export var yuzey_cikista_enerji: int = 0
@export var yuzey_donuste_enerji: int = 0

@export_group("Yüzey - Hareket Hızı")
@export var hareket_hizi_bonus: float = 0.0
# +150 = hızlı (GolgeAdim), -120 = yavaş (AgirAdim)
# player.gd velocity hesabında SPEED + Global.hareket_hizi_bonus kullanır

@export_group("Yüzey - Mantar Enerji Bonusu")
@export var mantar_enerji_bonus: int = 0
# magara_girisi.gd her mantar için bu kadar ekstra enerji verir
# MantarSever=+10, MantarTiksintisi=-8

# ==========================================
# VURUŞ MALİYETİ (Kök vurma)
# ==========================================

@export_group("Kök - Vuruş Enerji Maliyeti")
@export var vurus_maliyet_aktif: bool = false
@export var vurus_maliyet_degisim: int = 0
# -3 = daha az enerji harcar (DemirMide), +5 = daha fazla (CabukYorilan)

# ==========================================
# RUNTIME STATE
# ==========================================

var kilitli_mi: bool = false
var yapisik_mi: bool = false
var eklendigi_gun: int = 0

func _ready():
	# Trait geldiginde hemen aktif — pozitif de negatif de
	# kilitli_mi=false: aktif ama korumasiz (overwrite olabilir)
	# kilitli_mi=true: kilitle() sonrasi — overwrite'tan korunur
	eklendigi_gun = Global.gun_sayisi
	_etkileri_uygula()

func _etkileri_uygula():
	if saldiri_aktif and saldiri_degisim != 0:
		Global.balta_hasari += saldiri_degisim

	if vurus_maliyet_aktif and vurus_maliyet_degisim != 0:
		Global.vurus_enerji_bedeli = max(Global.vurus_enerji_bedeli + vurus_maliyet_degisim, 1)

	if hareket_hizi_bonus != 0.0:
		Global.hareket_hizi_bonus += hareket_hizi_bonus

	if mantar_enerji_bonus != 0:
		Global.mantar_enerji_bonus += mantar_enerji_bonus

func _etkileri_geri_al():
	if saldiri_aktif and saldiri_degisim != 0:
		Global.balta_hasari -= saldiri_degisim

	if vurus_maliyet_aktif and vurus_maliyet_degisim != 0:
		Global.vurus_enerji_bedeli = max(Global.vurus_enerji_bedeli - vurus_maliyet_degisim, 1)

	if hareket_hizi_bonus != 0.0:
		Global.hareket_hizi_bonus -= hareket_hizi_bonus

	if mantar_enerji_bonus != 0:
		Global.mantar_enerji_bonus -= mantar_enerji_bonus

# Traiti overwrite'tan koru
func kilitle() -> bool:
	if not pozitif_mi:
		return false
	if kilitli_mi:
		Global.bildirim_gonder("[" + trait_isim + "] zaten kilitli!")
		return false
	if Global.yasam_ozu < kilit_bedeli:
		Global.bildirim_gonder("Yeterli yasam ozu yok! Gerekli: " + str(kilit_bedeli))
		return false
	Global.yasam_ozu -= kilit_bedeli
	kilitli_mi = true
	Global.bildirim_gonder("[" + trait_isim + "] kilitlendi!")
	return true

# Geriye donuk uyumluluk
func kilidi_ac() -> bool:
	return kilitle()

func yapis_kontrol_et():
	if pozitif_mi or yapisik_mi:
		return
	if Global.gun_sayisi - eklendigi_gun >= yapis_gun_esigi:
		yapisik_mi = true
		Global.bildirim_gonder("⚠ [" + trait_isim + "] yapıştı! Çıkarmak: " + str(yapisik_cikarma_bedeli) + " ✦")

func cikar() -> bool:
	if pozitif_mi:
		return false
	var bedel = yapisik_cikarma_bedeli if yapisik_mi else normal_cikarma_bedeli
	if Global.yasam_ozu < bedel:
		Global.bildirim_gonder("Yeterli yaşam özü yok! Gerekli: " + str(bedel))
		return false
	Global.yasam_ozu -= bedel
	_etkileri_geri_al()
	Global.bildirim_gonder("✦ [" + trait_isim + "] çıkarıldı.")
	return true

func tur_basi_efekti_uygula():
	if not tur_basi_enerji_aktif or tur_basi_enerji == 0:
		return
	Global.enerji += tur_basi_enerji
	var i = "+" if tur_basi_enerji > 0 else ""
	Global.bildirim_gonder("[" + trait_isim + "] " + i + str(tur_basi_enerji) + " enerji")

func yuzey_cikis_efekti():
	if not yuzey_enerji_aktif or yuzey_cikista_enerji == 0:
		return
	Global.enerji += yuzey_cikista_enerji
	var i = "+" if yuzey_cikista_enerji > 0 else ""
	Global.bildirim_gonder("[" + trait_isim + "] Çıkışta: " + i + str(yuzey_cikista_enerji) + " enerji")

func yuzey_donus_efekti():
	if not yuzey_enerji_aktif or yuzey_donuste_enerji == 0:
		return
	Global.enerji += yuzey_donuste_enerji
	var i = "+" if yuzey_donuste_enerji > 0 else ""
	Global.bildirim_gonder("[" + trait_isim + "] Dönüşte: " + i + str(yuzey_donuste_enerji) + " enerji")
