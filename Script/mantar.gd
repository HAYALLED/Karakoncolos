extends Area2D

func _on_body_entered(body):
	if body.name == "Karakoncolos":
		Global.envanter["mantar"] += 1
		# ESKİSİ: print("Mantar toplandı! Envanter: ", Global.envanter["mantar"])
		# YENİSİ:
		Global.bildirim_gonder("Mantar toplandı! Toplam: " + str(Global.envanter["mantar"]))
		queue_free()
