extends VBoxContainer

signal action(id, data)

enum { ENTER_PRESSED, PASSWORD_TEXT_CHANGED, BROWSE_PRESSED }

func _ready():
	set_text("")


func init(txt):
	set_text(txt)
	visible = true


func set_text(txt):
	$Label.text = txt

func _on_Enter_pressed():
	emit_signal("action", ENTER_PRESSED, $HBox/Password.text)


func _on_Hidden_pressed():
	$HBox/Hidden.hide()
	$HBox/Visible.show()
	$HBox/Password.secret = false


func _on_Visible_pressed():
	$HBox/Hidden.show()
	$HBox/Visible.hide()
	$HBox/Password.secret = true


func _on_Password_text_changed(new_text):
	emit_signal("action", PASSWORD_TEXT_CHANGED, new_text)


func _on_Browse_pressed():
	emit_signal("action", BROWSE_PRESSED, null)