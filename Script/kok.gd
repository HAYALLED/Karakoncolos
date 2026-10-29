extends StaticBody2D

var oyuncu_yakinda = false

@onready var can_bari = $ProgressBar
@onready var prompt_yazisi = $PromptYazisi

@export var saldiri_hizi: float = 0.5
var saldiri_sayaci: float = 0.0

@export_group("Yaşam Özü")
@export var yasam_ozu_sansi: float = 0.50

@export_group("Relic Drop")
@export var relic_drop_sansi: float = 0.05
@export var relic_havuzu: Array[PackedScene] = []

@export var event_yoneticisi: Node

var bekleyen_relic: Node = null
var relic_secim_acik: bool = false

var esik_75_ateslendi: bool = false
var esik_50_ateslendi: bool = false
var esik_25_ateslendi: bool = false

func _ready():
	can_bari.max_value = Global.kok_baslangic_cani
	can_bari.value = Global.kok_guncel_can
	if prompt_yazisi:
		prompt_yazisi.hide()

func _process(delta):
	if saldiri_sayaci > 0:
		saldiri_sayaci -= delta

	if relic_secim_acik:
		if Input.is_action_just_pressed("etkilesim"):
			_relici_al()
		elif Input.is_action_just_pressed("duraklat"):
			_relici_reddet()
		return

	if Global.event_aktif:
		return

	if oyuncu_yakinda == true and Input.is_action_pressed("etkilesim"):
		if saldiri_sayaci <= 0:
			if Global.enerji >= Global.vurus_enerji_bedeli:
				Global.enerji -= Global.vurus_enerji_bedeli
				Global.kok_guncel_can -= Global.balta_hasari
				can_bari.value = Global.kok_guncel_can

				Global.bildirim_gonder("Koke " + str(Global.balta_hasari) + " hasar vurdun! Kalan Enerji: " + str(Global.enerji))

				if randf() <= yasam_ozu_sansi:
					Global.yasam_ozu += 1
					Global.bildirim_gonder("✦ Yasam ozu dustu! Toplam: " + str(Global.yasam_ozu))

				saldiri_sayaci = saldiri_hizi

				# Eşik kontrolü — tetiklenirse relic drop atlanır (override)
				if not _esik_kontrol():
					_relic_drop_kontrol()

				if Global.kok_guncel_can <= 0:
					Global.bildirim_gonder("KOKU KESTIN! OYUN BITTI!")
					get_tree().call_deferred("change_scene_to_file", "res://Scene/kazandin_ekrani.tscn")
			else:
				saldiri_sayaci = saldiri_hizi
				Global.bildirim_gonder("Cok yorgunsun! Yeryuzune donup mantar toplamalısin.")

# true dönerse raid tetiklendi — başka event çalışmasın
func _esik_kontrol() -> bool:
	if not event_yoneticisi:
		return false
	var yuzde = float(Global.kok_guncel_can) / float(Global.kok_baslangic_cani) * 100.0

	if not esik_75_ateslendi and yuzde <= 75.0:
		esik_75_ateslendi = true
		event_yoneticisi.kok_raid_tetikle(75)
		return true
	elif not esik_50_ateslendi and yuzde <= 50.0:
		esik_50_ateslendi = true
		event_yoneticisi.kok_raid_tetikle(50)
		return true
	elif not esik_25_ateslendi and yuzde <= 25.0:
		esik_25_ateslendi = true
		event_yoneticisi.kok_raid_tetikle(25)
		return true
	return false

func _relic_drop_kontrol():
	if relic_havuzu.is_empty():
		return
	if randf() > relic_drop_sansi:
		return
	var secilen_sahne = relic_havuzu[randi() % relic_havuzu.size()]
	bekleyen_relic = secilen_sahne.instantiate()
	relic_secim_acik = true
	Global.event_aktif = true
	Global.bildirim_gonder("✧ Relic dustu: " + bekleyen_relic.relic_isim + "!")
	Global.esya_goruldu(bekleyen_relic.relic_isim, bekleyen_relic.relic_aciklama, false)
	Global.bildirim_gonder("  " + bekleyen_relic.relic_aciklama)
	Global.bildirim_gonder("  [F: Al] [ESC: Reddet/Scrap]")

func _relici_al():
	if not bekleyen_relic:
		return
	Global.add_child(bekleyen_relic)
	Global.aktif_relicler.append(bekleyen_relic)
	Global.esya_goruldu(bekleyen_relic.relic_isim, bekleyen_relic.relic_aciklama, true)
	Global.bildirim_gonder("✧ " + bekleyen_relic.relic_isim + " alindi!")
	bekleyen_relic = null
	relic_secim_acik = false
	Global.event_aktif = false

func _relici_reddet():
	if not bekleyen_relic:
		return
	Global.bildirim_gonder("✧ " + bekleyen_relic.relic_isim + " reddedildi.")
	bekleyen_relic.scrap_et()
	bekleyen_relic.queue_free()
	bekleyen_relic = null
	relic_secim_acik = false
	Global.event_aktif = false

func _on_etkilesim_alani_body_entered(body):
	if body.name == "Karakoncolos":
		oyuncu_yakinda = true
		if prompt_yazisi:
			prompt_yazisi.text = "F: Basili Tut"
			prompt_yazisi.show()

func _on_etkilesim_alani_body_exited(body):
	if body.name == "Karakoncolos":
		oyuncu_yakinda = false
		if prompt_yazisi:
			prompt_yazisi.hide()
