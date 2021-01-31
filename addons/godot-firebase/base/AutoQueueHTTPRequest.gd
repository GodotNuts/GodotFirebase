class_name AutoQueueHTTPRequest
extends HTTPRequest

var _is_busy = false
var requests = []
var mutex

func _ready() -> void:
    mutex = Mutex.new()
    connect("request_completed", self, "_on_request_completed")

func set_busy(is_busy : bool = true) -> void:
    _is_busy = is_busy

func request(url : String, custom_headers : PoolStringArray = PoolStringArray(), ssl_validate_domain : bool = true, method : int = 0, request_data : String = "") -> int:
    if not _is_busy:
        set_busy()
        return .request(url, custom_headers, ssl_validate_domain, method, request_data)
    else:
        enqueue_request({"url" : url, "custom_headers": custom_headers, "ssl_validate_domain": ssl_validate_domain, "method": method, "request_data": request_data})
        return OK
        
func enqueue_request(request_obj : Dictionary) -> void:
    mutex.lock()
    requests.push_back(request_obj)
    mutex.unlock()
    
func dequeue_request() -> Dictionary:
    return requests.pop_front()
    
func _on_request_completed(result, response_code, headers, body):
    set_busy(false)
    if requests.size() > 0 and not _is_busy: # You might think this unnecessary, but due to thread timing weirdness, it may be required even with the Mutex
        mutex.lock()
        var next_request = dequeue_request()
        mutex.unlock()
        request(next_request.url, next_request.custom_headers, next_request.ssl_validate_domain, next_request.method, next_request.request_data)
