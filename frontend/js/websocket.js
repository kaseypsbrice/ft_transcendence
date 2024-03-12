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
	document.getElementById('login-button').style.display = 'none';
	document.getElementById('profile-button').style.display = '';
	document.getElementById('logout-button').style.display = '';
	document.getElementById('signup-button').style.display = 'none';
	onLogin();
	chatOnLogin();
	homeOnLogin();
}
function onLogoutWrapper(){
	document.getElementById('login-button').style.display = '';
	document.getElementById('profile-button').style.display = 'none';
	document.getElementById('logout-button').style.display = 'none';
	document.getElementById('signup-button').style.display = '';
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


function setPictureDisplayName(div, name)
{
	div.setAttribute("data-display-name", name);
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

function logout()
{
	document.cookie = `access_token=null;SameSite=Strict;Secure;`;
	sendWithToken(ws, {type: "logout"});
}

function viewMyProfile()
{
	viewProfile("my profile");
}

function displayGlobalError(msg)
{
	let newDiv = document.createElement('div');
	newDiv.classList.add('error', 'animation');
	newDiv.textContent = msg;
	document.getElementById('content').appendChild(newDiv);
}

function displayGlobalMessage(msg)
{
	let newDiv = document.createElement('div');
	newDiv.classList.add('confirmation', 'animation');
	newDiv.textContent = msg;
	document.getElementById('content').appendChild(newDiv);
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
				switch (msg.type)
				{
					case "authentication":
						if (msg.token != null)
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
						break;
					case "InvalidToken":
						logged_in = false;
						onLogoutWrapper();
						break;
					case "ViewProfile":
						if (msg.name != null)
							viewProfile(msg.name);
						break;
					case "ProfilePicture":
						if (!msg.data || !msg.data.name)
							break;
						let pictureMatches = document.querySelectorAll(`[data-display-name="${msg.data.name}"]`);
						if (msg.data.current)
						{
							let cachedProfilePicture = localStorage.getItem(msg.data.name)
							if (!cachedProfilePicture)
							{
								console.log("Error could not get cached profile picture");
								break;
							}
							let cachedJSON = JSON.parse(cachedProfilePicture);
							for (let i = 0; i < pictureMatches.length; i++)
							{
								let match = pictureMatches[i];
								match.src = cachedJSON.data;
							}
							break;
						}
						else
						{
							let cachedData = {
								data: msg.data.image,
								timestamp: msg.data.timestamp
							};
							localStorage.setItem(msg.data.name, JSON.stringify(cachedData))
							for (let i = 0; i < pictureMatches.length; i++)
							{
								let match = pictureMatches[i];
								match.src = msg.data.image;
							}
						}
						break;
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
document.getElementById('login-button').style.display = '';
document.getElementById('profile-button').style.display = 'none';
document.getElementById('logout-button').style.display = 'none';
document.getElementById('signup-button').style.display = '';
connect();