# GodotFirebase

Steps to use:
1) Copy the two subfolders here to your Godot project under the path "res://addons/"
2) Open your Project Settings
3) Go to Plugins
4) Activate both FirebaseAuth and FirebaseDatabase plugins
5) From there, you will have two new AutoLoad singletons in your project, called FirebaseDatabase and FirebaseAuth.
6) Go create a Firebase app. You can see how to do this on the web.
7) After creating the Firebase app, within it, add a web app.
8) This will popup a series of values. Take those values and copy them to the appropriate fields in the FirebaseAuth.gd and FirebaseDatabase.gd. This will ensure that both plugins can function with your database.
9) Use FirebaseDatabase.get_database_reference(path) to add a listener at a given path in your database. It will return to you a value to which you can hook up to a few different signals, and to which you can push data. You do not have to manually add it to the scene tree, as it gets added automatically. You can listen to many places at once, as needed.
10) Finally, create a login screen and go from there. I'm working on a proper demo. Once I'm done, it will be included here.


Todo:
1) Implement other Firebase features: Storage, Firestore, Analytics, etc.
