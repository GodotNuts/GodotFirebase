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
    match 1:
        0:
            task = test.get("some_document")
        1:
            task = test.update("some_document", {
                number = 1,
                text = "a string",
                array = [1, 2, "pop", "goes"],
                nest = {
                    a = "b",
                    c = "d"
                }
            })
        2:
            task = test.delete("some_document")
    
    var document = yield(task, "task_finished")
    
    Firebase.Firestore.enable_networking()
    
    task = test.get("some_document")
    document = yield(task, "task_finished")
    
