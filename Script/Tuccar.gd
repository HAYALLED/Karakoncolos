extends Area2D

var oyuncu_yakinda = false
var menu_acik = false
var secili_indeks = 0

@onready var tuccar_paneli = $TuccarArayuz/TuccarPaneli
@onready var liste_kutusu  = $TuccarArayuz/TuccarPaneli/ListeKutusu
@onready var bilgi_yazisi  = $TuccarArayuz/TuccarPaneli/BilgiYazisi
@onready var para_yazisi   = $TuccarArayuz/TuccarPaneli/ParaYazisi
@onready var prompt_yazisi = $PromptYazisi

@export_group("Kaynak Fiyatlari (Yasam Ozu)")
@export var odun_fiyati: int = 2
@export var odun_miktar: int = 5
@export var tas_fiyati: int = 2
@export var tas_miktar: int = 5
@export var mantar_fiyati: int = 1
@export var mantar_miktar: int = 8
@export var enerji_fiyati: int = 3
@export var enerji_miktar: int = 30
@export var balta_fiyati: int = 5
@export var balta_bonus: int = 3

@export_group("Kozmetik Satisi")
@export var kozmetik_fiyati: int = 8
@export var kozmetik_havuzu: Array[PackedScene] = []
# Inspector'dan 4 test kozmetik sahnesini buraya surukle

var urunler: Array = []

func _ready():
	if tuccar_paneli: tuccar_paneli.hide()
	if prompt_yazisi: prompt_yazisi.hide()
	_urunleri_olustur()

func _process(_delta):
	if oyuncu_yakinda and Input.is_action_just_pressed("etkilesim"):
		if not Global.uretim_acik:
			if not menu_acik:
				menuyu_ac()
			else:
				menuyu_kapat()

	if menu_acik:
		if Input.is_action_just_pressed("ui_down"):
			secili_indeks = (secili_indeks + 1) % urunler.size()
			menuyu_ciz()
		elif Input.is_action_just_pressed("ui_up"):
			secili_indeks = (secili_indeks - 1 + urunler.size()) % urunler.size()
			menuyu_ciz()
		elif Input.is_action_just_pressed("yemek_ye"):
			satin_al()
		elif Input.is_action_just_pressed("duraklat"):
			menuyu_kapat()

func _urunleri_olustur():
	urunler = [
		{"isim": "Odun x%d" % odun_miktar,                     "fiyat": odun_fiyati,    "tip": "odun",   "deger": odun_miktar},
		{"isim": "Tas x%d" % tas_miktar,                        "fiyat": tas_fiyati,     "tip": "tas",    "deger": tas_miktar},
		{"isim": "Mantar x%d" % mantar_miktar,                  "fiyat": mantar_fiyati,  "tip": "mantar", "deger": mantar_miktar},
		{"isim": "Enerji +%d" % enerji_miktar,                  "fiyat": enerji_fiyati,  "tip": "enerji", "deger": enerji_miktar},
		{"isim": "Balta Guclendir (+%d hasar)" % balta_bonus,   "fiyat": balta_fiyati,   "tip": "balta",  "deger": balta_bonus},
	]

	# Kozmetik satirlari — havuzdan dinamik olustur
	for sahne in kozmetik_havuzu:
		var temp = sahne.instantiate()
		var koz_isim = temp.get("kozmetik_isim") if temp.get("kozmetik_isim") else "Kozmetik"
		var koz_slot = str(temp.get("slot")) if temp.get("slot") != null else "?"
		# Zaten sahip olunanlari gosterme
		var mevcut = Global.kozmetikler.get(koz_slot)
		var sahip = mevcut != null and is_instance_valid(mevcut)
		temp.queue_free()

		urunler.append({
			"isim": "Kozmetik: %s [%s]%s" % [koz_isim, koz_slot, " [SAHIP]" if sahip else ""],
			"fiyat": kozmetik_fiyati,
			"tip": "kozmetik",
			"sahne": sahne,
			"sahip": sahip
		})

func menuyu_ac():
	menu_acik = true
	Global.uretim_acik = true
	_urunleri_olustur()
	if tuccar_paneli: tuccar_paneli.show()
	secili_indeks = 0
	menuyu_ciz()
	if prompt_yazisi: prompt_yazisi.hide()

func menuyu_kapat():
	menu_acik = false
	if tuccar_paneli: tuccar_paneli.hide()
	if oyuncu_yakinda and prompt_yazisi:
		prompt_yazisi.show()
	await get_tree().process_frame
	Global.uretim_acik = false

func menuyu_ciz():
	if not liste_kutusu:
		return
	for child in liste_kutusu.get_children():
		liste_kutusu.remove_child(child)
		child.queue_free()

	for i in range(urunler.size()):
		var urun = urunler[i]
		var etiket = Label.new()
		var yazi = "%s  [%d Yasam Ozu]" % [urun["isim"], urun["fiyat"]]
		var sahip_mi = urun.get("sahip", false)
		var karsilayabilir = Global.yasam_ozu >= urun["fiyat"] and not sahip_mi

		if i == secili_indeks:
			etiket.text = "> %s <" % yazi
			if sahip_mi:
				etiket.modulate = Color(0.5, 0.5, 0.5)
			else:
				etiket.modulate = Color(1, 1, 0) if karsilayabilir else Color(1, 0.4, 0.4)
		else:
			etiket.text = yazi
			if sahip_mi:
				etiket.modulate = Color(0.4, 0.4, 0.4)
			else:
				etiket.modulate = Color(0.8, 0.8, 0.8) if karsilayabilir else Color(0.4, 0.4, 0.4)

		liste_kutusu.add_child(etiket)

	if para_yazisi:
		para_yazisi.text = "Yasam Ozu: %d" % Global.yasam_ozu
	if bilgi_yazisi:
		bilgi_yazisi.text = "Yukari/Asagi: Gez | E: Satin Al | ESC: Kapat"
		bilgi_yazisi.modulate = Color(0, 0, 0)

func satin_al():
	var urun = urunler[secili_indeks]

	# Kozmetik - sahiplik kontrolü
	if urun.get("sahip", false):
		if bilgi_yazisi:
			bilgi_yazisi.text = "Bu kozmetike zaten sahipsin!"
			bilgi_yazisi.modulate = Color(0.7, 0.7, 0.2)
		return

	if Global.yasam_ozu < urun["fiyat"]:
		if bilgi_yazisi:
			bilgi_yazisi.text = "Yeterli yasam ozun yok!"
			bilgi_yazisi.modulate = Color(1, 0.3, 0.3)
		return

	Global.yasam_ozu -= urun["fiyat"]

	match urun["tip"]:
		"odun":
			Global.envanter["odun"] += urun["deger"]
			Global.bildirim_gonder("Odun alindi! +%d" % urun["deger"])
		"tas":
			Global.envanter["tas"] += urun["deger"]
			Global.bildirim_gonder("Tas alindi! +%d" % urun["deger"])
		"mantar":
			Global.envanter["mantar"] += urun["deger"]
			Global.bildirim_gonder("Mantar alindi! +%d" % urun["deger"])
		"enerji":
			Global.enerji = min(Global.enerji + urun["deger"], Global.max_enerji)
			Global.bildirim_gonder("Enerji yenilendi! +%d" % urun["deger"])
		"balta":
			Global.balta_hasari += urun["deger"]
			Global.bildirim_gonder("Balta guclendi! +%d hasar" % urun["deger"])
		"kozmetik":
			# Global'e child olarak ekle — sahne degismeden kalici kalir
			var koz = urun["sahne"].instantiate()
			Global.add_child(koz)
			# _ready() otomatik Global.kozmetikler[slot] = self yapar
			Global.bildirim_gonder("Kozmetik alindi! %s" % koz.kozmetik_isim)
			# DEBUG: Kontrol
			print("DEBUG Tuccar: kozmetikler = ", Global.kozmetikler)
			print("DEBUG Tuccar: koz.on_texture = ", koz.on_texture)
			# Listeyi guncelle — sahip olanlar gri gorsunsun
			_urunleri_olustur()

	if bilgi_yazisi:
		bilgi_yazisi.text = "Satin alindi!"
		bilgi_yazisi.modulate = Color(0.3, 1, 0.3)
	menuyu_ciz()

func _on_body_entered(body):
	if body.name == "Karakoncolos":
		oyuncu_yakinda = true
		if not menu_acik and prompt_yazisi:
			prompt_yazisi.show()

func _on_body_exited(body):
	if body.name == "Karakoncolos":
		oyuncu_yakinda = false
		if prompt_yazisi: prompt_yazisi.hide()
		if menu_acik: menuyu_kapat()
