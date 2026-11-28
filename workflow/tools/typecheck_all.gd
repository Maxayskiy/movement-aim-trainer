# Compiles every script in one Godot process. Used by check.ps1's typecheck step.
# Run: godot --headless --path <root> -s <abs path of this file> -- <list file>
# The list file holds one res:// path per line. Prints "TYPECHECK BAD <path>" per
# script that fails to compile, then "TYPECHECK DONE checked=<n> bad=<m>".
# Exits 1 if any script failed, else 0. Godot prints each compile error to stderr.
extends SceneTree


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("typecheck_all.gd: expected one argument after --: the list file")
		quit(1)
		return
	var text: String = FileAccess.get_file_as_string(args[0])
	if text.is_empty():
		printerr("typecheck_all.gd: list file missing or empty: %s" % args[0])
		quit(1)
		return
	var checked: int = 0
	var bad: int = 0
	for line: String in text.split("\n", false):
		var path: String = line.strip_edges()
		if path.is_empty():
			continue
		checked += 1
		if not _compiles(path):
			bad += 1
			print("TYPECHECK BAD %s" % path)
	print("TYPECHECK DONE checked=%d bad=%d" % [checked, bad])
	quit(1 if bad > 0 else 0)


func _compiles(path: String) -> bool:
	var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var script: GDScript = res as GDScript
	return script != null and script.can_instantiate()
