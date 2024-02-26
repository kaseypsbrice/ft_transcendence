document.addEventListener('DOMContentLoaded', function() {
    const messagesDiv = document.getElementById('chat-window');

    function fetchChatHistory() {
        fetch('http://localhost:4567/chat-history')
            .then(response => response.json())
            .then(messages => {
                messages.forEach(message => displayMessage(message));
            })
            .catch(error => console.error('Error fetching chat history:', error));
    }

    function displayMessage(message) {
		const messageElement = document.createElement('div');
		messageElement.classList.add('chat-message');
	
		// If the message is from the current user, mark it as sent
		// You will need to set the currentUserId variable based on your app's user session logic
		const currentUserId = 1; // Example user ID; replace with actual logic to determine current user
		if (message.sender_id === currentUserId) {
			messageElement.classList.add('sent');
		}
	
		const date = new Date(message.created_at); // Use the created_at property from your message
		const timeString = `${date.getHours()}:${date.getMinutes().toString().padStart(2, '0')}`;
	
		// Here you need to replace `message.username` with the actual property that holds the username
		// If you don't have usernames and only display timestamps, you can remove the username part
		messageElement.innerHTML = `
			<div>${message.content}</div>
			<div class="chat-message-info">
				<span>${timeString}</span> 
			</div>
		`;
	
		const messagesDiv = document.getElementById('messages'); // Ensure this is the correct ID for your messages container
		messagesDiv.appendChild(messageElement);
		messagesDiv.scrollTop = messagesDiv.scrollHeight; // Auto-scroll to latest message
	}

    fetchChatHistory();
});