class_name TuningExport
extends RefCounted
## Gets exported tuning text out of the game so the player can pass it on.
## In the web build, the hosting page can offer a native dialog (copy, send to Claude) by defining
## window.totoShowExport(text); everywhere else the text goes to the clipboard.

enum Result { OPENED_PAGE_DIALOG, COPIED_TO_CLIPBOARD }

const _PAGE_HOOK := "window.totoShowExport"


static func share(text: String) -> Result:
	if _page_has_hook():
		JavaScriptBridge.eval("%s(%s)" % [_PAGE_HOOK, JSON.stringify(text)], true)
		return Result.OPENED_PAGE_DIALOG
	DisplayServer.clipboard_set(text)
	return Result.COPIED_TO_CLIPBOARD


## Asks for the hook's type as a string: JavaScript booleans come back from eval() as integers.
static func _page_has_hook() -> bool:
	return OS.has_feature("web") and JavaScriptBridge.eval("typeof %s" % _PAGE_HOOK, true) == "function"
