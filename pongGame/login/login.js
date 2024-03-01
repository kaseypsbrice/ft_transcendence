const ws = new WebSocket('wss://127.0.0.1:8080');

ws.onopen = function(event) {
	console.log("Connected to websocket server");
};

ws.onmessage = function(event) {
    try {
		console.log("message received from server:");
        const msg = JSON.parse(event.data);
        if(msg.type === 'welcome') {
            console.log(msg.message);
        }
		else if (msg.type != null)
		{
			console.log(msg.type);
			if (msg.type === 'authentication' && msg.token != null)
			{
				document.cookie = `access_token=${msg.token};SameSite=Lax;Secure;path=/`
			}
		}
    } catch (e) {
        console.error('Error parsing message:', e);
    }
};

ws.onclose = function(event) {
	console.log('websocket connection closed', event.code, event.reason);
};

function submitForm(event)
{
	event.preventDefault();

	var username = document.getElementById("username").value;
	var password = document.getElementById("password").value;

	console.log("Username: ", username);
	console.log("Password: ", password);
	ws.send(JSON.stringify({"type": "login", "data": {"username": username, "password": password}}));
}