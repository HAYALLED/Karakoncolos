extends Control

# Sandik.tscn yapısı:
# Control (root) ← bu script
# └── Panel
#     ├── BaslikYazisi (Label)
#     ├── Sprite2D
#     ├── AnimationPlayer
#     └── LootYazisi (Label)

@onready var animasyon = get_node_or_null("Panel/AnimationPlayer")
@onready var loot_yazisi = get_node_or_null("Panel/LootYazisi")
@onready var baslik_yazisi = get_node_or_null("Panel/BaslikYazisi")

var loot_metni: String = ""

func _ready():
	# Control root olduğu için CanvasLayer'a karşı anchor düzgün çalışır
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if loot_yazisi: loot_yazisi.hide()
	if baslik_yazisi: baslik_yazisi.text = "SANDIK BULDUN!"
	print("animasyon: ", "OK" if animasyon else "YOK — path: Panel/AnimationPlayer")
	print("loot_yazisi: ", "OK" if loot_yazisi else "YOK — path: Panel/LootYazisi")

func baslat(metin: String):
	loot_metni = metin
	_sandigi_ac()

func _sandigi_ac():
	if animasyon and animasyon.has_animation("ac"):
		animasyon.play("ac")
		await animasyon.animation_finished
		_lootu_goster()
	else:
		_lootu_goster()

func _lootu_goster():
	if loot_yazisi and loot_metni != "":
		loot_yazisi.text = loot_metni
		loot_yazisi.show()
	await get_tree().create_timer(2.5).timeout
	get_parent().queue_free()
