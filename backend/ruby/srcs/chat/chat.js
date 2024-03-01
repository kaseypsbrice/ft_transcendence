const ws = new WebSocket('wss://localhost:8080');

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
		state = "logged_out";
		return true;
	}
	data["token"] = token;
	ws.send(JSON.stringify(data));
	return false;
}

ws.onopen = function() {
    console.log('Connected to the chat server');
};

ws.onmessage = function(event) {
    console.log('Received message:', event.data);
    const message = JSON.parse(event.data);
    displayMessage(message);
};

ws.onerror = function(error) {
    console.log('WebSocket Error:', error);
};

function sendMessage() {
    const message = {
		type: "chat_message",
        content: document.getElementById('messageInput').value
    };
    console.log('Sending message:', message);
    if (sendWithToken(ws, message))
		console.log("You are not logged in!");
    document.getElementById('messageInput').value = '';
}

function displayMessage(message) {
    console.log('Displaying message:', message);
    const messageElement = document.createElement('div');
    messageElement.classList.add('chat-message');
    messageElement.textContent = message.content;
    document.getElementById('messages').appendChild(messageElement);
    document.getElementById('messages').scrollTop = document.getElementById('messages').scrollHeight;
}

document.addEventListener('DOMContentLoaded', function() {
    const messageInput = document.getElementById('messageInput'); // input element for typing messages
    const messagesDiv = document.getElementById('messages'); // container where messages are displayed

    function fetchChatHistory() {
        fetch('http://localhost:4567/chat-history')
            .then(response => response.json())
            .then(messages => {
                messages.forEach(message => displayMessage(message));
            })
            .catch(error => console.error('Error fetching chat history:', error));
    }

    fetchChatHistory();

    document.getElementById('sendButton').addEventListener('click', function(event) {
        event.preventDefault(); // Prevent the default button click behavior
        sendMessage();
    });

	messageInput.addEventListener("keypress", function(event){
		if (event.key === "Enter") {
			event.preventDefault();
			sendMessage();
		}
	})
});