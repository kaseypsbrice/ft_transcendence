function onLogin()
{
	window.location.hash = "#home";
}

function registerDisplayError(msg)
{
	console.log(msg);
}

window.onMessage = function(event, msg)
{
	switch(msg.type)
	{
		case "RegisterError":
			if (msg.message != null)
				registerDisplayError(msg.message);
			break;
	}
}

function submitForm(event)
{
	event.preventDefault();

	var username = document.getElementById("username").value;
	var password = document.getElementById("password").value;
	if (password != document.getElementById("password_confirm").value)
		return;
	var display_name = document.getElementById("display_name").value;

	if (!ws || ws.readyState != ws.OPEN)
	{
		registerDisplayError("Could not connect to server")
		return;
	}
	ws.send(JSON.stringify({"type": "register", "data": {"username": username, "password": password, "display_name": display_name}}));
}