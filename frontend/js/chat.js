function onMessage(ws, event, msg) {
	console.log(msg)
	if (msg.type === "ChatMessage" && msg["message"] != null && msg.message["content"] != null)
		displayMessage(msg.message);
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

function displayMessage(message) {
    console.log('Displaying message:', message);
    const messageElement = document.createElement('div');
    messageElement.classList.add('chat-message');
    messageElement.textContent = message.content;
    document.getElementById('messages').appendChild(messageElement);
    document.getElementById('messages').scrollTop = document.getElementById('messages').scrollHeight;
}

(function (){
	console.log("loaded")
    const messageInput = document.getElementById('messageInput'); // input element for typing messages
    const messagesDiv = document.getElementById('messages'); // container where messages are displayed

    function fetchChatHistory() {
        fetch('https://127.0.0.1:9001/chat-history')
            .then(response => response.json())
            .then(messages => {
                messages.forEach(message => displayMessage(message));
            })
            .catch(error => console.error('Error fetching chat history:', error));
    }

    fetchChatHistory();

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
