extends Area2D

func _on_body_entered(body):
	if body.name == "Karakoncolos":
		Global.envanter["odun"] += 1
		# YENİSİ:
		Global.bildirim_gonder("Odun toplandı! Toplam: " + str(Global.envanter["odun"]))
		queue_free()
