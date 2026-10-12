class_name EventData
extends RefCounted
## A random event definition. Built from config/events.json.

var id := ""
var duration := 30.0
var weight := 1.0
var color := Color.WHITE
var rain := false
var bite_time := 1.0   # multiplies the wait for a bite
var luck := 0.0        # boosts rare fish
var value := 1.0       # multiplies coin value of catches
var junk := 1.0        # multiplies junk chance


func display_text() -> String:
	return tr("event.%s" % id)


static func from_dict(event_id: String, d: Dictionary) -> EventData:
	var e := EventData.new()
	e.id = event_id
	e.duration = float(d.get("duration", 30.0))
	e.weight = float(d.get("weight", 1.0))
	e.color = Color.html(str(d.get("color", "#ffffff")))
	e.rain = bool(d.get("rain", false))
	var m: Dictionary = d.get("modifiers", {}) if d.get("modifiers") is Dictionary else {}
	e.bite_time = float(m.get("bite_time", 1.0))
	e.luck = float(m.get("luck", 0.0))
	e.value = float(m.get("value", 1.0))
	e.junk = float(m.get("junk", 1.0))
	return e
