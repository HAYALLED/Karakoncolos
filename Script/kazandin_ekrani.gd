extends Control

func _on_menuye_don_butonu_pressed():
	# Oyuncuyu tekrar Ana Menüye gönderiyoruz
	get_tree().change_scene_to_file("res://Scene/ana_menu.tscn")
