extends HSplitContainer

var user_name = ""
var text = ""

func _ready():
    $UserName.text = user_name
    $Text.text = text