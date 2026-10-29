extends Area2D

func _on_body_entered(body):
	if body.name == "Karakoncolos":
		Global.envanter["tas"] += 1
		Global.bildirim_gonder("Taş toplandı! Toplam: " + str(Global.envanter["tas"]))
		queue_free()
