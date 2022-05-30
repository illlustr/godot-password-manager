extends Control

enum { NO_ACTION, NEW, OPEN, SAVE, SAVE_AS, SAVE_INC, QUIT, ABOUT, LICENCES, PWD_GEN, CHG_PW, SETTINGS }
enum { UNLOCKED, LOCKED }
enum { SET_PASSWORD, ENTER_PASSWORD, ACCESS_DATA }

var settings: Settings
var passwords: Passwords
var database: Database

var file_menu
var tools_menu
var help_menu
var menu_action = NO_ACTION
var state = ""
var password = ""

func _ready():
	settings = Settings.new()
	settings = settings.load_data()
	load_passwords()
	database = Database.new()
	configure_menu()
	for child in $Content.get_children():
		var _e = child.connect("action", self, "state_handler")


func state_handler(action, data):
	match state:
		SET_PASSWORD:
			match action:
				"enter_pressed":
					password = data.sha256_text()
					state = ACCESS_DATA
					show_content("DataForm")
				"password_text_changed":
					# Evaluate the password strength
					pass
		ENTER_PASSWORD:
			match action:
				"enter_pressed":
					# Try to open the database
					# If error, display alert
					state = ACCESS_DATA
					show_content("DataForm")
				"browse_pressed":
					menu_action = OPEN
					do_action()
		ACCESS_DATA:
			pass


func set_title(locked):
	var title = ProjectSettings.get_setting("application/config/name")
	title += " - " + settings.current_file
	if locked:
		title += " [LOCKED]"
	if OS.is_debug_build():
		title += " (DEBUG)"
	OS.set_window_title(title)


func load_passwords():
	passwords = Passwords.new()
	var pwd = passwords.load_data(settings)
	if pwd == null:
		passwords.set_iv()
		show_content("SetPasswordForm")
		state = SET_PASSWORD
	else:
		if pwd is Passwords:
			passwords = pwd
			set_title(LOCKED)
			$Content/PasswordForm.set_text(settings.current_file)
			show_content("PasswordForm")
			state = ENTER_PASSWORD
		else:
			$Alert.show_message("Error opening password data file")


func show_content(target_name):
	for child in $Content.get_children():
		if child.name == target_name:
			child.show()
		else:
			child.hide()


func configure_menu():
	file_menu = $M/Menu/File.get_popup()
	file_menu.add_item("New", NEW, KEY_MASK_CTRL | KEY_N)
	file_menu.add_item("Open", OPEN, KEY_MASK_CTRL | KEY_O)
	file_menu.add_separator()
	file_menu.add_item("Save", SAVE, KEY_MASK_CTRL | KEY_S)
	file_menu.add_item("Save As...", SAVE_AS, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_S)
	file_menu.add_item("Save Increment", SAVE_INC, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_I)
	file_menu.add_separator()
	file_menu.add_item("Quit", QUIT, KEY_MASK_CTRL | KEY_Q)
	file_menu.connect("id_pressed", self, "_on_FileMenu_id_pressed")
	
	tools_menu = $M/Menu/Tools.get_popup()
	tools_menu.add_item("Password Generator")
	tools_menu.add_item("Change Password")
	tools_menu.add_item("Settings")
	tools_menu.connect("id_pressed", self, "_on_ToolsMenu_id_pressed")
	
	help_menu = $M/Menu/Help.get_popup()
	help_menu.add_item("About", ABOUT)
	help_menu.add_separator()
	help_menu.add_item("Licences", LICENCES)
	help_menu.connect("id_pressed", self, "_on_HelpMenu_id_pressed")


func _on_FileMenu_id_pressed(id):
	menu_action = id
	match id:
		NEW:
			passwords.save_data(settings)
			settings.current_file = ""
			load_passwords()
		OPEN:
			do_action()
		SAVE:
			do_action()
		SAVE_AS:
			menu_action = SAVE
			settings.current_file = ""
			do_action()
		QUIT:
			get_tree().quit()


func _on_ToolsMenu_id_pressed(id):
	match id:
		PWD_GEN:
			pass
		CHG_PW:
			pass
		SETTINGS:
			pass


func _on_HelpMenu_id_pressed(id):
	match id:
		ABOUT:
			$c/About.popup_centered()
		LICENCES:
			$c/Licences.popup_centered()


func do_action():
	match menu_action:
		OPEN:
			$c/FileDialog.current_dir = settings.last_dir
			$c/FileDialog.current_file = settings.current_file
			$c/FileDialog.mode = FileDialog.MODE_OPEN_FILE
			$c/FileDialog.popup_centered()
		SAVE:
			if settings.current_file == "":
				$c/FileDialog.current_dir = settings.last_dir
				$c/FileDialog.current_file = ""
				$c/FileDialog.mode = FileDialog.MODE_SAVE_FILE
				$c/FileDialog.popup_centered()
			else:
				save_data()


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			get_tree().quit()


# Handle shutdown of App
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_data()


func save_data():
	settings.save_data()
	passwords.save_data(settings)


func _on_File_pressed():
	file_menu.show()


func _on_Tools_pressed():
	tools_menu.show()


func _on_Help_pressed():
	help_menu.show()


func _on_FileDialog_file_selected(path):
	if path.rstrip("/") == path.get_base_dir():
		$Alert.show_message("No filename was specified")
		return
	settings.current_file = path.get_file()
	settings.last_dir = path.get_base_dir()
	if menu_action == SAVE:
		passwords.save_data(settings)
	else:
		load_passwords()
