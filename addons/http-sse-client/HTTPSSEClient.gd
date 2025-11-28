@tool
extends Node

signal new_sse_event(headers, event, data)
signal connected
signal connection_error(error)

const event_tag = "event:"
const data_tag = "data:"
const continue_internal = "continue_internal"

var httpclient = HTTPClient.new()
var is_connected = false

var domain
var url_after_domain
var port
var trusted_chain
var common_name_override
var told_to_connect = false
var connection_in_progress = false
var is_requested = false
var response_body = PackedByteArray()

func connect_to_host(domain : String, url_after_domain : String, port : int = -1, trusted_chain : X509Certificate = null, common_name_override : String = ""):
	process_mode = Node.PROCESS_MODE_INHERIT
	self.domain = domain
	self.url_after_domain = url_after_domain
	self.port = port
	self.trusted_chain = trusted_chain
	self.common_name_override = common_name_override
	told_to_connect = true

func attempt_to_connect():
	var tls_options = TLSOptions.client(trusted_chain, common_name_override)
	var err = httpclient.connect_to_host(domain, port, tls_options)
	if err == OK:
		connected.emit()
		is_connected = true
	else:
		connection_error.emit(str(err))

func attempt_to_request(httpclient_status):
	if httpclient_status == HTTPClient.STATUS_CONNECTING or httpclient_status == HTTPClient.STATUS_RESOLVING:
		return

	if httpclient_status == HTTPClient.STATUS_CONNECTED:
		var err = httpclient.request(HTTPClient.METHOD_POST, url_after_domain, ["Accept: text/event-stream"])
		if err == OK:
			is_requested = true

func _process(delta):
	if !told_to_connect:
		return

	if !is_connected:
		if !connection_in_progress:
			attempt_to_connect()
			connection_in_progress = true
		return

	httpclient.poll()
	var httpclient_status = httpclient.get_status()
	if !is_requested:
		attempt_to_request(httpclient_status)
		return

	if httpclient.has_response() or httpclient_status == HTTPClient.STATUS_BODY:
		var headers = httpclient.get_response_headers_as_dictionary()

		if httpclient_status == HTTPClient.STATUS_BODY:
			httpclient.poll()
			var chunk = httpclient.read_response_body_chunk()
			if(chunk.size() == 0):
				return
			else:
				response_body = response_body + chunk

			_parse_response_body(headers)

		elif Firebase.emulating and Firebase._config.workarounds.database_connection_closed_issue:
			# Emulation does not send the close connection header currently, so we need to manually read the response body
			# see issue https://github.com/firebase/firebase-tools/issues/3329 in firebase-tools
			# also comment https://github.com/GodotNuts/GodotFirebase/issues/154#issuecomment-831377763 which explains the issue
			while httpclient.connection.get_available_bytes():
				var data = httpclient.connection.get_partial_data(1)
				if data[0] == OK:
					response_body.append_array(data[1])
			if response_body.size() > 0:
				_parse_response_body(headers)
	
func _parse_response_body(headers):
	var body = response_body.get_string_from_utf8()
	if body:
		var event_datas = get_event_data(body)
		var consumed_idx = 0
		
		for event_data in event_datas:
			if event_data.event == continue_internal:
				continue

			if event_data.event == "keep-alive":
				consumed_idx = event_data.end_idx
				continue
				
			var result = Utilities.get_json_data(event_data.data)
			if result != null:
				new_sse_event.emit(headers, event_data.event, result)
				consumed_idx = event_data.end_idx
			else:
				# JSON failed. 
				# If this is not the last event, it's garbage, skip it.
				# If it IS the last event, it might be partial, so we keep it.
				if event_data != event_datas.back():
					consumed_idx = event_data.end_idx
				else:
					# Last event failed parsing. Keep it in buffer.
					pass
		
		if consumed_idx > 0:
			if consumed_idx >= body.length():
				response_body.resize(0)
			else:
				var remaining = body.substr(consumed_idx)
				response_body = remaining.to_utf8_buffer()


func get_event_data(body : String) -> Array:
	var results = []
	var start_idx = 0

	if body.find(event_tag, start_idx) == -1:
		return [{"event":continue_internal}]
		
	while true:
		# Find the index of the next event tag
		var event_idx = body.find(event_tag, start_idx)
		if event_idx == -1:
			break  # No more events found

		# Find the index of the corresponding data tag
		var data_idx = body.find(data_tag, event_idx + event_tag.length())
		if data_idx == -1:
			break  # No corresponding data found

		# Extract the event
		var event_value = body.substr(event_idx + event_tag.length(), data_idx - (event_idx + event_tag.length())).strip_edges()
		if event_value == "":
			break  # No valid event value found

		# Extract the data
		var data_end = body.find(event_tag, data_idx)  # Assume data ends at the next event tag
		if data_end == -1:
			data_end = body.length()  # If no new event tag, read till the end of the body

		var data_value = body.substr(data_idx + data_tag.length(), data_end - (data_idx + data_tag.length())).strip_edges()
		if data_value == "":
			break  # No valid data found

		# Append the event and data to results
		results.append({"event": event_value, "data": data_value, "end_idx": data_end})
		# Update the start index for the next iteration
		start_idx = data_end  # Move past the current data section
	
	return results

func _exit_tree():
	if httpclient:
		httpclient.close()
