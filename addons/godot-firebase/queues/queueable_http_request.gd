class_name QueueableHTTPRequest
extends HTTPRequest

signal queue_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray)

var _queue := []

# Determine if we need to set Use Threads to true; it can cause collisions with get_http_client_status() due to a thread returning the data _after_ having checked the connection status and result in double-requests.

func _ready() -> void:
	request_completed.connect(
		func(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray):
			queue_request_completed.emit(result, response_code, headers, body)
			
			if not _queue.is_empty():
				var req = _queue.pop_front()
				self.request(req.url, req.headers, req.method, req.data)
	)
	
func request(url : String, headers : PackedStringArray = PackedStringArray(), method := HTTPClient.METHOD_GET, data : String = "") -> Error:
	var status = get_http_client_status()
	var result = OK
	
	if status != HTTPClient.STATUS_DISCONNECTED:
		_queue.push_back({url=url, headers=headers, method=method, data=data})
		return result

	result = super.request(url, headers, method, data)
	
	return result
