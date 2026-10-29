extends Node2D

# ==========================================
# BASE DÜŞMAN
# Bunu C+D yaparak yeni düşman tipleri oluştur.
# Tüm değerler Inspector'dan değiştirilebilir.
# ==========================================

@export_group("Kimlik")
@export var dusman_isim: String = "Dusman"

@export_group("Gorsel")
@export var sprite_texture: Texture2D

@export_group("Savas Statlari")
@export var max_can: int = 30
@export var saldiri: int = 5
@export var enerji_cezasi: int = 15

# ==========================================
# KAZANMA ÖDÜLÜ — BaseRelic.scrap_listesi gibi
# Desteklenen kaynaklar: "odun", "tas", "mantar", "yasam_ozu"
# Örnek:
#   {"kaynak": "odun",      "min": 1, "max": 3}
#   {"kaynak": "tas",       "min": 0, "max": 2}
#   {"kaynak": "mantar",    "min": 1, "max": 1}
#   {"kaynak": "yasam_ozu", "min": 2, "max": 5}
# ==========================================
@export_group("Kazanma Odulu - Kaynaklar")
@export var odul_listesi: Array[Dictionary] = [
	{"kaynak": "odun", "min": 0, "max": 3},
	{"kaynak": "tas",  "min": 0, "max": 2}
]

# ==========================================
# KAZANMA ÖDÜLÜ — Relic drop
# Buraya PackedScene eklenirse kazanınca
# o sahne instantiate edilip aktif_relicler'e eklenir.
# Birden fazla eklenirse rastgele biri seçilir.
# ==========================================
@export_group("Kazanma Odulu - Relic Drop")
@export var odul_relic_sahneleri: Array[PackedScene] = []

@export_group("Kodeks")
@export var dusman_aciklama: String = ""
# 7. karsilasimada KarakterEkrani'nin dusman kitapliginda gorunur.
# Bos birakilirsa hicbir zaman gosterilmez.

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	if sprite and sprite_texture:
		sprite.texture = sprite_texture
