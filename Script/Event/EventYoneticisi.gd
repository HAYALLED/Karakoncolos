extends Node

enum Zaman {
	YER_ALTINA_INIS,
	YUZEYE_CIKIS
}

@export_group("Sandık Olayı")
@export var sandik_aktif: bool = true
@export var sandik_sansi: float = 0.35

@export_group("Düşman Olayı")
@export var dusman_aktif: bool = true
@export var dusman_sansi: float = 0.40

@export_group("Can Verme Olayı")
@export var can_verme_aktif: bool = true
@export var can_verme_sansi: float = 0.20

@export_group("Can Kaybı Olayı")
@export var can_kaybi_aktif: bool = true
@export var can_kaybi_sansi: float = 0.20

@export_group("Köy Baskını Olayı")
@export var koy_baskini_aktif: bool = true
@export var koy_baskini_sansi: float = 0.25

@export_group("Kök Raid Olayı")
@export var kok_raid_aktif: bool = true

func eventleri_tetikle(zaman: Zaman):
	var tetiklenecekler: Array = []

	for event in get_children():
		var isim = event.get("event_isim")
		var zaman_degeri = event.get("tetikleme_zamani")
		if isim == null or zaman_degeri == null:
			continue
		if not _aktif_mi(isim):
			continue
		if zaman_degeri != zaman:
			continue
		if randf() <= _sansi_al(isim):
			tetiklenecekler.append(event)

	if tetiklenecekler.is_empty():
		return

	var secilen = tetiklenecekler[randi() % tetiklenecekler.size()]
	Global.bildirim_gonder("--- OLAY ---")
	Global.event_aktif = true
	await secilen.calistir()
	Global.event_aktif = false

# kok.gd bu metodu doğrudan çağırır
func kok_raid_tetikle(esik: int):
	if not kok_raid_aktif:
		return
	var raid = get_node_or_null("KokRaidEvent")
	if not raid:
		Global.bildirim_gonder("HATA: KokRaidEvent node bulunamadi!")
		return
	Global.event_aktif = true
	await raid.tetikle(esik)
	Global.event_aktif = false

func _aktif_mi(isim: String) -> bool:
	match isim:
		"sandik":      return sandik_aktif
		"dusman":      return dusman_aktif
		"can_verme":   return can_verme_aktif
		"can_kaybi":   return can_kaybi_aktif
		"koy_baskini": return koy_baskini_aktif
	return false

func _sansi_al(isim: String) -> float:
	match isim:
		"sandik":      return sandik_sansi
		"dusman":      return dusman_sansi
		"can_verme":   return can_verme_sansi
		"can_kaybi":   return can_kaybi_sansi
		"koy_baskini": return koy_baskini_sansi
	return 0.0
