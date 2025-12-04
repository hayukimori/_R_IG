extends RefCounted
class_name VideoLib

const CACHE_DIR := "user://cache/videos/"

var node: Node
var http := HTTPRequest.new()

func _init(set_node: Node) -> void:

	self.node = set_node
	self.http = HTTPRequest.new()	

	if http.get_parent() == null:
		self.node.add_child(http)
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)



func get_video_or_default(url: String) -> String:

	if !node:
		push_error("Node not found")

	var filename := url.get_file()
	var local_path := CACHE_DIR + filename

	if FileAccess.file_exists(local_path):
		return local_path

	var error = http.request(url)
	if error != OK:
		push_error("Failed to make request.")
		return ""

	var result = await http.request_completed

	var result_code = result[0]
	var response_code = result[1]
	var _headers = result[2]
	var body = result[3]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		push_error("Couldn't complete request. Result: %d" % result_code)
		return ""
	

	if response_code != 200:
		push_error("Falha ao baixar vídeo: %s" % url)
		return ""

	var f := FileAccess.open(local_path, FileAccess.WRITE)
	f.store_buffer(body)
	f.close()

	return local_path
