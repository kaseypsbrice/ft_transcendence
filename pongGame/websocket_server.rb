require 'em-websocket'
require 'faye/websocket'
require 'eventmachine'
require 'json'
require 'pg'
require_relative 'client'
require_relative 'pong' # Ensure pong.rb is correctly referenced
require_relative 'snake'
require_relative 'user'

$clients = Hash.new
$db = PG::Connection.new("localhost", "5432", nil, nil, "transcendence", "admin", "password");

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

def game_loop(player_ws, timer)
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
	partner = $clients[player.partner]
	if partner == nil
		timer.cancel
		puts "partner nil"
		return
	end
	
	game.update_game_state
	player_ws.send({type: "state", data: game.state_as_json}.to_json) 
	player.partner.send({type: "state", data: game.state_as_json}.to_json)
	if game.state_as_json["winner"] != nil && game.state_as_json["winner"] > -1
		player.in_game = false
		player.game = nil
		partner.in_game = false
		partner.game = nil
		timer.cancel
	end
end

EM.run {
	EM::WebSocket.run(:host => '0.0.0.0', :port => 8080) do |ws|
		ws.onopen do |handshake|
		puts "WebSocket connection open"
		$clients[ws] = Client.new
		ws.send({type: "welcome", message: "Welcome to Online Pong!"}.to_json)
		#ws.send({type: "state", data: game.state_as_json}.to_json)
    end

    ws.onmessage do |msg|
		puts "Received message: #{msg}"
		if $clients[ws] == nil
			puts "Discarding message from disconnected client"
			next
		end
		begin
		action = JSON.parse(msg)
		if !action.is_a?(Hash)
			next
		end
        # ... handle actions
		case action["type"]
		when "move_left_paddle", "move_right_paddle" # Corrected to match client message types
			if $clients[ws].game != nil && action.key?("direction")
				direction = action["direction"].to_i
				if action["type"] == "move_left_paddle"
					$clients[ws].game.move_left_paddle(direction)
				elsif action["type"] == "move_right_paddle"
					$clients[ws].game.move_right_paddle(direction)
				end
			end
		when "change_direction"
			if $clients[ws].game != nil && action.key?("direction")
				$clients[ws].game.change_direction($clients[ws].id, action["direction"].to_i)
			end
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
		when "register"
			if !action.key?("data") || !action["data"].key?("username") || !action["data"].key?("username")
				puts "Invalid register request"
				return
			end
			user = User.create(action["data"]["username"], action["data"]["password"], $db);
			if user.error == nil
				puts "New User: " + user.id.to_s
			end
		end
        
		rescue JSON::ParserError => e
			puts "Error parsing JSON: #{e.message}"
		end
	end

    ws.onclose do |code, reason|
		client = $clients[ws]
		if (client.in_game && client.partner != nil)
			partner = $clients[client.partner]
			if (partner != nil)
				partner.game = nil
				partner.in_game = false
				puts "client disconnected"
				client.partner.send({type: "partner_disconnected"}.to_json)
			end
		end
		puts "WebSocket connection closed"
    	$clients.delete(ws)
    end
end
}

