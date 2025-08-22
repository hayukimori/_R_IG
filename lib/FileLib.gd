class_name FileLib

static func read_file_as_string(path: String) -> String:
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return ""
    var content = file.get_as_text()
    file.close()
    return content

static func file_exists(path: String) -> bool:
    return FileAccess.file_exists(path)