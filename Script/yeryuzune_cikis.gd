extends Area2D

var oyuncu_yakinda = false
var menu_acik = false
var secili_indeks = 0
var bebek_menu_acik = false
var bebek_gorev_indeks = 0

@onready var mekan_paneli = $MekanArayuz/MekanPaneli
@onready var liste_kutusu = $MekanArayuz/MekanPaneli/ListeKutusu
@onready var bilgi_yazisi = $MekanArayuz/MekanPaneli/BilgiYazisi
@onready var prompt_yazisi = $PromptYazisi

var mekanlar = [
	{"isim": "Orman (Bol Odun, Az Mantar)", "sahne": "res://Scene/yer_ustu.tscn"},
	{"isim": "Rutubetli Tarla (Bol Mantar)", "sahne": "res://Scene/yer_ustu.tscn"},
	{"isim": "Taş Ocağı (Sadece Taş ve Tehlike)", "sahne": "res://Scene/yer_ustu.tscn"}
]

var bebek_gorevleri = [
	{"isim": "Taş Topla", "kaynak": "tas", "min": 1, "max": 3},
	{"isim": "Odun Topla", "kaynak": "odun", "min": 1, "max": 3},
	{"isim": "Mantar Topla", "kaynak": "mantar", "min": 1, "max": 4},
]

func _ready():
	if mekan_paneli: mekan_paneli.hide()
	if prompt_yazisi: prompt_yazisi.hide()

func _process(_delta):
	if oyuncu_yakinda and Input.is_action_just_pressed("etkilesim"):
		if bebek_menu_acik:
			_bebek_gorevini_sec()
		elif menu_acik:
			menuyu_kapat()
		else:
			if Global.bebek_sayisi > 0:
				_bebek_menuyu_ac()
			else:
				menuyu_ac()

	if bebek_menu_acik:
		if Input.is_action_just_pressed("ui_down"):
			bebek_gorev_indeks = (bebek_gorev_indeks + 1) % bebek_gorevleri.size()
			_bebek_menuyu_ciz()
		elif Input.is_action_just_pressed("ui_up"):
			bebek_gorev_indeks = (bebek_gorev_indeks - 1 + bebek_gorevleri.size()) % bebek_gorevleri.size()
			_bebek_menuyu_ciz()
		elif Input.is_action_just_pressed("duraklat"):
			_bebek_menuyu_kapat()
			menuyu_ac()
		return

	if menu_acik:
		if Input.is_action_just_pressed("ui_down"):
			secili_indeks = (secili_indeks + 1) % mekanlar.size()
			menuyu_ciz()
		elif Input.is_action_just_pressed("ui_up"):
			secili_indeks = (secili_indeks - 1 + mekanlar.size()) % mekanlar.size()
			menuyu_ciz()
		elif Input.is_action_just_pressed("yemek_ye"):
			mekana_git()
		elif Input.is_action_just_pressed("duraklat"):
			menuyu_kapat()

# ==========================================
# BEBEK GÖREVLENDİRME
# ==========================================
func _bebek_menuyu_ac():
	bebek_menu_acik = true
	Global.uretim_acik = true
	bebek_gorev_indeks = 0
	mekan_paneli.show()
	_bebek_menuyu_ciz()
	if prompt_yazisi: prompt_yazisi.hide()

func _bebek_menuyu_kapat():
	bebek_menu_acik = false
	mekan_paneli.hide()
	# await YOK — await olursa menuyu_ac() önce çalışır, sonra uretim_acik=false gelir ve menü kilitlenir
	Global.uretim_acik = false

func _bebek_menuyu_ciz():
	for child in liste_kutusu.get_children():
		liste_kutusu.remove_child(child)
		child.queue_free()

	var baslik = Label.new()
	baslik.text = "BEBEKLER (" + str(Global.bebek_sayisi) + ") — Görev Ver:"
	baslik.modulate = Color(1, 0.8, 0.2)
	liste_kutusu.add_child(baslik)

	for i in range(bebek_gorevleri.size()):
		var gorev = bebek_gorevleri[i]
		var etiket = Label.new()
		if i == bebek_gorev_indeks:
			etiket.text = "> " + gorev["isim"] + " <"
			etiket.modulate = Color(1, 1, 0)
		else:
			etiket.text = gorev["isim"]
			etiket.modulate = Color(1, 1, 1)
		liste_kutusu.add_child(etiket)

	bilgi_yazisi.text = "Yukarı/Aşağı: Gez | E: Görevlendir | ESC: Atla"
	bilgi_yazisi.modulate = Color(1, 1, 1)

func _bebek_gorevini_sec():
	var secilen_gorev = bebek_gorevleri[bebek_gorev_indeks]

	var toplam = 0
	for _i in range(Global.bebek_sayisi):
		toplam += randi_range(secilen_gorev["min"], secilen_gorev["max"])

	Global.envanter[secilen_gorev["kaynak"]] += toplam
	Global.bildirim_gonder(
		str(Global.bebek_sayisi) + " bebek görevlendi! +" + str(toplam) + " " + secilen_gorev["kaynak"]
	)

	# Bebek menüsü kapanınca uretim_acik'ı hemen kapat — menuyu_ac tekrar açacak
	bebek_menu_acik = false
	mekan_paneli.hide()
	Global.uretim_acik = false
	menuyu_ac()

# ==========================================
# YÜZEY MENÜSÜ
# ==========================================
func menuyu_ac():
	menu_acik = true
	Global.uretim_acik = true
	mekan_paneli.show()
	secili_indeks = 0
	menuyu_ciz()
	if prompt_yazisi: prompt_yazisi.hide()

func menuyu_kapat():
	menu_acik = false
	mekan_paneli.hide()
	if oyuncu_yakinda and prompt_yazisi:
		prompt_yazisi.show()
	await get_tree().process_frame
	Global.uretim_acik = false

func menuyu_ciz():
	for child in liste_kutusu.get_children():
		liste_kutusu.remove_child(child)
		child.queue_free()

	for i in range(mekanlar.size()):
		var mekan = mekanlar[i]
		var etiket = Label.new()
		if i == secili_indeks:
			etiket.text = "> " + mekan["isim"] + " <"
			etiket.modulate = Color(1, 1, 0)
		else:
			etiket.text = mekan["isim"]
			etiket.modulate = Color(1, 1, 1)
		liste_kutusu.add_child(etiket)

	bilgi_yazisi.text = "Yukarı/Aşağı: Gez | E: Yola Çık | ESC: Vazgeç"
	bilgi_yazisi.modulate = Color(1, 1, 1)

func mekana_git():
	var secilen_mekan = mekanlar[secili_indeks]

	if Global.ilk_cikis == true:
		Global.ilk_cikis = false
		Global.bildirim_gonder("Gün " + str(Global.gun_sayisi) + ": " + secilen_mekan["isim"] + " yoluna düşüldü.")
	else:
		Global.gun_sayisi += 1
		Global.bildirim_gonder("Gün " + str(Global.gun_sayisi) + ": " + secilen_mekan["isim"] + " yoluna düşüldü.")
		if Global.gun_sayisi % Global.bahar_dongusu == 0:
			Global.kok_guncel_can += Global.iyilesme_miktari
			if Global.kok_guncel_can > Global.kok_baslangic_cani:
				Global.kok_guncel_can = Global.kok_baslangic_cani
			Global.bildirim_gonder("BAHAR GELDİ! Kökün Canı: " + str(Global.kok_guncel_can))

		# DUZELTME: gun_basi_kontrol her gun calisir — bahar bloguna tasinmadi
		var karakoncolos = get_tree().current_scene.get_node_or_null("Karakoncolos")
		if karakoncolos:
			var ty = karakoncolos.get_node_or_null("TraitYoneticisi")
			if ty and ty.has_method("gun_basi_kontrol"):
				ty.gun_basi_kontrol()

	# DUZELTME: freed instance temizle — yuzey_cikis_efekti dongusu oncesi
	Global.aktif_relicler = Global.aktif_relicler.filter(func(r): return is_instance_valid(r))
	Global.aktif_traitler = Global.aktif_traitler.filter(func(t): return is_instance_valid(t))

	# Relic çıkış efektleri
	for relic in Global.aktif_relicler:
		if relic.has_method("yuzey_cikis_efekti"):
			relic.yuzey_cikis_efekti()
	# Trait çıkış efektleri
	for t in Global.aktif_traitler:
		if t.has_method("yuzey_cikis_efekti"):
			t.yuzey_cikis_efekti()

	menu_acik = false
	Global.uretim_acik = false
	get_tree().call_deferred("change_scene_to_file", secilen_mekan["sahne"])

# ==========================================
# ETKİLEŞİM
# ==========================================
func _on_body_entered(body):
	if body.name == "Karakoncolos":
		oyuncu_yakinda = true
		if not menu_acik and not bebek_menu_acik and prompt_yazisi:
			prompt_yazisi.show()

func _on_body_exited(body):
	if body.name == "Karakoncolos":
		oyuncu_yakinda = false
		if prompt_yazisi: prompt_yazisi.hide()
		if menu_acik: menuyu_kapat()
		if bebek_menu_acik: _bebek_menuyu_kapat()
