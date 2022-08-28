extends "res://addons/gut/test.gd"


const FirestoreDocument = preload("res://addons/godot-firebase/firestore/firestore_document.gd")

class TestDeserialization:
    extends "res://addons/gut/test.gd"


    func test_deserialize_array_of_dicts():
        var doc_infos: Dictionary = {
            "name": "projects/godot-firebase/databases/(default)/documents/rooms/EUZT",
            "fields": {
                "code": {"stringValue": "EUZT"},
                "players": {
                    "arrayValue": {
                        "values": [
                            {"mapValue": {"fields": {"name": {"stringValue": "Hello"}}}},
                            {"mapValue": {"fields": {"name": {"stringValue": "Test"}}}}
                        ]
                    }
                }
            },
            "createTime": "2021-02-16T07:24:11.106522Z",
            "updateTime": "2021-02-16T08:21:32.131028Z"
        }
        var expected_doc_fields: Dictionary = {
            "code": "EUZT", "players": [{"name": "Hello"}, {"name": "Test"}]
        }
        var firestore_document: FirestoreDocument = FirestoreDocument.new(doc_infos)

        assert_eq_deep(firestore_document.doc_fields, expected_doc_fields)


    func test_deserialize_array_of_strings():
        var doc_infos: Dictionary = {
            "name": "projects/godot-firebase/databases/(default)/documents/rooms/EUZT",
            "fields": {
                "code": {"stringValue": "EUZT"},
                "things": {"arrayValue": {"values": [{"stringValue": "first"}, {"stringValue": "second"}]}}
            },
            "createTime": "2021-02-16T07:24:11.106522Z",
            "updateTime": "2021-02-16T08:21:32.131028Z"
        }
        var expected_doc_fields: Dictionary = {"code": "EUZT", "things": ["first", "second"]}
        var firestore_document: FirestoreDocument = FirestoreDocument.new(doc_infos)

        assert_eq_deep(firestore_document.doc_fields, expected_doc_fields)
