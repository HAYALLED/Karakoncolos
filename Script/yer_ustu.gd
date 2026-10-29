extends Node2D

@onready var zaman_bari = $CanvasLayer/ProgressBar

func _ready():
	zaman_bari.max_value = Global.gece_suresi
	zaman_bari.value = Global.gece_suresi

func _on_timer_timeout():
	# Event popup açıksa timer'ı durdur — sayma ama değişiklik de yapma
	if Global.event_aktif:
		return

	zaman_bari.value -= 1

	if zaman_bari.value <= 0:
		Global.bildirim_gonder("Güneş doğdu! Karakoncolos bayıldı ve eşyalarının yarısını düşürdü!")
		Global.envanter["mantar"] = int(Global.envanter["mantar"] / 2.0)
		Global.envanter["tas"] = int(Global.envanter["tas"] / 2.0)
		Global.envanter["odun"] = int(Global.envanter["odun"] / 2.0)
		get_tree().call_deferred("change_scene_to_file", "res://Scene/yer_alti.tscn")
