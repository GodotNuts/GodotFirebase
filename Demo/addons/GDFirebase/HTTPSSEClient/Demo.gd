extends Node2D

var config = {
 # Add full config data here
 "url":"" # For demo purposes, I use my Firebase database URL
}

func _ready():
    var sub_url = "" # Add the "/sub_list_url" stuff here, including query parameters as needed; for demo purposes, I use the list path in my Firebase database, combined with ".json?auth=" and whatever the auth token is.
    $HTTPSSEClient.connect("connected", self, "on_connected")
    $HTTPSSEClient.connect_to_host(config.url, sub_url, 443, true, false)

func on_connected():
    $HTTPSSEClient.connect("new_sse_event", self, "on_new_sse_event")
    
func on_new_sse_event(headers, event, data):
    print("event is: " + event)
    print("data is: " + data) 