function openChat() {
    document.getElementById("chat-form-container").style.display = "block";
}

function closeChat() {
    document.getElementById("chat-form-container").style.display = "none";
}

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

let message_id = 0;
const messageInput = document.getElementById('message-input');

window.chatOnMessage = function(msg) {
	//(msg)
	switch (msg.type)
	{
		case "ChatMessage":
			let you = false;
			if (msg.you != null)
				you = msg.you;
			if (validMessage(msg))
				displayUserMessage(msg.message["sender"], msg.message["content"], false, you);
			break;
		case "Alert":
			if (msg.data != null && msg.data.type != null)
			{
				switch (msg.data.type)
				{
					case "invite":
						displayMessage(`${msg.data.user_from} invited you to a game of ${msg.data.game}!`, true, function() {
							acceptInvite(msg.data.user_from);
						});
						break;
					case "friend":
						displayMessage(`${msg.data.user_from} wants to be your friend!`, true, function() {
							sendWithToken(ws, {type: "accept_friend", name: msg.data.user_from});
						});
						break;
				}
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
				for (let i = msg.data.length - 1; i >= 0; i--)
				{
					let you = false;
					if (msg.data.you != null)
						you = msg.data.you;
					if (validMessage(msg.data[i]))
						displayUserMessage(msg.data[i].message.sender, msg.data[i].message.content, false, you);
				}
			}
			break;
		case "TournamentInfo":
			if (msg.data && msg.data.status && msg.data.game && msg.data.status == "MatchReady")
			{
				displayMessage("Tournament match ready! Click to join", true, function () {
					window.location.hash = msg.data.game;
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
			displayMessage("Successfully joined tournament, waiting for players...", true, function() {
				window.location.hash = "#tournament";
			});
			break
		case "TournamentSuccess":
			if (msg["game"] != null)
				displayMessage(`Successfully proposed ${msg.game} tournament`, true, function() {
			window.location.hash = "#tournament";
		});
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
		content: messageInput.value
	};
	//console.log('Sending message:', message);
	sendWithToken(ws, message);
	messageInput.value = '';
}

function displayNameClicked(display_name)
{
	viewProfile(display_name);
}

function displayUserMessage(display_name, msg, whisper = false, you = false)
{
	const messageContainer = document.getElementById('msg-container')
	const messageElement = document.createElement('div');
	messageElement.classList.add('msg');
	if (you)
		messageElement.classList.add('our-msg');
	else
		messageElement.classList.add('other-msg');
	const messageParagraph = document.createElement('p');
	if (whisper)
		messageParagraph.innerHTML = `~<span id=clickable-name-${message_id}>${display_name}</span> whispers~: ${msg}`
	else
		messageParagraph.innerHTML = `<span id=clickable-name-${message_id}>${display_name}</span>: ${msg}`

	messageElement.appendChild(messageParagraph);
	messageContainer.appendChild(messageElement);
	const clickableSpan = document.getElementById(`clickable-name-${message_id}`);
	clickableSpan.classList.add('clickable');
	clickableSpan.style.cursor = 'pointer';
    clickableSpan.style.color = 'white';
	clickableSpan.style.textDecoration = 'underline';
	clickableSpan.addEventListener('click', function() {
		displayNameClicked(display_name);
	});
	document.getElementById('msg-container').scrollTop = document.getElementById('msg-container').scrollHeight;
	message_id += 1;
}

function displayMessage(str, clickable = false, clickHandler = null) {
	const messageElement = document.createElement('div');
	messageElement.classList.add('msg');
	messageElement.classList.add('server-msg');
	const messageParagraph = document.createElement('p');
	messageParagraph.textContent = str;
	if (clickable) {
		messageParagraph.classList.add('clickable');
		messageParagraph.style.cursor = 'pointer';
        messageParagraph.style.color = 'white';
		messageParagraph.style.textDecoration = 'underline';
		messageParagraph.addEventListener('click', function() {
			clickHandler();
			messageElement.remove();
		});
	}
	messageElement.appendChild(messageParagraph);
	document.getElementById('msg-container').appendChild(messageElement);
	document.getElementById('msg-container').scrollTop = document.getElementById('msg-container').scrollHeight;

}

document.getElementById('send-button').addEventListener('click', function(event) {
	event.preventDefault(); // Prevent the default button click behavior
	//console.log("clicked");
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
	