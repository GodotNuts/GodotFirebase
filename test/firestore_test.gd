extends Node2D

export var email := ""
export var password := ""

func _ready() -> void:
    Firebase.Auth.login_with_email_and_password(email, password)
    yield(Firebase.Auth, "login_succeeded")
    print("Logged in!")
    
    var task: FirestoreTask
    
    Firebase.Firestore.disable_networking()
    
    task = Firebase.Firestore.list("test_collection", 5, "", "number")
    print(yield(task, "listed_documents"))
    
    var test : FirestoreCollection = Firebase.Firestore.collection("test_collection")
    
    for i in 5:
        var name = "some_document_%d" % hash(str(i))
        task = test.delete(name)
        task = test.update(name, {"number": i + 10})
    
    var document = yield(task, "task_finished")
    
    Firebase.Firestore.enable_networking()
    
    task = test.get("some_document_%d" % hash(str(4)))
    document = yield(task, "task_finished")
    print(document)
