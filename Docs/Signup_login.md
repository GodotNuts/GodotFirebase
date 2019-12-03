# Signup and Login

**Please note before you can use the login methods, you need to enable the Email/Password Signin Method**

![email signin method](/Docs/Images/email_signin_method.png)

---
## Signup with Email
From inside of Godot after you have set your configurations in the **Firebase.gd** script, you are able to call
```
Firebase.Auth.signup_with_email(email, password)
```

This will create the login_request_body variable and insert the correct data into it.

```python
var login_request_body = {
    "email":"",
    "password":"",
    "returnSecureToken": true
   }
```

From there the script will POST the data to the `signup_request_url` and add the user to the application

---
## Login with Email
From inside of Godot after you have set your configurations in the **Firebase.gd** script, you are able to call
```
Firebase.Auth.login_with_email(email, password)
```

This will create the login_request_body variable and insert the correct data into it.

```python
var login_request_body = {
    "email":"",
    "password":"",
    "returnSecureToken": true
   }
```

From there the script will POST the data to the `signin_request_url`, and wait for a response. The function `func _on_FirebaseAuth_request_completed(result, response_code, headers, body)` will take that response and parse it out for you.

#### Unable to parse body
If the script is unable to parse the body, it will print our an error to the console and 'return' out of the function


#### Body has RESPONSE_SIGNIN, RESPONSE_SIGNUP
If the response body has `RESPONSE_SIGNIN, RESPONSE_SIGNUP`, the user will be logged in and the refresh countdown will start
This refresh is needed for Firebase, as there is a limit to how long a connection can be left open, and you need the connection to stay open for updates

#### Body has RESPONSE_USERDATA
If the response body has `RESPONSE_USERDATA`, the script will emit a signal "userdata_received" with the userdata

#### Body has INVALID_EMAIL, EMAIL_NOT_FOUND, INVALID_PASSWORD, USER_DISABLED or WEAK_PASSWORD
If the response body has `INVALID_EMAIL, EMAIL_NOT_FOUND, INVALID_PASSWORD, USER_DISABLED or WEAK_PASSWORD`, the login has failed and the script will emit a signal "login_failed". It will also pass the error code and error message to be printed into the console

---
## Successful Login
If the login was successful, a signal (login_succeeded) from **FirebaseAuth.gd** will emit with the auth data. You can see in the example below we connect to this signal and tie it to a function called "_on_FirebaseAuth_login_succeeded" that looks for the auth data to be sent to it. You can then print this data out if you want with a simple print command
```python
print(auth)
```

You can also use this data to only show the items you care about, such as the email address of the person who just signed in

```python
print(auth.email)
```

auth contains the following information
* displayname
* email
* expiresin
* idtoken
* kind
* localid
* refreshtoken
* registered

---
## Stored Login Information
Upon a successful login, the auth information will be written to a local encrypted file from **FirebaseAuth.gd** using the function **save_auth_local(auth_info)**. This is called for you and should not be run by your application outside of its loop.

#### Upgrading from Godot 3.1.x to Godot 3.2.x+
If you originally used this code in Godot 3.1.x on Android and moved to Godot 3.2.x and above, you will need to implement some extra code when trying to load the data, as Godot changed how **OS.get_unique_id()** works.

---
## Auto Login
Once a user registers and logs into the app for the first time, they will auto login in the future. This is handled by the function **load_auth_local()** from **FirebaseAuth.gd**. 

# Examples

![signup login page](/Docs/Images/signup_login_page.png)
```python
extends Node2D

var EmailTextbox
var PasswordTextbox

func _ready():
	Firebase.Auth.connect("login_succeeded", self, "_on_FirebaseAuth_login_succeeded")
	Firebase.Auth.connect("login_failed", self, "on_login_failed")

	EmailTextbox = get_node("EmailTextbox")
	PasswordTextbox = get_node("PasswordTextbox")

func _on_login_pressed():
	Firebase.Auth.login_with_email_and_password(EmailTextbox.text, PasswordTextbox.text)

func _on_register_pressed():
	Firebase.Auth.signup_with_email_and_password(EmailTextbox.text, PasswordTextbox.text)

func _on_FirebaseAuth_login_succeeded(auth):
	var user = Firebase.Auth.get_user_data()
	print(user)
    
func on_login_failed(error_code, message):
	print("error code: " + str(error_code))
	print("message: " + str(message))
```