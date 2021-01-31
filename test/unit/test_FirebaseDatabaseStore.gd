extends "res://addons/gut/test.gd"

const FirebaseDatabaseStore = preload("res://addons/godot-firebase/database/database_store.gd")
const TestKey = "-MPrgu_F8OXiL-VpRxjq"
const TestObject = {
	"I": "Some Value",
	"II": "Some Other Value",
	"III": [111, 222, 333, 444, 555],
	"IV": {
		"a": "Another Value",
		"b": "Yet Another Value"
	}
}
const TestObjectOther = {
	"a": "A Different Value",
	"b": "Another One",
	"c": "A New Value"
}
const TestArray = [666, 777, 888, 999]
const TestValue = 12345.6789

class TestPutOperations:
	extends "res://addons/gut/test.gd"
	
	func test_put_object():
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey, TestObject)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]
		
		assert_eq_deep(store_object, TestObject)
		
		store.queue_free()
	
	func test_put_nested_object():
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey, TestObject)
		store.put(TestKey + "/V", TestObjectOther)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]["V"]
		
		assert_eq_deep(store_object, TestObjectOther)
		
		store.queue_free()
	
	func test_put_array_value():
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey, TestObject)
		store.put(TestKey + "/III", TestArray)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]["III"]
		
		assert_eq_deep(store_object, TestArray)
		
		store.queue_free()
	
	func test_put_normal_value():
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey, TestObject)
		store.put(TestKey + "/II", TestValue)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]["II"]
		
		assert_eq_deep(store_object, TestValue)
		
		store.queue_free()
	
	func test_put_deleted_value():
		# NOTE: Firebase Realtime Database sets values to null to indicate that they have been
		#  deleted.
		
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey, TestObject)
		store.put(TestKey + "/II", null)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]
		
		assert_false(store_object.has("II"), "The value should have been deleted, but was not.")
		
		store.queue_free()
	
	func test_put_new_object():
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey, TestObject)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]
		
		assert_eq_deep(store_object, TestObject)
		
		store.queue_free()
	
	func test_put_new_nested_object():
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey + "/V", TestObjectOther)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]["V"]
		
		assert_eq_deep(store_object, TestObjectOther)
		
		store.queue_free()
	
	func test_put_new_array_value():
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey + "/III", TestArray)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]["III"]
		
		assert_eq_deep(store_object, TestArray)
		
		store.queue_free()
	
	func test_put_new_normal_value():
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey + "/II", TestValue)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]["II"]
		
		assert_eq_deep(store_object, TestValue)
		
		store.queue_free()

class TestPatchOperations:
	extends "res://addons/gut/test.gd"
	
	func test_patch_object():
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.patch(TestKey, TestObject)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]
		
		assert_eq_deep(store_object, TestObject)
		
		store.queue_free()
	
	func test_patch_nested_object():
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey, TestObject)
		store.patch(TestKey + "/V", TestObjectOther)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]["V"]
		
		assert_eq_deep(store_object, TestObjectOther)
		
		store.queue_free()
	
	func test_patch_array_value():
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey, TestObject)
		store.patch(TestKey + "/III", TestArray)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]["III"]
		
		assert_eq_deep(store_object, TestArray)
		
		store.queue_free()
	
	func test_patch_normal_value():
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey, TestObject)
		store.patch(TestKey + "/II", TestValue)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]["II"]
		
		assert_eq_deep(store_object, TestValue)
		
		store.queue_free()
	
	func test_patch_deleted_value():
		# NOTE: Firebase Realtime Database sets values to null to indicate that they have been
		#  deleted.
		
		var store = TestUtils.instantiate(FirebaseDatabaseStore)
		
		store.put(TestKey, TestObject)
		store.patch(TestKey + "/II", null)
		
		var store_data: Dictionary = store.get_data()
		var store_object = store_data[TestKey]
		
		assert_false(store_object.has("II"), "The value should have been deleted, but was not.")
		
		store.queue_free()
