
function loginDisplayError(msg)
{
	let errorDiv = document.getElementById('login-error')
	errorDiv.style.display = '';
	errorDiv.textContent = msg;
}

window.onLogin = function()
{
	window.location.hash = "#home";
	displayGlobalMessage("Successfully Logged In!");
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

document.getElementById('login-error').style.display = 'none';