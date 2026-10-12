class_name ItemData
extends RefCounted
## A catchable thing: a fish or a piece of junk. Built by Catalog from config/fish.csv and junk.csv.

var id := ""
var rarity := ""
var cell := Vector2i.ZERO   # icon position in the sprite sheet
var weight := 0.0           # spawn weight among fish (junk ignores it)
var value := 0              # base coins
var is_junk := false


func display_name() -> String:
	return tr("item.%s" % id)


func rarity_name() -> String:
	return tr("rarity.%s" % rarity)
