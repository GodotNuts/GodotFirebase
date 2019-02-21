# GodotFirebase

Steps to use:
1) Copy the folder provided to the path res://addons/
2) Open your Project Settings
3) Go to Plugins
4) Activate the GDFirebase plugin
5) From there, you will have an autoload singleton with the variables Auth, Database, and Firestore; reference it by using Firebase.Auth, etc.
6) Go create a Firebase app at console.firebase.google.com. There are instructions there for how to do it.
7) After creating the Firebase app, within it, add a web app.
8) This will popup a series of values called "config". Take those values and copy them to the appropriate fields in the FirebaseAuth.gd, FirebaseDatabase.gd, and FirebaseFirestore.gd, found in the folder for the addons.
9) Use Firebase.Database.get_database_reference(path, filter) to add a listener at a given path in your database. It will return to you a value to which you can hook up to a few different signals, and to which you can push data. You do not have to manually add it to the scene tree, as it gets added automatically. You can listen to many places at once, as needed. You can, optionally, pass a Dictionary of tags (found in FirebaseDatabase) to values representing your filters and queries. Queries are currently cached, so they can't be dynamically updated, but I can add that if there's a desire.




Todo:
1) Implement other Firebase features: Storage, Remote Config, Dynamic Links
