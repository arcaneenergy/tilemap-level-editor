extends WindowDialog

func _on_ButtonGithub_pressed() -> void:
	OS.shell_open("https://github.com/arcaneenergy/tilemap-level")

func _on_ButtonYouTube_pressed() -> void:
	OS.shell_open("https://www.youtube.com/c/ArcaneEnergy")

func _on_ButtonWebsite_pressed() -> void:
	OS.shell_open("https://arcaneenergy.github.io/")
