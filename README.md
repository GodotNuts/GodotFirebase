# GodotFirebase

## Installation and Activation
1. Copy the folder **GDFirebase** to the project path res://addons/
2. Open your Project Settings
3. Go to Plugins
4. Activate the GDFirebase plugin<br>
![Plugin Section](/Images/plugins_section.png)
5. From there, you will have an autoload singleton with the variables Auth, Database, and Firestore; reference it by using Firebase.Auth, etc.

## Creating A Firebase App / Web App
1. Go create a Firebase app at console.firebase.google.com. A Guide can be found [Here](https://firebase.google.com/docs/projects/learn-more#setting_up_a_firebase_project_and_connecting_apps)
2. Once the app has been created, add a web app to it
    1. Click on the **Project Settings** option<br>
    ![FB Project Settings](/Images/fb_project_settings.png)

    2. Click on the **Add App** button<br>
    ![FB Add App](/Images/fb_add_app.png)

    3. Click the **Web App** button<br>
    ![FB Web App](/Images/fb_web_app.png)

    4. Add a name to your web app and click **Register App**<br>
    ![FB Register App](/Images/fb_register_app.png)

3. This will show a series of values called "config". Take those values and copy them to the appropriate fields in **Firebase.gd**, found in the **GDFirebase** folder
4. Use Firebase.Database.get_database_reference(path, filter) to add a listener at a given path in your database. It will return to you a value to which you can hook up to a few different signals, and to which you can push data. You do not have to manually add it to the scene tree, as it gets added automatically. You can listen to many places at once, as needed. You can, optionally, pass a Dictionary of tags (found in FirebaseDatabase) to values representing your filters and queries. Queries are currently cached, so they can't be dynamically updated, but I can add that if there's a desire.




## Todo:
1. Implement other Firebase features: Storage, Remote Config, Dynamic Links
2. Add comments to code
3. Create documentation