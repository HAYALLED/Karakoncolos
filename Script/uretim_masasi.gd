extends Area2D

var oyuncu_yakinda = false
var menu_acik = false
var secili_indeks = 0

@onready var crafting_paneli = $CraftingArayuz/CraftingPaneli
@onready var liste_kutusu = $CraftingArayuz/CraftingPaneli/ListeKutusu
@onready var bilgi_yazisi = $CraftingArayuz/CraftingPaneli/BilgiYazisi
# Sahneye eklediğimiz etkileşim yazısı:
@onready var prompt_yazisi = $PromptYazisi 

func _ready():
	if crafting_paneli:
		crafting_paneli.hide()
	# Oyun başlarken havada yazı kalmasın diye gizliyoruz
	if prompt_yazisi:
		prompt_yazisi.hide()

func _process(_delta):
	if oyuncu_yakinda and Input.is_action_just_pressed("etkilesim"):
		if menu_acik == false:
			menuyu_ac()
		else:
			menuyu_kapat()

	if menu_acik:
		if Input.is_action_just_pressed("ui_down"):
			secili_indeks += 1
			if secili_indeks >= Global.tarifler.size():
				secili_indeks = 0 
			menuyu_ciz()

		elif Input.is_action_just_pressed("ui_up"):
			secili_indeks -= 1
			if secili_indeks < 0:
				secili_indeks = Global.tarifler.size() - 1 
			menuyu_ciz()

		elif Input.is_action_just_pressed("yemek_ye"):
			esya_uret()

		elif Input.is_action_just_pressed("duraklat"):
			menuyu_kapat()

func menuyu_ac():
	menu_acik = true
	Global.uretim_acik = true # Karakoncolos'a "Ben açıldım, ESC'ye basarsa oyunu durdurma!" diyoruz.
	crafting_paneli.show()
	secili_indeks = 0
	menuyu_ciz()
	if prompt_yazisi:
		prompt_yazisi.hide()

func menuyu_kapat():
	menu_acik = false
	crafting_paneli.hide()
	if oyuncu_yakinda and prompt_yazisi:
		prompt_yazisi.show()
		
	# ÇOK ÖNEMLİ: Menü kapanırken aynı salise içinde karakter oyunu durdurmasın diye 1 kare (frame) bekletiyoruz
	await get_tree().process_frame
	Global.uretim_acik = false

func menuyu_ciz():
	if not liste_kutusu: return
	
	for child in liste_kutusu.get_children():
		liste_kutusu.remove_child(child)
		child.queue_free()
		
	for i in range(Global.tarifler.size()):
		var tarif = Global.tarifler[i]
		var etiket = Label.new() 
		
		var yazi = tarif["isim"]
		if tarif["uretildi"] == true:
			yazi += " [SAHİPSİN]"
		else:
			yazi += " | Maliyet: "
			if tarif["tas_bedeli"] > 0: yazi += str(tarif["tas_bedeli"]) + " Taş "
			if tarif["odun_bedeli"] > 0: yazi += str(tarif["odun_bedeli"]) + " Odun"
		
		var yapabilir_mi = (Global.envanter["tas"] >= tarif["tas_bedeli"]) and (Global.envanter["odun"] >= tarif["odun_bedeli"])
		
		if i == secili_indeks:
			etiket.text = "> " + yazi + " <"
			
			if tarif["uretildi"]:
				etiket.modulate = Color(0.5, 0.5, 0.5) 
			elif yapabilir_mi:
				etiket.modulate = Color(1, 1, 0) 
			else:
				etiket.modulate = Color(1, 0.4, 0.4) 
		else:
			etiket.text = yazi
			
			if tarif["uretildi"]:
				etiket.modulate = Color(0.3, 0.3, 0.3) 
			elif yapabilir_mi:
				etiket.modulate = Color(0.1, 0.8, 0.1) 
			else:
				etiket.modulate = Color(0.4, 0.4, 0.4) 
				
		liste_kutusu.add_child(etiket)
		
	bilgi_yazisi.text = "Yukarı/Aşağı: Gez | E: Üret | F: Kapat"
	bilgi_yazisi.modulate = Color(0, 0, 0) 

func esya_uret():
	var secilen_tarif = Global.tarifler[secili_indeks]
	
	if secilen_tarif["uretildi"] == true:
		bilgi_yazisi.text = "BUNA ZATEN SAHİPSİN!"
		bilgi_yazisi.modulate = Color(1, 0.5, 0) 
		return 
		
	if Global.envanter["tas"] >= secilen_tarif["tas_bedeli"] and Global.envanter["odun"] >= secilen_tarif["odun_bedeli"]:
		
		Global.envanter["tas"] -= secilen_tarif["tas_bedeli"]
		Global.envanter["odun"] -= secilen_tarif["odun_bedeli"]
		
		if secilen_tarif["tip"] == "hasar":
			Global.balta_hasari += secilen_tarif["deger"]
			bilgi_yazisi.text = "ÜRETİLDİ! Yeni Hasar: " + str(Global.balta_hasari)
			bilgi_yazisi.modulate = Color(0, 0.8, 0) 
			
		elif secilen_tarif["tip"] == "enerji_tasarrufu":
			Global.vurus_enerji_bedeli -= secilen_tarif["deger"]
			if Global.vurus_enerji_bedeli < 1: 
				Global.vurus_enerji_bedeli = 1 
			bilgi_yazisi.text = "ÜRETİLDİ! Ağaca vurmak daha az enerji istiyor."
			bilgi_yazisi.modulate = Color(0, 0.8, 0)
			
		Global.balta_seviyesi += 1
		
		secilen_tarif["uretildi"] = true
		
		Global.bildirim_gonder("Başarıyla üretildi: " + secilen_tarif["isim"])
		menuyu_ciz()
	else:
		bilgi_yazisi.text = "YETERSİZ MALZEME!"
		bilgi_yazisi.modulate = Color(1, 0, 0) 
		Global.bildirim_gonder("Yetersiz malzeme!")

func _on_body_entered(body):
	if body.name == "Karakoncolos":
		oyuncu_yakinda = true
		# Oyuncu gelince, menü açık değilse yazıyı göster
		if not menu_acik and prompt_yazisi:
			prompt_yazisi.show()

func _on_body_exited(body):
	if body.name == "Karakoncolos":
		oyuncu_yakinda = false
		# Oyuncu gidince yazıyı kesinlikle gizle
		if prompt_yazisi:
			prompt_yazisi.hide()
		# Masadan uzaklaşırsa menüyü otomatik kapat
		if menu_acik:
			menuyu_kapat()
