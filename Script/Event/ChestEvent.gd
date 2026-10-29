extends Node

var event_isim: String = "sandik"
var tetikleme_zamani: int = 0

@export_group("Sahne")
@export var sandik_sahnesi: PackedScene

@export_group("Sandık İçeriği - Odun")
@export var odun_sansi: float = 0.6
@export var min_odun: int = 1
@export var max_odun: int = 4

@export_group("Sandık İçeriği - Taş")
@export var tas_sansi: float = 0.6
@export var min_tas: int = 1
@export var max_tas: int = 3

@export_group("Sandık İçeriği - Mantar")
@export var mantar_sansi: float = 0.4
@export var min_mantar: int = 1
@export var max_mantar: int = 5

func calistir():
	Global.bildirim_gonder("İnişte eski bir sandık buldun!")

	var loot_metni: String = ""
	var hic_bir_sey_yok: bool = true

	if randf() <= odun_sansi:
		var miktar = randi_range(min_odun, max_odun)
		Global.envanter["odun"] += miktar
		loot_metni += "+ " + str(miktar) + " Odun\n"
		hic_bir_sey_yok = false

	if randf() <= tas_sansi:
		var miktar = randi_range(min_tas, max_tas)
		Global.envanter["tas"] += miktar
		loot_metni += "+ " + str(miktar) + " Taş\n"
		hic_bir_sey_yok = false

	if randf() <= mantar_sansi:
		var miktar = randi_range(min_mantar, max_mantar)
		Global.envanter["mantar"] += miktar
		loot_metni += "+ " + str(miktar) + " Mantar\n"
		hic_bir_sey_yok = false

	if hic_bir_sey_yok:
		loot_metni = "Sandık boştu. Tüh."

	Global.bildirim_gonder(loot_metni)

	if not sandik_sahnesi:
		print("UYARI: Sandik sahnesi atanmamış!")
		return

	var katman = CanvasLayer.new()
	katman.layer = 10
	get_tree().current_scene.add_child(katman)

	var sandik = sandik_sahnesi.instantiate()
	katman.add_child(sandik)
	sandik.baslat(loot_metni)

	await katman.tree_exited
