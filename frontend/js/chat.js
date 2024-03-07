(function (){

function validMessage(msg)
{
	if (msg["message"] == null || msg.message["content"] == null || msg.message["sender"] == null)
		return false;
	return true;
}

window.onMessage = function(ws, event, msg) {
	console.log(msg)
	if (msg.type === "ChatMessage" && validMessage(msg))
	{
		displayMessage(msg.message["sender"] + ": " + msg.message["content"]);
	}
	else if (msg.type === "Alert" && msg.data != null && msg.data.type != null)
	{
		if (msg.data.type === "invite" && msg.data.user_from != null && msg.data.game != null)
		{
			displayMessage(`${msg.data.user_from} invited you to a game of ${msg.data.game}!`, true, function() {
				acceptInvite(msg.data.user_from);
			});
		}
	}
	else if (msg.type == "Whisper" && validMessage(msg))
	{
		displayMessage(`~${msg.message["sender"]} whispers~: ${msg.message["content"]}`)
	}
	else if (msg.type == "WhisperResponse" && msg["message"] != null && msg["user"] != null)
	{
		displayMessage(`~you whisper to ${msg.user}~: ${msg.message}`)
	}
	else if (msg.type == "ChatMessageError" && msg["message"] != null)
	{
		displayMessage(`Error! ${msg.message}`)
	}
};

function acceptInvite(text)
{
	ws.sendWithToken({type: "accept_invite", user_from: text.split(" ")[0]});
}

function sendMessage() {
    message = {
		type: "chat_message",
        content: document.getElementById('messageInput').value
    };
    console.log('Sending message:', message);
    sendWithToken(ws, message);
    document.getElementById('messageInput').value = '';
}

function displayMessage(str, clickable = false, clickHandler = null) {
	console.log('Displaying message:', str);
	const messageElement = document.createElement('div');
	messageElement.classList.add('chat-message');
	if (clickable) {
		const clickableSpan = document.createElement('span');
		clickableSpan.classList.add('clickable');
		clickableSpan.textContent = str;
		clickableSpan.addEventListener('click', clickHandler);
		messageElement.appendChild(clickableSpan);
	} else {
		messageElement.textContent = str;
	}
	document.getElementById('messages').appendChild(messageElement);
	document.getElementById('messages').scrollTop = document.getElementById('messages').scrollHeight;
}


const messageInput = document.getElementById('messageInput'); // input element for typing messages
const messagesDiv = document.getElementById('messages'); // container where messages are displayed

function fetchChatHistory() {
	fetch('https://127.0.0.1:9001/chat-history')
		.then(response => response.json())
		.then(messages => {
			messages.forEach(message => displayMessage(message.sender + ": " + message.content));
		})
		.catch(error => console.error('Error fetching chat history:', error));
}
fetchChatHistory();

sendWithToken(ws, {type: "get_alerts"});

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
})
})();
