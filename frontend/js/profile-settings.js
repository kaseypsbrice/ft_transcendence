function profileSettingsDisplayError(msg)
{
	let errorDiv = document.getElementById('profile-settings-error');
	errorDiv.style.display = '';
	errorDiv.textContent = msg;
}

window.onLogout = function()
{
	profileSettingsDisplayError("You are not logged in");
}

window.onLogin = function()
{
	document.getElementById('profile-settings-error').style.display = 'none';
	profileSettingsDisplayError("");
	sendWithToken(ws, {type:"get_profile", profile: "my profile"});
	let cachedData = localStorage.getItem("my profile");
	setPictureDisplayName(document.getElementById('profile-settings-picture'), "my profile");
	if (!cachedData)
		sendWithToken(ws, {type: "get_profile_picture", display_name: "my profile", timestamp: "0"});
	else
	{
		let cachedJSON = JSON.parse(cachedData);
		sendWithToken(ws, {type: "get_profile_picture", display_name: "my profile", timestamp: cachedJSON.timestamp});
	}
}

window.onMessage = function(msg)
{
	switch (msg.type)
	{
		case "ChangeSettingsError":
			if (msg.message != null)
				profileSettingsDisplayError(msg.message);
			break;
		case "ChangeSettingsSuccess":
			displayGlobalMessage("Settings have been updated!")
			onLogin();
			break;
		case "Profile":
			if (!msg.data || !msg.data.username || !msg.data.display_name || !msg.data.you)
			{
				console.log("Invalid profile");
				break;
			}
			document.getElementById('settings-username').placeholder = msg.data.username;
			document.getElementById('settings-display-name').placeholder = msg.data.display_name;
			break;
	}
}

function submitProfileSettings(event)
{
	event.preventDefault();
	let password = document.getElementById('settings-password').value
	let new_password = document.getElementById('settings-new-password').value
	let new_password_confirm = document.getElementById('settings-new-password-confirm').value
	let display_name = document.getElementById('settings-display-name').value
	let username = document.getElementById('settings-username').value
	var fileInput = document.getElementById('img-upload');

	let settings_send = {type: "change_settings"}
	console.log("clicked")
	if (password.size == 0)
	{
		profileSettingsDisplayError("Please enter your current password");
		return;
	}
	settings_send["password"] = password;
	if (new_password.length > 0)
	{
		if (new_password != new_password_confirm)
		{
			profileSettingsDisplayError("Passwords do not match");
			return
		}
		settings_send["new_password"] = new_password;
	}
	if (display_name.length > 0)
		settings_send["display_name"] = display_name;
	if (username.length > 0)
		settings_send["username"] = username;

	
	let file = fileInput.files[0];
	
	if (file)
	{
		if (file.size > 10 * 1024 * 1024)
		{
			profileSettingsDisplayError("File exceeds 10MB");
			return;
		}
		else
		{
			var reader = new FileReader();
			
			reader.onload = function(event) {
				var imageData = event.target.result;
				settings_send["profile_picture"] = imageData;
				if (!ws || ws.readyState != ws.OPEN)
				{
					profileSettingsDisplayError("Could not connect to server");
					return;
				}
				sendWithToken(ws, settings_send);
			};
			
			reader.readAsDataURL(file);
			return;
		}
	}

	if (!ws || ws.readyState != ws.OPEN)
	{
		profileSettingsDisplayError("Could not connect to server");
		return;
	}
	sendWithToken(ws, settings_send);
}

if (is_logged_in())
	onLogin();
else
	onLogout();


document.getElementById('profile-settings-error').style.display = 'none';