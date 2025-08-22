class_name Route
extends RefCounted

var endpoint: String
var method: HTTPClient.Method


func _init(route_endpoint: String, route_method: HTTPClient.Method) -> void:
    endpoint = route_endpoint
    method = route_method


func url(context: Dictionary = {}) -> String:
    var rlib := RouteLib.new()

    var result := rlib.get_route(endpoint)
    for key in context.keys():
        result = result.replace("{" + str(key) + "}", str(context[key]))
    
    return result