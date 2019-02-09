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
9) Enter a ListName. This corresponds to the path in your database that you want to observe.
10) Finally, create a login screen. I have included an extremely rudimentary one in the form of FirebaseLoginAndDB.tscn. When added to your project, it will be a simple user interface to show you how to interact with FirebaseAuth. I've also included Game.gd, a script that demonstrates how to use FirebaseDatabase. You'll want to do something specific to your project, but this will show the basics. The FirebaseAuth scene will hide itself when login is successful.


Todo:
1) Make it so you can listen to multiple lists simultaneously from the Database singleton plugin; it is currently limited to one list only
2) Implement other Firebase features
