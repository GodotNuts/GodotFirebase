extends Node2D

export var email := ""
export var password := ""

func _ready() -> void:
    Firebase.Auth.login_with_email_and_password(email, password)
    yield(Firebase.Auth, "login_succeeded")
    print("Logged in!")
    
    Firebase.Firestore.disable_networking()
    
    var test := Firebase.Firestore.collection("test_collection")
    
    var task: FirestoreTask
    for i in 5:
        var name = "some_document_%d" % hash(str(i))
        task = test.delete(name)
        task = test.update(name, {"number": null})
    
    var document = yield(task, "task_finished")
    
    Firebase.Firestore.enable_networking()
    
    task = test.get("some_document_%d" % hash(str(4)))
    document = yield(task, "task_finished")
    print(document)
