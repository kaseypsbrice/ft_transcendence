
function loginDisplayError(msg)
{
	console.log(msg);
}

window.onLogin = function()
{
	window.location.hash = "#home";
}

window.onMessage = function(msg)
{
	switch (msg.type)
	{
		case "LoginError":
			if (msg.message != null)
				loginDisplayError(msg.message);
			break;
	}
}

function submitForm(event)
{
	event.preventDefault();

	var username = document.getElementById("username").value;
	var password = document.getElementById("password").value;

	if (!ws || ws.readyState != ws.OPEN)
	{
		loginDisplayError("Could not connect to server")
		return;
	}
	ws.send(JSON.stringify({"type": "login", "data": {"username": username, "password": password}}));
}