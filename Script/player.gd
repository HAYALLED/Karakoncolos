extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


@onready var gun_yazisi = $Arayuz/GunYazisi
@onready var duraklatma_menusu = $Arayuz/DuraklatmaMenusu
@onready var envanter_paneli = $Arayuz/EnvanterPaneli

@onready var mantar_slot = $Arayuz/EnvanterPaneli/HBoxContainer/MantarSlot
@onready var mantar_yazisi = $Arayuz/EnvanterPaneli/HBoxContainer/MantarSlot/Label
@onready var tas_slot = $Arayuz/EnvanterPaneli/HBoxContainer/TasSlot
@onready var tas_yazisi = $Arayuz/EnvanterPaneli/HBoxContainer/TasSlot/Label
@onready var odun_slot = $Arayuz/EnvanterPaneli/HBoxContainer/OdunSlot
@onready var odun_yazisi = $Arayuz/EnvanterPaneli/HBoxContainer/OdunSlot/Label

@onready var enerji_yazisi = $Arayuz/EnerjiYazisi
@onready var relic_container = get_node_or_null("Arayuz/EnvanterPaneli/RelicContainer")
@onready var karakter_ekrani = get_node_or_null("KarakterEkrani")
@onready var trait_yoneticisi = get_node_or_null("TraitYoneticisi")
@onready var sapka_sprite = get_node_or_null("Sprite2D/Sapka")
@onready var govde_sprite = get_node_or_null("Sprite2D/Govde")
@onready var pantalon_sprite = get_node_or_null("Sprite2D/Pantalon")
@onready var ayakkabi_sprite = get_node_or_null("Sprite2D/Ayakkabi")

func _ready():
	pass  # KarakterEkrani kendi CanvasLayer'ini _ready'de gizli baslatir

func _process(_delta):
	if Input.is_action_just_pressed("duraklat"):
		if Global.uretim_acik == false and not (karakter_ekrani and karakter_ekrani.ekran_acik):
			oyunu_duraklat()

	if Input.is_action_just_pressed("karakter_ekrani"):
		_karakter_ekrani_toggle()

	if get_tree().paused: return

	if enerji_yazisi:
		enerji_yazisi.text = "Enerji: " + str(Global.enerji)
	if gun_yazisi:
		gun_yazisi.text = "Gun: " + str(Global.gun_sayisi)

	if Global.envanter["mantar"] > 0:
		mantar_slot.show()
		mantar_yazisi.text = str(Global.envanter["mantar"])
	else:
		mantar_slot.hide()

	if Global.envanter["tas"] > 0:
		tas_slot.show()
		tas_yazisi.text = str(Global.envanter["tas"])
	else:
		tas_slot.hide()

	if Global.envanter["odun"] > 0:
		odun_slot.show()
		odun_yazisi.text = str(Global.envanter["odun"])
	else:
		odun_slot.hide()

	_relic_slotlari_guncelle()
	_kozmetikleri_uygula()

	if Input.is_action_just_pressed("envanter_ac"):
		envanter_paneli.visible = !envanter_paneli.visible

func _physics_process(delta):
	if get_tree().paused: return

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction = Input.get_axis("sol", "sag")
	var gercek_hiz = SPEED + Global.hareket_hizi_bonus
	if direction:
		velocity.x = direction * gercek_hiz
	else:
		velocity.x = move_toward(velocity.x, 0, gercek_hiz)

	move_and_slide()

func oyunu_duraklat():
	if get_tree().paused:
		get_tree().paused = false
		duraklatma_menusu.hide()
	else:
		get_tree().paused = true
		duraklatma_menusu.show()

func _on_devam_butonu_pressed():
	oyunu_duraklat()

func _on_ana_menu_butonu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/ana_menu.tscn")

func _relic_slotlari_guncelle():
	if not relic_container:
		return

	# DUZELTME: queue_free edilmis ama listede kalan relici temizle — "previously freed" hatasinin kaynagi
	Global.aktif_relicler = Global.aktif_relicler.filter(func(r): return is_instance_valid(r))

	for child in relic_container.get_children():
		relic_container.remove_child(child)
		child.queue_free()

	for relic in Global.aktif_relicler:
		var sprite = relic.get_node_or_null("Sprite2D")
		if sprite and sprite.texture:
			var tex_rect = TextureRect.new()
			tex_rect.texture = sprite.texture
			tex_rect.custom_minimum_size = Vector2(32, 32)
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.tooltip_text = relic.relic_isim
			relic_container.add_child(tex_rect)
		else:
			var slot_label = Label.new()
			slot_label.text = relic.relic_isim
			slot_label.modulate = Color(1, 0.9, 0.4)
			relic_container.add_child(slot_label)

func _karakter_ekrani_toggle():
	if not karakter_ekrani:
		return
	# Yeni KarakterEkrani: ekran_acik property + ac()/kapat() metodlari kullanir
	if karakter_ekrani.ekran_acik:
		karakter_ekrani.kapat()
		get_tree().paused = false
	else:
		karakter_ekrani.ac()
		get_tree().paused = true

func _kozmetikleri_uygula():
	_slot_guncelle(sapka_sprite, Global.kozmetikler.get("sapka"))
	_slot_guncelle(govde_sprite, Global.kozmetikler.get("govde"))
	_slot_guncelle(pantalon_sprite, Global.kozmetikler.get("pantalon"))
	_slot_guncelle(ayakkabi_sprite, Global.kozmetikler.get("ayakkabi"))

func _slot_guncelle(hedef: Sprite2D, koz):
	if not hedef:
		return
	if koz and is_instance_valid(koz) and koz.get("on_texture"):
		if hedef.texture != koz.on_texture:
			hedef.texture = koz.on_texture
			hedef.visible = true
			# DEBUG: kaldır sonra
			print("DEBUG _slot_guncelle: %s -> texture ATANDI, visible=true" % hedef.name)
	else:
		hedef.texture = null
		hedef.visible = false

func _debug_kozmetik():
	# Bunu bir kere cagirir — F5 ile test et
	for slot_adi in ["sapka", "govde", "pantalon", "ayakkabi"]:
		var koz = Global.kozmetikler.get(slot_adi)
		if koz:
			print("DEBUG slot=%s valid=%s texture=%s" % [slot_adi, is_instance_valid(koz), koz.get("on_texture")])
