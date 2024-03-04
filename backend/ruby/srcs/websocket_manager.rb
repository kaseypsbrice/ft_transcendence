require 'pg'
require 'openssl'
require_relative 'user_manager'
require_relative 'pong'
require_relative 'snake'
require_relative 'client'
require_relative 'chat/db_init'
require_relative 'chat/models/chat_message'

class WebSocketManager
	def initialize
		@connections = {} # (websocket connection : client object)
		@db = PG::Connection.new("db", "5432", nil, nil, "pong", "postgres", "password");
		@rsa_private = OpenSSL::PKey::RSA.generate 2048
		@rsa_public = @rsa_private.public_key
		@user_manager = UserManager.new(@db, @rsa_private, @rsa_public)
	end

	def handle_open(ws, handshake)
		puts "WebSocket connection open"
		@connections[ws] = Client.new(ws)
		ws.send({type: "welcome", message: "Welcome to Online Pong!"}.to_json)
	end

	def handle_message(ws, msg)
		puts "Received message: #{msg}"
		if @connections[ws] == nil
			puts "Discarding message from disconnected client"
			return
		end

		client = @connections[ws]

		begin # begin block to rescue JSON.parse Errors (try/catch)
		msg_data = JSON.parse(msg)
		if !msg_data.is_a?(Hash)
			return
		end

		# if this isn't a login, register or ping request, verify token
		if msg_data["type"] != "login" && msg_data["type"] != "register" && msg_data["type"] != "ping" \
			&& msg_data["type"] != "get_leaderboard"
			if !msg_data["token"] || !@user_manager.token_valid?(msg_data["token"])
				ws.send({type: "InvalidToken"}.to_json)
				return
			else
				if !client.user_id || !@user_manager.user?(client.user_id)
					@user_manager.new_user_from_token(client, msg_data["token"])
					if !client.user_id || !@user_manager.user?(client.user_id)
						puts "ERROR: failed to create user from valid token"
						ws.send({type: "InvalidToken"}.to_json)
						return
					end
				end
			end
		end
		
        # ... handle msg_data
		case msg_data["type"]
		when "ping"
			d = ""
			if msg_data["data"]
				d = msg_data["data"]
			end
			ws.send({type:"pong", data: d}.to_json)
		# 								-------- GAME COMMANDS --------
		when "move_left_paddle", "move_right_paddle" # Corrected to match client message types
			if client.game != nil && msg_data.key?("direction")
				direction = msg_data["direction"].to_i
				if msg_data["type"] == "move_left_paddle"
					client.game.move_left_paddle(direction)
				elsif msg_data["type"] == "move_right_paddle"
					client.game.move_right_paddle(direction)
				end
			end
		when "change_direction"
			if client.game != nil && msg_data.key?("direction")
				client.game.change_direction(client.id, msg_data["direction"].to_i)
			end
		when "find_pong"
			if !client.in_game
				client.game_selected = "pong"
				client.matchmaking = true
				partner = find_partner(ws, "pong")
				if partner != nil
					start_game(partner, ws, "pong")
					timer = EM.add_periodic_timer(0.016) {game_loop(ws, timer)}
				end
			end
		when "find_snake"
			if !client.in_game
				client.game_selected = "snake"
				client.matchmaking = true
				partner = find_partner(ws, "snake")
				if partner != nil
					start_game(partner, ws, "snake")
					timer = EM.add_periodic_timer(0.1) {game_loop(ws, timer)}
				end
			end
		when "get_match_history"
			history = @user_manager.get_match_history(client, msg_data["token"])
			ws.send({type: "MatchHistory", data: history}.to_json)
			puts history
			return
		when "register" # 				-------- USER REGISTRATION --------
			if !msg_data.key?("data") || !msg_data["data"].key?("username") || !msg_data["data"].key?("password") || !msg_data["data"].key?("display_name")
				puts "Invalid register request"
				ws.send({type: "RegisterFormatError"}.to_json)
				return # make sure the user sent a username and password
			end

			# create a new user object with credentials, this reads from the database: user.rb
			@user_manager.register(client, msg_data["data"]["username"], msg_data["data"]["password"], msg_data["data"]["display_name"]);

		when "login" # 						-------- USER LOGIN --------
			if !msg_data.key?("data") || !msg_data["data"].key?("username") || !msg_data["data"].key?("password")
				puts "Invalid login request"
				ws.send({type: "LoginFormatError"}.to_json)
				return # make sure the user sent a username and password
			end

			# create a new user object with credentials, this reads from the database: user.rb
			@user_manager.login(client, msg_data["data"]["username"], msg_data["data"]["password"]);
		when "chat_message"
			# TODO: Extract sender_id and receiver_id from the message or session context
			sender_id = client.user_id
			receiver_id = -1
			msg_data.delete("token")
			msg_data.delete("type")
			msg_data["sender"] = @user_manager.get_user(client.user_id).display_name
			msg_data["content"] = msg_data["content"].lstrip.rstrip
			puts "1"
			if !msg_data["content"] || msg_data["content"].empty?
				return
			end

			puts "2"
			# Chat commands
			if msg_data["content"].start_with?("/")
				msg_data["content"].slice!(0)
				split_msg = msg_data["content"].split(' ', 3)
				case split_msg[0]
				when "w"
					if split_msg.size < 3
						ws.send({type:"ChatMessageError", error:"NoWhisperUser", message:"/w {user} {msg}"}.to_json)
						return
					end
					begin
						user = User.from_display_name(split_msg[1])
						if !@user_manager.user?(user.id)
							ws.send({type:"ChatMessageError", error:"UserOffline", message:"User #{split_msg[1]} is offline"}.to_json)
							return
						end
						receiver_id = user.id
						msg_data["content"] = split_msg[2]
						
						ws.send({type:"WhisperResponse", user: split_msg[1], message: msg_data["content"]}.to_json)
					rescue User::Error
						ws.send({type:"ChatMessageError", error:"UserNotFound", message:"User #{split_msg[1]} does not exist"}.to_json)
						return
					end
				when "help"
					ws.send({type:"HelpResponse", message:"Commands\n\t/w {user} {msg} : whisper to a user"}.to_json)
					return
				end
			end

			#TODO: check if client is in game and send to partner game websocket

			# Save the message to the database
			puts "creating chat message"
			ChatMessage.create(sender_id: sender_id, receiver_id: receiver_id, content: msg_data["content"])

			# Broadcast the message to all clients (including the sender)
			if receiver_id == -1
				@connections.each { |client_ws, client| 
				client_ws.send({type: "ChatMessage", message: msg_data}.to_json)
				}
			else # Whisper to all clients logged in as correct user
				@connections.each { |client_ws, client| 
					if client.user_id == receiver_id
						client_ws.send({type: "ChatMessage", message: msg_data}.to_json)
					end
				}
			end
		when "get_leaderboard"
			ws.send({type: "GetLeaderboard", data: @user_manager.get_leaderboard()}.to_json)
		end
		rescue JSON::ParserError => e
			puts "Error parsing JSON: #{e.message}"
		end
	end

	def handle_close(ws, code, reason)
		client = @connections[ws]
		if (client.in_game && client.partner != nil)
			partner = @connections[client.partner]
			if (partner != nil)
				partner.game = nil
				partner.in_game = false
				puts "client disconnected"
				client.partner.send({type: "partner_disconnected"}.to_json)
			end
		end
		puts "WebSocket connection closed"
    	@connections.delete(ws)
		@connections.each_value do |other_client|
			if client.user_id == other_client.user_id
				return
			end
		end
		@user_manager.delete_user(client.user_id)
	end

	def find_partner(ws, game)
		client = @connections[ws]
		@connections.each {|partner_ws, partner|
			if partner_ws == ws
				next
			#elsif @user_manager.get_user(client.user_id).id == @user_manager.get_user(partner.user_id).id # UNCOMMENT FOR RELEASE, MAKES IT SO YOU CAN"T PLAY AGAINST YOURSELF
			#	puts "You can not play against yourself"
			#	next
			end
			partner = @connections[partner_ws]
			if partner.game_selected == game && partner.matchmaking && !partner.in_game
				return partner_ws
			end
		}
		return nil
	end
	
	def start_game(player1_ws, player2_ws, game_name)
		player1 = @connections[player1_ws]
		player2 = @connections[player2_ws]
	
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
			player2.game = @connections[player1_ws].game
		elsif game_name == "snake"
			player1.game = SnakeGame.new
			player2.game = @connections[player1_ws].game
		end
		player1_ws.send({type: "game_found", data: {player_id: player1.id}}.to_json);
		player2_ws.send({type: "game_found", data: {player_id: player2.id}}.to_json);
	end
	
	def game_loop(player_ws, timer)
		if @connections[player_ws] == nil
			timer.cancel
			puts "player_ws nil"
			return
		end
	
		game = @connections[player_ws].game
		if game == nil 
			timer.cancel
			puts "game nil"
			return
		end
	
		player = @connections[player_ws]
		partner = @connections[player.partner]
		if partner == nil
			timer.cancel
			puts "partner nil"
			return
		end
		
		game.update_game_state
		player_ws.send({type: "state", data: game.state_as_json}.to_json) 
		player.partner.send({type: "state", data: game.state_as_json}.to_json)
		if game.state_as_json["winner"] != nil && game.state_as_json["winner"] > -1
			winner_id = player.user_id
			loser_id = partner.user_id
			if game.state_as_json["winner"] != player.id
				winner_id = partner.user_id
				loser_id = player.user_id
			end
			@user_manager.save_match(player.game_selected, winner_id, loser_id, "INSERT MATCH TYPE HERE")
			player.in_game = false
			player.game = nil
			partner.in_game = false
			partner.game = nil
			timer.cancel
		end
	end
end