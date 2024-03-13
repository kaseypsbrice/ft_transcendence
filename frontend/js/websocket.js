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


let dbInit = window.indexedDB.open('transcendence_db', 1);

// Handle upgrade event to create or modify object stores and indexes
dbInit.onupgradeneeded = function(event) {
	let db = event.target.result;

	// Create or modify object stores and indexes
	if (!db.objectStoreNames.contains('profiles')) {
		let objectStore = db.createObjectStore('profiles', { keyPath: 'profileName' });
		objectStore.createIndex('profileData', 'profileData', { unique: false });
    }
};

dbInit.onsuccess = function(event) {
	console.log("IndexedDB opened successfully");
};

dbInit.onerror = function(event) {
	console.error("Error opening IndexedDB:", event.target.error);
};

let dbPromise = window.indexedDB.open('profile_data', 1);

dbPromise.onupgradeneeded = function(event) {
	let db = event.target.result;
	let objectStore = db.createObjectStore('profiles', { keyPath: 'profileName' });
	objectStore.createIndex('profileData', 'profileData', { unique: false });
};

dbPromise.onerror = function(event) {
	console.error("Error opening IndexedDB database:", event.target.error);
	dbPromise = window.indexedDB.open('profile_data', 1);
};

function saveProfileData(profileName, profileData) {
	return new Promise(function(resolve, reject) {
		let dbPromise = window.indexedDB.open('transcendence_db', 1);

		dbPromise.onsuccess = function(event) {
			let db = event.target.result;
			let transaction = db.transaction(['profiles'], 'readwrite');
			let objectStore = transaction.objectStore('profiles');
			let request = objectStore.put({ profileName: profileName, profileData: profileData });

			request.onsuccess = function(event) {
				resolve();
				db.close(); // Close the database connection after the operation
			};

			request.onerror = function(event) {
				reject("Error saving profile data to IndexedDB");
				db.close(); // Close the database connection after the operation
			};
		};

		dbPromise.onerror = function(event) {
			reject("Error opening IndexedDB:", event.target.error);
		};
	});
}

function getProfileData(profileName) {
	return new Promise(function(resolve, reject) {
		// Wrap the dbPromise call inside a new Promise
		let dbPromise = window.indexedDB.open('transcendence_db', 1);

		dbPromise.onsuccess = function(event) {
			let db = event.target.result;
			let transaction = db.transaction(['profiles'], 'readonly');
			let objectStore = transaction.objectStore('profiles');
			let request = objectStore.get(profileName);

			request.onsuccess = function(event) {
				resolve(event.target.result);
				db.close(); // Close the database connection after the operation
			};

			request.onerror = function(event) {
				reject("Error retrieving profile data from IndexedDB");
				db.close(); // Close the database connection after the operation
			};
		};

		dbPromise.onerror = function(event) {
			reject("Error opening IndexedDB:", event.target.error);
		};
	});
}

function onOpenWrapper(){
	onOpen();
	chatOnOpen();
	if (hasAccessToken())
	{
		logged_in = true;
		onLoginWrapper();
	}
	else
	{
		logged_in = false;
		onLogoutWrapper();
	}
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
	if (token == null || token.length < 50)
	{
		return false;
	}
	return true;
}


function setPictureDisplayName(div, name)
{
	//console.log(div, name);
	div.setAttribute("data-display-name", name);
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
	window.ws = new WebSocket('wss://10.11.1.11:9001/ws');
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
						document.cookie = `access_token=null;SameSite=Strict;Secure;`;
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
						if (msg.data.current) {
							getProfileData(msg.data.name).then(function(cachedData) {
								if (!cachedData) {
									console.error("Error: Could not get cached profile picture");
									return;
								}
								for (let i = 0; i < pictureMatches.length; i++) {
									let match = pictureMatches[i];
									match.src = cachedData.profileData.data;
								}
							}).catch(function(error) {
								console.error("Error: " + error);
							});
						} else {
							let data = {
								data: msg.data.image,
								timestamp: msg.data.timestamp
							};
							saveProfileData(msg.data.name, data).then(function() {
								for (let i = 0; i < pictureMatches.length; i++) {
									let match = pictureMatches[i];
									match.src = msg.data.image;
								}
							}).catch(function(error) {
								console.error("Error: " + error);
							});
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
