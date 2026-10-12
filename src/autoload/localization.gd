extends Node
## Autoload "Localization": language selection on top of Godot's translation system.
## Text lives in locales/translations.csv (one column per language) which Godot imports
## as translations; code just calls tr("some.key"). Missing keys fall back to English.

signal language_changed

const FALLBACK := "en"

var available: Dictionary = {}   # locale code -> display name


func _ready() -> void:
	for code in TranslationServer.get_loaded_locales():
		var translation := TranslationServer.get_translation_object(code)
		available[code] = str(translation.get_message("meta.name")) if translation else code
	var code := PlayerState.language
	if code.is_empty():
		code = OS.get_locale_language()
	set_language(code, false)


func set_language(code: String, remember := true) -> void:
	if not available.has(code):
		code = FALLBACK
	TranslationServer.set_locale(code)
	if remember:
		PlayerState.language = code
	language_changed.emit()


func current_language() -> String:
	return TranslationServer.get_locale()
