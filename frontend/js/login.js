function onLogin()
{
	window.location.hash = "#home";
}

function submitForm(event)
{
	event.preventDefault();

	var username = document.getElementById("username").value;
	var password = document.getElementById("password").value;

	console.log("Username: ", username);
	console.log("Password: ", password);
	ws.send(JSON.stringify({"type": "login", "data": {"username": username, "password": password}}));
}