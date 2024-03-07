//const ws = new WebSocket('wss://127.0.0.1:9001/ws');

let logged_in = true;

// Overload these in future scripts
function onOpen(event) {}
function onClose(event) {}
function onMessage(event, msg) {}
function onLogout() {}
function onLogin() {}
function cleanupPage() {}

function is_logged_in()
{
	//console.log("is_logged_in ", logged_in)
	if (logged_in)
		return true;
	return false;
}

function hasAccessToken()
{
	var token = null;
	const cookies = document.cookie.split(';');
	for (let cookie of cookies) {
		const [name, value] = cookie.trim().split('=');
		if (name === 'access_token') {

			token = value;
			break;
		}
	}
	if (token == null)
	{
		return false;
	}
	return true;
}

if (!hasAccessToken())
{
	logged_in = false;
}

function sendWithToken(ws, data)
{
	var token = null;
	const cookies = document.cookie.split(';');
	for (let cookie of cookies) {
		const [name, value] = cookie.trim().split('=');
		if (name === 'access_token') {

			token = value;
			break;
		}
	}
	if (token == null)
	{
		return true;
	}
	data["token"] = token;
	ws.send(JSON.stringify(data));
	return false;
}

function connect()
{
	window.ws = new WebSocket('wss://127.0.0.1:9001/ws');
	ws.onopen = function(event) {
		console.log("Connected to websocket server");
		if (logged_in)
			sendWithToken(ws, {type:"connected"});
		else
			ws.send(JSON.stringify({type:"connected"}));
		onOpen(event);
	};

	ws.onmessage = function(event) {
		try {
			console.log("message received from server:");
			const msg = JSON.parse(event.data);
			console.log(msg);	
			if (msg.type != null)
			{
				console.log(msg.type);
				if (msg.type === 'authentication' && msg.token != null)
				{
					document.cookie = `access_token=${msg.token};SameSite=Strict;Secure;`;
					logged_in = true;
					onLogin();
				}
				if (msg.type === 'InvalidToken')
				{
					logged_in = false;
					onLogout();
				}
			}
			onMessage(event, msg);
		} catch (e) {
			console.error('Error parsing message:', e);
		}
	};

	ws.onclose = function(event) {
		console.log('websocket connection closed', event.code, event.reason);
		onClose(event);
		setTimeout(function() {
			connect();
		}, 1000);
	};

	ws.onerror = function(err)
	{
		console.log("Websocket Error: ", err.message);
		ws.close();
	};
}
connect();