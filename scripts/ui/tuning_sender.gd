class_name TuningSender
extends RefCounted
## Sends exported tuning to Claude through the page hosting the web build.
## The page defines window.totoSendTuning(text) and shows the result; anywhere else, sending is unavailable.

const _PAGE_HOOK := "window.totoSendTuning"


## Asks for the hook's type as a string: JavaScript booleans come back from eval() as integers.
static func is_available() -> bool:
	return OS.has_feature("web") and JavaScriptBridge.eval("typeof %s" % _PAGE_HOOK, true) == "function"


static func send(text: String) -> void:
	JavaScriptBridge.eval("%s(%s)" % [_PAGE_HOOK, JSON.stringify(text)], true)
