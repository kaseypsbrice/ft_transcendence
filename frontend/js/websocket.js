const ws = new WebSocket('wss://127.0.0.1:8080');

let logged_in = true;

// Overload these in future scripts
function onOpen(ws, event) {}
function onClose(ws, event) {}
function onMessage(ws, event, msg) {}
function onLogout() {}
function onLogin() {}

ws.onopen = function(event) {
	console.log("Connected to websocket server");
	onOpen(ws, event);
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
				document.cookie = 'access_token=${msg.token};SameSite=Strict;Secure;';
				logged_in = true;
				onLogin();
			}
			if (msg.type === 'InvalidToken')
			{
				logged_in = false;
				onLogout();
			}
		}
		onMessage(ws, event, msg);
    } catch (e) {
        console.error('Error parsing message:', e);
    }
};

ws.onclose = function(event) {
	console.log('websocket connection closed', event.code, event.reason);
	onClose(ws, event);
};

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