require_relative 'db_init'
require_relative 'models/chat_message'

sender_id = 1
receiver_id = 2
content = "Hello, this is a test message."

chat_message = ChatMessage.create(sender_id: sender_id, receiver_id: receiver_id, content: content)

if chat_message.persisted?
	puts "Messaage saved successfully. ID: #{chat_message.id}"
else
	puts "Failed to save the message."
end
