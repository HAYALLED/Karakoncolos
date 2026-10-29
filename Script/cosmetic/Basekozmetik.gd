extends Node2D

# ==========================================
# BASE KOZMETİK — C+D ile yeni kozmetik yap
# Sadece görsel, stat etkisi yok.
# _ready()'de Global.kozmetikler[slot]'a
# kendini otomatik kaydeder.
# ==========================================

@export_group("Kimlik")
@export var kozmetik_isim: String = "Kozmetik"
@export_enum("sapka", "govde", "pantalon", "ayakkabi") var slot: String = "sapka"

@export_group("Görsel")
@export var on_texture: Texture2D

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready():
	if sprite and on_texture:
		sprite.texture = on_texture
	# DUZELTME: @export_enum bazen int doner — str() ile garanti et
	var slot_str = str(slot)
	Global.kozmetikler[slot_str] = self
	print("DEBUG Kozmetik: slot=%s tip=%s texture=%s" % [slot_str, typeof(slot), on_texture])
