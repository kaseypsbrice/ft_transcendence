require 'em-websocket'
require 'faye/websocket'
require 'eventmachine'
require 'json'
require_relative 'client'
require_relative 'pong' # Ensure pong.rb is correctly referenced
require_relative 'snake'

$clients = Hash.new

Signal.trap("INT") {
	puts "Shutting down server..."
	# Close the WebSocket connections
	$clients.each_key { |ws| ws.close }
	EM.stop if EM.reactor_running?
	exit
}

def find_partner(ws, game)
	$clients.each {|partner_ws, client|
		if partner_ws == ws
			next
		end
		partner = $clients[partner_ws]
		if partner.game_selected == game && partner.matchmaking && !partner.in_game
			return partner_ws
		end
	}
	return nil
end

def start_game(player1_ws, player2_ws, game_name)
	player1 = $clients[player1_ws]
	player2 = $clients[player2_ws]

	player1.id = 0
	player1.matchmaking = false
	player1.in_game = true
	player1.partner = player2_ws

	player2.id = 1
	player2.matchmaking = false
	player2.in_game = true
	player2.partner = player1_ws

	if game_name == "pong"
		player1.game = PongGame.new
		player2.game = $clients[player1_ws].game
	elsif game_name == "snake"
		player1.game = SnakeGame.new
		player2.game = $clients[player1_ws].game
	end
	player1_ws.send({type: "game_found", data: {player_id: player1.id}}.to_json);
	player2_ws.send({type: "game_found", data: {player_id: player2.id}}.to_json);
end

# todo: proper client disconnection
def game_loop(player_ws, timer)
	#puts "update_pong_state"
	if $clients[player_ws] == nil
		timer.cancel
		puts "player_ws nil"
		return
	end

	game = $clients[player_ws].game
	if game == nil 
		timer.cancel
		puts "game nil"
		return
	end

	player = $clients[player_ws]
	if $clients[player.partner] == nil
		timer.cancel
		puts "partner nil"
		return
	end
	
	game.update_game_state
	player_ws.send({type: "state", data: game.state_as_json}.to_json) 
	player.partner.send({type: "state", data: game.state_as_json}.to_json) 
end



EM.run {
  # Periodic timer for game state updates
  #EM.add_periodic_timer(0.016) do
  #  game.update_game_state # Your method to update the game state
   # game_state_json = game.state_as_json.to_json
    # clients.each { |client| client.send(game_state_json) }
	#clients.each {|ws, client|
	#	ws.send({type: "state", data: game.state_as_json}.to_json) 
	#}
  #end

	EM::WebSocket.run(:host => '0.0.0.0', :port => 8080) do |ws|
		ws.onopen do |handshake|
		puts "WebSocket connection open"
		$clients[ws] = Client.new
		ws.send({type: "welcome", message: "Welcome to Online Pong!"}.to_json)
		#ws.send({type: "state", data: game.state_as_json}.to_json)
    end

    ws.onmessage do |msg|
		puts "Received message: #{msg}"
		action = JSON.parse(msg)
        # ... handle actions
		case action["type"]
		when "move_left_paddle", "move_right_paddle" # Corrected to match client message types
			direction = action["direction"].to_i
			if action["type"] == "move_left_paddle"
				$clients[ws].game.move_left_paddle(direction)
			elsif action["type"] == "move_right_paddle"
				$clients[ws].game.move_right_paddle(direction)
			end
		when "change_direction"
			$clients[ws].game.change_direction($clients[ws].id, action["direction"].to_i)
		when "find_pong"
			if !$clients[ws].in_game
				$clients[ws].game_selected = "pong"
				$clients[ws].matchmaking = true
				partner = find_partner(ws, "pong")
				if partner != nil
					start_game(partner, ws, "pong")
					timer = EM.add_periodic_timer(0.016) {game_loop(ws, timer)}
				end
			end
		when "find_snake"
			if !$clients[ws].in_game
				$clients[ws].game_selected = "snake"
				$clients[ws].matchmaking = true
				partner = find_partner(ws, "snake")
				if partner != nil
					start_game(partner, ws, "snake")
					timer = EM.add_periodic_timer(0.1) {game_loop(ws, timer)}
				end
			end
		end
        
        # # add log to see the game state
		#game_state_json = game.state_as_json.to_json
        #puts "Game state: #{game_state_json}"

		# clients.each { |client| client.send({type: "state", data: game.state_as_json}.to_json) }

		#rescue JSON::ParserError => e
		#	puts "Error parsing JSON: #{e.message}"
	end

    ws.onclose do |code, reason|
      $clients.delete(ws)
    end
end
}

