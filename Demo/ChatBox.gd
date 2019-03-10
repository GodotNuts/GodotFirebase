extends HSplitContainer

func set_item(item):
    $UserName.text = item.user_name + ": "
    $Text.text = item.text