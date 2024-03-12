//const ws = new WebSocket('wss://127.0.0.1:9001/ws');

let logged_in = true;
let current_profile = "my profile";

// Overload these in future scripts
function onOpen() {}
function onClose() {}
function onMessage(msg) {}
function onLogout() {}
function onLogin() {}
function cleanupPage() {}
function chatOnMessage(msg) {}
function chatOnLogin() {}
function chatOnOpen() {}
function homeOnLogin() {}
function homeOnLogout() {}


function onOpenWrapper(){
	onOpen();
	chatOnOpen();
}
function onCloseWrapper(){
	onClose();
}
function onMessageWrapper(msg){
	onMessage(msg);
	chatOnMessage(msg);
}
function onLoginWrapper(){
	onLogin();
	chatOnLogin();
	homeOnLogin();
}
function onLogoutWrapper(){
	onLogout();
	homeOnLogout();
}

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
	onLogoutWrapper();
}

function sendWithToken(ws, data)
{
	if (!ws || ws.readyState != ws.OPEN)
	{
		console.log("Not connected to server, remember to handle disconnection!");
		return;
	}
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

function viewProfile(profile)
{
	current_profile = profile;
	console.log(window.location.hash)
	if (window.location.hash == "#profile")
		onOpen();
	else
		window.location.hash = "#profile";
}

function viewMyProfile()
{
	viewProfile("my profile");
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
		onOpenWrapper();
	};

	ws.onmessage = function(event) {
		try {
			console.log("message received from server:");
			if (event.data == null || typeof(event.data) != "string")
				return
			const msg = JSON.parse(event.data);
			console.log(msg);	
			if (msg.type != null)
			{
				console.log(msg.type);
				if (msg.type === 'authentication' && msg.token != null)
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
					document.cookie = `access_token=${msg.token};SameSite=Strict;Secure;`;
					if (!logged_in || msg.token != token)
					{
						logged_in = true;
						onLoginWrapper();
					}
				}
				if (msg.type === 'InvalidToken')
				{
					logged_in = false;
					onLogoutWrapper();
				}
				if (msg.type == "ViewProfile" && msg.name != null)
				{
					viewProfile(msg.name);
				}
			}
			onMessageWrapper(msg);
		} catch (e) {
			console.error('Error parsing message:', e);
		}
	};

	ws.onclose = function(event) {
		console.log('websocket connection closed', event.code, event.reason);
		onCloseWrapper();
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