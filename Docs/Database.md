# Database Commands

## get_database_reference(path, filter):

This function is used to create a reference to the database that you have in Firebase. This is best used when you store this reference into a variable to call from multiple places, or add listeners to for changes in data.

```python
# The following stores a reference to the path game/score into the variable firebase_reference
firebase_reference = Firebase.Database.get_database_reference("game/score", { })
```

If you get a error in Godot that says **Assertion Failed**, please check to make sure the rules on the Database in Firebase have been set correctly. The following is a basic set of rules which only allows logged in users to read and write data.

```
// These rules grant access to a node matching the authenticated
// user's ID from the Firebase auth token
{
  "rules": {
      ".read": "auth != null",
      ".write": "auth != null"
  }
}
```

## push(data):

This function is used to push data into a database that you have referenced. See **get_database_reference(path, filter):** one how to create a reference path.

You can add a single item:
```python
# The following will push a single peice of data into the referenced database
firebase_reference.push({"Score" : "100"})
```

Or you can add a dictionary of items:
```python
# The following will push a dictionary into the referenced database
firebase_reference.push({"mouse_position": {"x": mouse_pos.x, "y": mouse_pos.y}, "color": "red"})
```

# Database Signals

## Coming Soon

# Examples

## Pushing Data

For all examples consider the following. A single textbox with a send button.

![Push Data Example](/Docs/Images/push_data_example.png)


### Single Item

The following will take the text from the textbox, and push it into the database from the reference point we created. Once the send button is clicked, we will be able to see the data in Firebase.

![Push Data Example Value](/Docs/Images/push_data_example_value.png)

```python
func _on_send_pressed():
    var score_data = get_node("score")
	firebase_reference.push({"score" : score_data.text})
```

![Push Data Example Result](/Docs/Images/push_data_example_result.png)

### Multiple Items

The following will take the text from the textbox, as well as the current mouse position, and push it into the database from the reference point we created. Once the send button is clicked, we will be able to see the data in Firebase.

```python
func _on_send_pressed():
    var score_data = get_node("score")
    var mouse_pos = get_global_mouse_position()
	firebase_reference.push({"mouse_position": var2str(mouse_pos), "score" : score_data.text})
```

![Push Data Example Result 2](/Docs/Images/push_data_example_result_2.png)