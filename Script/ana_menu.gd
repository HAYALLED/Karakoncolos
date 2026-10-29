extends Control

func _on_basla_butonu_pressed():
	Global.bildirim_gonder("Oyuna başlanıyor...")
	Global.oyunu_sifirla()
	# ARTIK YERYÜZÜNE DEĞİL, DOĞRUDAN MAĞARAYA İNİYORUZ!
	get_tree().change_scene_to_file("res://Scene/yer_alti.tscn")

func _on_cikis_butonu_pressed():
	get_tree().quit()
