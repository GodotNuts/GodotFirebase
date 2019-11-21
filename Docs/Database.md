# Database Commands

## get_database_reference(path, filter):

This function is used to create a reference to the database that you have in Firebase. This is best used when you store this reference into a variable to call from multiple places, or add listeners to for changes in data.

```python
# The following stores a reference to the path game/score into the variable firebase_reference
firebase_reference = Firebase.Database.get_database_reference("game/score", { })
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

## full_data_update

## new_data_update