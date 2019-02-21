extends Control

signal received_data(json_data)

export (String) var BaseFirebaseURL
export (float) var UpdateGranularity


func _on_Button_pressed():
    var data = $VBoxContainer/TextEdit.text
    while true:
        if $HTTPRequest.get_http_client_status() != HTTPClient.STATUS_REQUESTING:
            $HTTPRequest.request("https://asterizzle.firebaseio.com/testlist.json?auth=gXgxH4xdRW7n3eoCMcU4tt8gIxNpqjBwm3pH4JJt", ["accept: text/event-stream"], true, HTTPClient.METHOD_POST, "{" + data + "}")
        yield(get_tree().create_timer(UpdateGranularity), "timeout")

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
    var bod = body.get_string_from_ascii()
    var data_idx = bod.find("data:")
    bod = bod.right(data_idx + "data:".length())
    var json_result = JSON.parse(bod)
    var res = json_result.result
    emit_signal("received_data", res.data)