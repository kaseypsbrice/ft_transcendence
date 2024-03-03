function onLogin()
{
	window.location.hash = "#home";
}

function submitForm(event)
{
	event.preventDefault();

	var username = document.getElementById("username").value;
	var password = document.getElementById("password").value;
	if (password != document.getElementById("password_confirm").value)
		return;
	var display_name = document.getElementById("display_name").value;

	console.log("Username: ", username);
	console.log("Password: ", password);
	console.log("Display Name: ", display_name);
	ws.send(JSON.stringify({"type": "register", "data": {"username": username, "password": password, "display_name": display_name}}));
}