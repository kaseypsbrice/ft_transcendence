(function (){

function validMessage(msg)
{
	if (msg["message"] == null || msg.message["content"] == null || msg.message["sender"] == null)
		return false;
	return true;
}

window.chatOnLogin = function () {
	sendWithToken(ws, {type: "get_chat_history"});
	sendWithToken(ws, {type: "get_alerts"});
};

window.chatOnMessage = function(event, msg) {
	console.log(msg)
	switch (msg.type)
	{
		case "ChatMessage":
			if (validMessage(msg))
				displayUserMessage(msg.message["sender"], msg.message["content"]);
			break;
		case "Alert":
			if (msg.data != null && msg.data.type != null)
			{
				displayMessage(`${msg.data.user_from} invited you to a game of ${msg.data.game}!`, true, function() {
					acceptInvite(msg.data.user_from);
				});
			}
			break;
		case "Whisper":
			if (validMessage(msg))
				displayUserMessage(msg.message["sender"], msg.message["content"], true);
			break;
		case "WhisperResponse":
			if (msg["message"] != null && msg["user"] != null)
				displayMessage(`~you whisper to ${msg.user}~: ${msg.message}`);
			break;
		case "ChatMessageError":
			if (msg["message"] != null)
			displayMessage(`Error! ${msg.message}`);
			break;
		case "ChatHistory":
			if (msg["data"] != null)
			{
				for (i in msg.data)
				{
					if (validMessage(msg.data[i]))
						displayUserMessage(msg.data[i].message.sender, msg.data[i].message.content);
				}
			}
			break;
		case "TournamentMatchStarted":
			if (msg["game"] != null)
			{
				displayMessage("Tournament match ready! Click to join", true, function () {
					window.location.hash = msg["game"];
				});
			}
			break;
		case "InviteAccepted":
			if (msg["game"] != null)
			{
				displayMessage("Private match ready! Click to join", true, function () {
					window.location.hash = msg["game"];
				});
			}
			break;
		case "HelpResponse":
			if (msg["message"] != null)
				displayMessage(msg.message);
			break;
		case "ChatTournamentCreated":
			if (msg["game"] != null && msg["user"] != null && msg["id"] != null)
			{
				displayMessage(`${msg.user} proposes a ${msg.game} tournament! Click to join!`, true, function() {
					sendWithToken(ws, {type: "join_tournament_id", id: msg.id});
				});
			}
			break
		case "JoinTournamentSuccess":
			displayMessage("Successfully joined tournament, waiting for players...");
			break
		case "TournamentSuccess":
			if (msg["game"] != null)
				displayMessage(`Successfully proposed ${msg.game} tournament`);
			break;
		case "InviteSuccess":
			if (msg["user"] != null)
				displayMessage(`Successfully invited ${msg.user} to a game`);
			break;
		case "InvalidToken":
				displayMessage(`Please login to view chat`, true, function () {
					window.location.hash = "#login";
				});
			break;
	}
};

function acceptInvite(text)
{
	sendWithToken(ws, {type: "accept_invite", user_from: text.split(" ")[0]});
}

function sendMessage() {
	if (!ws || ws.readyState != ws.OPEN)
	{
		displayMessage("Error! Not connected to server");
		return;
	}
    message = {
		type: "chat_message",
        content: document.getElementById('messageInput').value
    };
    console.log('Sending message:', message);
    sendWithToken(ws, message);
    document.getElementById('messageInput').value = '';
}

function displayNameClicked(display_name)
{
	current_profile = display_name;
	window.location.hash = "#profile";
}

function displayUserMessage(display_name, msg, whisper = false)
{
	const messageElement = document.createElement('div');
	messageElement.classList.add('chat-message');

	const clickableSpan = document.createElement('span');
	const textNode = document.createTextNode(`: ${msg}`);
	if (whisper)
		clickableSpan.textContent = `~${display_name} whispers~`;
	else
		clickableSpan.textContent = display_name;
	clickableSpan.classList.add('clickable');
	clickableSpan.style.cursor = 'pointer';
	clickableSpan.style.textDecoration = 'underline';
	clickableSpan.addEventListener('click', function() {
		displayNameClicked(display_name);
    });
	messageElement.appendChild(clickableSpan);
	messageElement.appendChild(textNode);
	document.getElementById('messages').appendChild(messageElement);
	document.getElementById('messages').scrollTop = document.getElementById('messages').scrollHeight;
}

function displayMessage(str, clickable = false, clickHandler = null) {
	console.log('Displaying message:', str);
	const messageElement = document.createElement('div');
	messageElement.classList.add('chat-message');
	if (clickable) {
		const clickableSpan = document.createElement('span');
		clickableSpan.classList.add('clickable');
		clickableSpan.textContent = str;
		clickableSpan.style.cursor = 'pointer';
		clickableSpan.style.textDecoration = 'underline';
		clickableSpan.addEventListener('click', function() {
			clickHandler();
			messageElement.remove();
		});
		messageElement.appendChild(clickableSpan);
	} else {
		messageElement.textContent = str;
	}
	document.getElementById('messages').appendChild(messageElement);
	document.getElementById('messages').scrollTop = document.getElementById('messages').scrollHeight;
}


const messageInput = document.getElementById('messageInput'); // input element for typing messages
const messagesDiv = document.getElementById('messages'); // container where messages are displayed


document.getElementById('sendButton').addEventListener('click', function(event) {
	event.preventDefault(); // Prevent the default button click behavior
	console.log("clicked");
	sendMessage();
});

messageInput.addEventListener("keypress", function(event){
	if (event.key === "Enter") {
		event.preventDefault();
		sendMessage();
	}
});

if (ws.readyState == ws.OPEN)
	chatOnLogin();

})();
