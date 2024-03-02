require 'em-websocket'
require_relative 'db_init'
require_relative 'models/chat_message'

Signal.trap("INT") {
	puts "Shutting down server..."
	# Close the WebSocket connections
	@clients.each {|client| client.close}
	EM.stop if EM.reactor_running?
	exit
}

# Stores connections to vroadcast messages to all cliets
@clients = []

EventMachine.run do
	EventMachine::WebSocket.start(host: '0.0.0.0', port:8081) do |ws|
		ws.onopen do
			puts "Websocket connection opened"
			@clients << ws
		end

		ws.onclose do
			puts "Websocket connection closed"
			@clients.delete(ws)
		end

		ws.onmessage do |msg|
			# TODO: Extract sender_id and receiver_id from the message or session context
			msg_data = JSON.parse(msg)
			sender_id = msg_data['sender_id']
			receiver_id = msg_data['receiver_id']
			content = msg_data['content']

			# Add log to check whether the message is received
			puts "Received message: #{content} from #{sender_id} to #{receiver_id}"

			# Save the message to the database
			ChatMessage.create(sender_id: sender_id, receiver_id: receiver_id, content:content)

			# Broadcast the message to all clients (including the sender
			@clients.each { |client| client.send msg }
		end

		ws.onerror do |error|
			puts "Error encountered: #{error.message}"
		end
	end
end
