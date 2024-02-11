require 'em-websocket'
require 'faye/websocket'
require 'eventmachine'
require 'json'
require_relative 'pong' # Ensure pong.rb is correctly referenced

Signal.trap("INT") {
	puts "Shutting down server..."
	# Close the WebSocket connections
	clients.each { |client| client.close }
	EM.stop if EM.reactor_running?
	exit
}

EM.run {
  clients = []
  game = PongGame.new

  # Periodic timer for game state updates
  EM.add_periodic_timer(0.016) do
    game.update_game_state # Your method to update the game state
    game_state_json = game.state_as_json.to_json
    # clients.each { |client| client.send(game_state_json) }
	clients.each { |client| client.send({type: "state", data: game.state_as_json}.to_json) }
  end

  EM::WebSocket.run(:host => '0.0.0.0', :port => 8080) do |ws|
    ws.onopen do |handshake|
      puts "WebSocket connection open"
      clients << ws
      ws.send({type: "welcome", message: "Welcome to Online Pong!"}.to_json)
      ws.send({type: "state", data: game.state_as_json}.to_json)
    end

    ws.onmessage do |msg|
      puts "Received message: #{msg}"
      begin
        action = JSON.parse(msg)
        # ... handle actions
        case action["type"]
		when "move_left_paddle", "move_right_paddle" # Corrected to match client message types
		  direction = action["direction"].to_i
		  if action["type"] == "move_left_paddle"
			game.move_left_paddle(direction)
		  elsif action["type"] == "move_right_paddle"
			game.move_right_paddle(direction)
		  end
		end

        
        
        # # add log to see the game state
		game_state_json = game.state_as_json.to_json
        puts "Game state: #{game_state_json}"

		# clients.each { |client| client.send({type: "state", data: game.state_as_json}.to_json) }

      rescue JSON::ParserError => e
        puts "Error parsing JSON: #{e.message}"
      end
    end

    ws.onclose do |code, reason|
      clients.delete(ws)
    end
  end
}

