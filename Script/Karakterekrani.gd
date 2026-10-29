extends Control

# ==========================================
# KARAKTER EKRANI
# Root: Control
# Görsel: $CanvasLayer aç/kapat
# process_mode = ALWAYS — pause'da çalışır
#
# Scene yapısı (Karakterekrani.tscn):
# Control "Karakterekrani"            ← bu script
#  └── CanvasLayer (layer=6)
#       └── Control "tam ekran"       (full rect)
#            ├── ColorRect "arkaplan" (full rect)
#            └── VBoxContainer "ana layout" (full rect, margin)
#                 ├── HBoxContainer "üst bar"
#                 │    ├── Label "EnerjiYazisi"
#                 │    └── Label "YasamOzuYazisi"
#                 ├── HBoxContainer "orta"        ← size_flags vertical expand
#                 │    ├── VBoxContainer "PozitifKutu"
#                 │    ├── VBoxContainer "MerkezKutu"
#                 │    └── VBoxContainer "NegatifKutu"
#                 └── TabContainer "KodeksTab"
#                      ├── ScrollContainer "Esya Kitapligi"
#                      │    └── VBoxContainer "EsyaListe"
#                      └── ScrollContainer "Dusman Kitapligi"
#                           └── VBoxContainer "DusmanListe"
# ==========================================

@onready var _canvas       = $CanvasLayer
@onready var enerji_yazisi = $"CanvasLayer/tam ekran/ana layout/üst bar/EnerjiYazisi"
@onready var yasam_yazisi  = $"CanvasLayer/tam ekran/ana layout/üst bar/YasamOzuYazisi"
@onready var pozitif_kutu  = $"CanvasLayer/tam ekran/ana layout/orta/PozitifKutu"
@onready var merkez_kutu   = $"CanvasLayer/tam ekran/ana layout/orta/MerkezKutu"
@onready var negatif_kutu  = $"CanvasLayer/tam ekran/ana layout/orta/NegatifKutu"
@onready var esya_liste    = $"CanvasLayer/tam ekran/ana layout/KodeksTab/Esya Kitapligi/EsyaListe"
@onready var dusman_liste  = $"CanvasLayer/tam ekran/ana layout/KodeksTab/Dusman Kitapligi/DusmanListe"

const C_POZITIF = Color(0.4,  1.0,  0.5,  1.0)  # Yeşil  — aktif, korumasız
const C_KILITLI = Color(0.95, 0.78, 0.1,  1.0)  # Altın  — kilitli, korumalı
const C_NEGATIF = Color(1.0,  0.4,  0.4,  1.0)  # Kırmızı
const C_NORMAL  = Color(0.88, 0.88, 0.88, 1.0)
const C_RELIC   = Color(0.9,  0.75, 1.0,  1.0)
const C_GIZ     = Color(0.45, 0.45, 0.45, 1.0)
const C_BASLIK  = Color(1.0,  0.85, 0.3,  1.0)

func _ready():
	_canvas.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

# ==========================================
# AÇMA / KAPAMA
# ==========================================
var ekran_acik: bool:
	get: return _canvas.visible

func ac():
	_canvas.visible = true
	guncelle()

func kapat():
	_canvas.visible = false

# ==========================================
# GÜNCELLEME
# ==========================================
func guncelle():
	Global.aktif_relicler = Global.aktif_relicler.filter(func(r): return is_instance_valid(r))
	Global.aktif_traitler = Global.aktif_traitler.filter(func(t): return is_instance_valid(t))

	enerji_yazisi.text = "Enerji: %d / %d" % [Global.enerji, Global.max_enerji]
	yasam_yazisi.text  = "Yasam Ozu: %d" % Global.yasam_ozu

	_traitler_guncelle()
	_merkez_guncelle()
	_esya_kodeks_guncelle()
	_dusman_kodeks_guncelle()

func _stat_guncelle():
	enerji_yazisi.text = "Enerji: %d / %d" % [Global.enerji, Global.max_enerji]
	yasam_yazisi.text  = "Yasam Ozu: %d" % Global.yasam_ozu

# ==========================================
# TRAİTLER
# kilitli_mi=false → aktif, korumasız → "Kilitle [bedel]" butonu
# kilitli_mi=true  → aktif, korumalı  → altın renk
# Negatif → "Sil [bedel]" butonu
# ==========================================
func _traitler_guncelle():
	_temizle(pozitif_kutu)
	_temizle(negatif_kutu)

	var pozitifler = Global.aktif_traitler.filter(func(t): return t.pozitif_mi)
	var negatifler = Global.aktif_traitler.filter(func(t): return not t.pozitif_mi)

	# --- POZİTİF ---
	if pozitifler.is_empty():
		pozitif_kutu.add_child(_lbl("-- Henuz yok --", C_GIZ, 12))
	for t in pozitifler:
		if t.kilitli_mi:
			pozitif_kutu.add_child(_lbl_wrap("▲ %s  [KILITLI]" % t.trait_isim, C_KILITLI, 13))
			pozitif_kutu.add_child(_lbl_wrap("  %s" % t.trait_aciklama, C_NORMAL, 11))
			pozitif_kutu.add_child(_lbl("  Overwrite korumasinda.", C_KILITLI, 11))
			var btn_sil = _buton("Sil", Color(0.75, 0.15, 0.15))
			var t_ref = t
			btn_sil.pressed.connect(func():
				t_ref._etkileri_geri_al()
				Global.aktif_traitler.erase(t_ref)
				t_ref.queue_free()
				_stat_guncelle()
				_traitler_guncelle()
			)
			pozitif_kutu.add_child(btn_sil)
		else:
			pozitif_kutu.add_child(_lbl_wrap("▲ %s  [Aktif]" % t.trait_isim, C_POZITIF, 13))
			pozitif_kutu.add_child(_lbl_wrap("  %s" % t.trait_aciklama, C_NORMAL, 11))
			# İki buton: Kilitle veya Sil
			var buton_kutu = HBoxContainer.new()
			var btn_kilitle = _buton("Kilitle [%d YO]" % t.kilit_bedeli, Color(0.2, 0.5, 0.85))
			var btn_sil = _buton("Sil", Color(0.75, 0.15, 0.15))
			var t_ref = t
			btn_kilitle.pressed.connect(func():
				if t_ref.kilitle():
					_stat_guncelle()
					_traitler_guncelle()
			)
			btn_sil.pressed.connect(func():
				t_ref._etkileri_geri_al()
				Global.aktif_traitler.erase(t_ref)
				t_ref.queue_free()
				_stat_guncelle()
				_traitler_guncelle()
			)
			buton_kutu.add_child(btn_kilitle)
			buton_kutu.add_child(btn_sil)
			pozitif_kutu.add_child(buton_kutu)
		pozitif_kutu.add_child(_ayirici())

	# --- NEGATİF ---
	if negatifler.is_empty():
		negatif_kutu.add_child(_lbl("-- Henuz yok --", C_GIZ, 12))
	for t in negatifler:
		var bedel = t.yapisik_cikarma_bedeli if t.yapisik_mi else t.normal_cikarma_bedeli
		if t.yapisik_mi:
			var durum = "YAPISIK"
			negatif_kutu.add_child(_lbl_wrap("▼ %s  [%s]" % [t.trait_isim, durum], Color(0.8, 0.2, 0.2), 13))
		else:
			var kalan = t.yapis_gun_esigi - (Global.gun_sayisi - t.eklendigi_gun)
			var durum = "Normal — %d gun sonra yapisir" % max(kalan, 0)
			negatif_kutu.add_child(_lbl_wrap("▼ %s  [%s]" % [t.trait_isim, durum], C_NEGATIF, 13))
		negatif_kutu.add_child(_lbl_wrap("  %s" % t.trait_aciklama, C_NORMAL, 11))
		var btn = _buton("Sil  [%d Yasam Ozu]" % bedel, Color(0.75, 0.15, 0.15))
		var t_ref = t
		btn.pressed.connect(func():
			if t_ref.cikar():
				Global.aktif_traitler.erase(t_ref)
				t_ref.queue_free()
			_stat_guncelle()
			_traitler_guncelle()
		)
		negatif_kutu.add_child(btn)
		negatif_kutu.add_child(_ayirici())

# ==========================================
# MERKEZ: Kozmetik + Relic
# ==========================================
func _merkez_guncelle():
	_temizle(merkez_kutu)

	# --- ENVANTER ---
	merkez_kutu.add_child(_lbl("ENVANTER", C_BASLIK, 14))
	merkez_kutu.add_child(_ayirici())
	var env_metin = "Mantar: %d  |  Tas: %d  |  Odun: %d" % [
		Global.envanter["mantar"], Global.envanter["tas"], Global.envanter["odun"]]
	merkez_kutu.add_child(_lbl(env_metin, C_NORMAL, 13))
	merkez_kutu.add_child(_ayirici())

	merkez_kutu.add_child(_lbl("KOZMETIKLER", C_BASLIK, 14))
	merkez_kutu.add_child(_ayirici())
	var slot_isimler = {"sapka":"Sapka","govde":"Govde","pantalon":"Pantalon","ayakkabi":"Ayakkabi"}
	for slot in ["sapka","govde","pantalon","ayakkabi"]:
		var koz = Global.kozmetikler.get(slot)
		if koz and not is_instance_valid(koz):
			Global.kozmetikler[slot] = null
			koz = null
		merkez_kutu.add_child(_lbl("%s: %s" % [slot_isimler[slot], koz.kozmetik_isim if koz else "---"], C_NORMAL, 13))

	merkez_kutu.add_child(_ayirici())
	merkez_kutu.add_child(_lbl("RELICLER", C_RELIC, 14))
	merkez_kutu.add_child(_ayirici())
	if Global.aktif_relicler.is_empty():
		merkez_kutu.add_child(_lbl("-- Henuz yok --", C_GIZ, 12))
	else:
		var scroll = ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.custom_minimum_size = Vector2(0, 120)
		var liste = VBoxContainer.new()
		liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for r in Global.aktif_relicler:
			liste.add_child(_lbl("* %s" % r.relic_isim, C_RELIC, 12))
			liste.add_child(_lbl_wrap("  %s" % r.relic_aciklama, C_NORMAL, 10))
			liste.add_child(_ayirici())
		scroll.add_child(liste)
		merkez_kutu.add_child(scroll)

# ==========================================
# EŞYA KODEKSİ
# ==========================================
func _esya_kodeks_guncelle():
	_temizle(esya_liste)
	if Global.esya_kodeks.is_empty():
		esya_liste.add_child(_lbl("Henuz hicbir esya gormedin.", C_GIZ, 12))
		return
	for isim in Global.esya_kodeks:
		var veri = Global.esya_kodeks[isim]
		if veri["sahip"]:
			esya_liste.add_child(_lbl("* %s" % isim, C_RELIC, 13))
			esya_liste.add_child(_lbl_wrap("  %s" % veri["aciklama"], C_NORMAL, 11))
		else:
			esya_liste.add_child(_lbl("? %s  [Sahip degil]" % isim, C_GIZ, 13))

# ==========================================
# DÜŞMAN KODEKSİ
# ==========================================
func _dusman_kodeks_guncelle():
	_temizle(dusman_liste)
	if Global.dusman_kodeks.is_empty():
		dusman_liste.add_child(_lbl("Henuz hicbir dusman gormedin.", C_GIZ, 12))
		return
	for isim in Global.dusman_kodeks:
		var sayi = Global.dusman_kodeks[isim]
		var satir = "X %s  [%dx]" % [isim, sayi]
		if sayi >= 3: satir += "  Can: %s" % str(Global.dusman_can_kodeks.get(isim,"?"))
		if sayi >= 5: satir += "  Saldiri: %s" % str(Global.dusman_saldiri_kodeks.get(isim,"?"))
		var renk = Color(1.0,0.5,0.5) if sayi >= 5 else Color(0.8,0.4,0.4)
		dusman_liste.add_child(_lbl_wrap(satir, renk, 13))
		if sayi >= 7 and Global.dusman_aciklama_kodeks.has(isim):
			dusman_liste.add_child(_lbl_wrap("  %s" % Global.dusman_aciklama_kodeks[isim], C_NORMAL, 11))

# ==========================================
# YARDIMCILAR
# ==========================================
func _lbl(metin: String, renk: Color, boyut: int) -> Label:
	var l = Label.new()
	l.text = metin
	l.modulate = renk
	l.add_theme_font_size_override("font_size", boyut)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _lbl_wrap(metin: String, renk: Color, boyut: int) -> Label:
	var l = _lbl(metin, renk, boyut)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _buton(metin: String, renk: Color) -> Button:
	var b = Button.new()
	b.text = metin
	b.modulate = renk
	b.add_theme_font_size_override("font_size", 12)
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	return b

func _ayirici() -> HSeparator:
	var s = HSeparator.new()
	s.modulate = Color(1, 1, 1, 0.12)
	return s

func _temizle(kutu: Node):
	for child in kutu.get_children():
		kutu.remove_child(child)
		child.queue_free()
