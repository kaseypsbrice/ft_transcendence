require 'pg'
require 'openssl'
require_relative 'user_manager'
require_relative 'pong'
require_relative 'snake'
require_relative 'client'
require_relative 'chat/db_init'
require_relative 'chat/models/chat_message'
require_relative 'tournament'
require_relative 'alert_manager'

class WebSocketManager
	attr_accessor :connections, :db

	def initialize
		@connections = {} # (websocket connection : client object)
		@db = PG::Connection.new("db", "5432", nil, nil, "pong", "postgres", "password");
		@rsa_private = OpenSSL::PKey::RSA.generate 2048
		@rsa_public = @rsa_private.public_key
		@user_manager = UserManager.new(@db, @rsa_private, @rsa_public)
		@alert_manager = AlertManager.new(self)
	end

	def handle_open(ws, handshake)
		puts "WebSocket connection open"
		@connections[ws] = Client.new(ws)
		ws.send({type: "welcome", message: "Welcome to Online Pong!"}.to_json)
		@alert_manager.send_client_alerts(@connections[ws])
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
		
		user = @user_manager.get_user(client.user_id)
		if user != nil
			user.current_ws = ws
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
					client.game.set_left_paddle(direction)
				elsif msg_data["type"] == "move_right_paddle"
					client.game.set_right_paddle(direction)
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
				end
			end
		when "find_snake"
			if !client.in_game
				client.game_selected = "snake"
				client.matchmaking = true
				partner = find_partner(ws, "snake")
				if partner != nil
					start_game(partner, ws, "snake")
				end
			end
		when "find_tournament"
			if !msg_data.key?("game")
				ws.send({type: "FindTournamentError", message: "Game not provided"}.to_json)
				return
			end
			if !@alert_manager.join_or_create_tournament(user, msg_data["game"])
				ws.send({type: "FindTournamentError", message: "Game not found"}.to_json)
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
			save_to_db = true
			sender_id = client.user_id
			receiver_id = -1
			msg_data.delete("token")
			msg_data.delete("type")
			msg_data["sender"] = @user_manager.get_user(client.user_id).display_name
			msg_data["content"] = msg_data["content"].lstrip.rstrip
			if !msg_data["content"] || msg_data["content"].empty?
				return
			end

			#                               -------- CHAT COMMANDS --------
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
						target = @user_manager.get_user_from_display_name(split_msg[1])
						if !target
							ws.send({type:"ChatMessageError", error:"UserOffline", message:"User #{split_msg[1]} is offline"}.to_json)
							return
						end
						if target.blocked?(user.id)
							ws.send({type: "ChatMessageError", error:"Blocked", message: "Cannot whisper #{split_msg[1]}, you are blocked"}.to_json)
							return
						end
						if user.blocked?(target.id)
							ws.send({type: "ChatMessageError", error:"Blocked", message: "Cannot whisper #{split_msg[1]}, they are blocked"}.to_json)
							return
						end
						receiver_id = target.id
						msg_data["content"] = split_msg[2]
						
						ws.send({type:"WhisperResponse", user: split_msg[1], message: msg_data["content"]}.to_json)
						@connections.each { |client_ws, client| 
							if client.user_id == receiver_id
								client_ws.send({type: "Whisper", message: msg_data}.to_json)
							end
						}
						return
					rescue User::Error
						ws.send({type:"ChatMessageError", error:"UserNotFound", message:"User #{split_msg[1]} does not exist"}.to_json)
						return
					end
				when "invite"
					if split_msg.size < 3
						ws.send({type: "ChatMessageError", error: "InviteFormat", message: "Invite format error"}.to_json)
						return
					elsif split_msg[2] != "pong" && split_msg[2] != "snake"
						ws.send({type: "ChatMessageError", error: "InviteFormat", message: "Invite game #{split_msg[2]} not recognised, try 'pong' or 'snake'"}.to_json)
						return
					end
					user_to = @user_manager.get_user_from_display_name(split_msg[1])
					if (user_to == nil)
						ws.send({type: "ChatMessageError", error:"UserNotFound", message: "User #{split_msg[1]} is not online"}.to_json)
						return
					end
					if user_to.blocked?(user.id)
						ws.send({type: "ChatMessageError", error:"Blocked", message: "Cannot invite #{split_msg[1]}, you are blocked"}.to_json)
						return
					end
					if user.blocked?(user_to.id)
						ws.send({type: "ChatMessageError", error:"Blocked", message: "Cannot invite #{split_msg[1]}, they are blocked"}.to_json)
						return
					end
					@alert_manager.create_invite(user, user_to, split_msg[2])
					ws.send({type: "InviteSuccess", user: split_msg[1]}.to_json)
					return
				when "help"
					ws.send({type: "HelpResponse", message:"---Commands---"}.to_json)
					ws.send({type: "HelpResponse", message:"/w {user} {msg} : whisper to a user"}.to_json)
					ws.send({type: "HelpResponse", message:"/invite {user} {game} : invite user to game"}.to_json)
					ws.send({type: "HelpResponse", message:"/tournament {game} : propose a tournament"}.to_json)
					ws.send({type: "HelpResponse", message:"/profile {display name} : view a profile"}.to_json)
					return
				when "tournament"
					if split_msg.size < 2
						ws.send({type: "ChatMessageError", error:"TournamentFormatError", message: "Tournament format error"}.to_json)
						return
					end
					if user.tournament != nil
						ws.send({type: "ChatMessageError", error:"AlreadyInTournament", message: "You are already in a #{user.tournament.game} tournament"}.to_json)
						return
					end
					if @alert_manager.create_tournament(user, split_msg[1])
						ws.send({type: "TournamentSuccess", game: split_msg[1]}.to_json)
						to_all = {type: "ChatTournamentCreated", user: user.display_name, game: split_msg[1], id: user.tournament.id}.to_json
						@connections.each do |k, v|
							to_user = @user_manager.get_user(v.user_id)
							if (to_user && to_user.id != user.id && to_user.tournament == nil)
								k.send(to_all)
							end
						end
					else
						ws.send({type: "ChatMessageError", error:"GameNotFound", message: "Cannot create #{split_msg[1]} tournament, game not found"}.to_json)
					end
					return
				when "profile"
					if split_msg.size < 2
						ws.send({type: "ChatMessageError", error:"ProfileFormatError", message: "No display name provided"}.to_json)
						return
					end
					if @user_manager.get_user_info(split_msg[1]) != nil
						ws.send({type: "ViewProfile", name: split_msg[1]}.to_json)
					else
						ws.send({type: "ChatMessageError", error:"ProfileNotFound", message: "Could not find user with display name #{split_msg[1]}"}.to_json)
					end
					return
				else
					ws.send({type: "ChatMessageError", error:"CommandNotFound", message: "Command \'#{split_msg[0]}\' not found: /help to see commands"}.to_json)
				end
				return
			end

			#TODO: check if client is in game and send to partner game websocket

			# Save the message to the database
			puts "creating chat message from #{msg_data["sender"]}"
			ChatMessage.create(sender_id: sender_id, content: msg_data["content"])

			# Broadcast the message to all clients (including the sender)
			
			@connections.each { |client_ws, client|
				if !user.blocked?(client.user_id) && @user_manager.user?(client.user_id) && !@user_manager.get_user(client.user_id).blocked?(user.id)
					you = false
					if client.user_id == user.id
						you = true
					end
					client_ws.send({type: "ChatMessage", message: msg_data, you: you}.to_json)
				end
			}
		when "get_leaderboard"
			ws.send({type: "GetLeaderboard", data: @user_manager.get_leaderboard()}.to_json)
		when "get_alerts"
			@alert_manager.send_client_alerts(client)
		when "get_chat_history"
			begin
				chat_history = user.get_chat_history(@db)
				ret_chat_history = []
				chat_history.each do |_msg|
					_msg_new = {
						message: {
							sender: @user_manager.get_user_info(_msg['sender_id'].to_i).display_name,
							content: _msg['content'],
							created_at: _msg['created_at']
						},
						you: false
					}
					if _msg['sender_id'] == user.id
						_msg_new[:you] = true
					end
					ret_chat_history.push(_msg_new)
				end
				ws.send({type: "ChatHistory", data: ret_chat_history}.to_json)
			rescue User::Error => e
				ws.send({type: "ChatHistoryError", message: "Error fetching chat history"}.to_json)
			end
		when "get_profile"
			if msg_data["profile"] == nil
				ws.send({type: "GetProfileError", message: "No display name provided"}.to_json)
				return
			end
			profile = nil
			if msg_data["profile"] == "my profile"
				profile = @user_manager.get_profile(user.display_name, user)
			else
				profile = @user_manager.get_profile(msg_data["profile"], user)
			end
			if profile == nil
				ws.send({type: "GetProfileError", message: "Could not find user #{msg_data["profile"]}"}.to_json)
				return
			end
			if profile[:display_name] == user.display_name
				profile[:you] = true
			end
			friends = []
			profile[:friends].each do |friend|
				new_friend = {
					name: @user_manager.get_user_info(friend).display_name,
					online: false
				}
				@connections.each_value do |c|
					if c.user_id == friend
						new_friend[:online] = true
						break
					end
				end
				friends.push(new_friend)
			end
			profile[:friends] = friends
			@connections.each_value do |c|
				if c.user_id == profile[:id]
					profile[:online] = true
					break
				end
			end
			if @alert_manager.pending_friend(user, @user_manager.get_user_info(profile[:display_name]))
				profile[:pending_friend] = true
			end
			puts "final profile"
			puts profile
			ws.send({type: "Profile", data: profile}.to_json)
		when "block_user"
			begin
				b_user = nil
				if msg_data["id"] != nil
					b_user = @user_manager.get_user_info(msg_data["id"])
					if b_user == nil
						ws.send({type: "BlockError", message: "Couldn't find user with id #{msg_data["id"]}"}.to_json)
					elsif user.blocked?(b_user.id)
						ws.send({type: "BlockReply", message: "User #{b_user.display_name} is already blocked"}.to_json)
					else
						user.block_user(b_user.id, @db)
						user.unfriend_user(b_user.id, @db)
						if @user_manager.user?(b_user.id)
							@user_manager.get_user(b_user.id).unfriend_user(user.id, @db)
						else
							b_user.unfriend_user(user.id, @db)
						end
						ws.send({type: "BlockReply", message: "User #{b_user.display_name} has been blocked"}.to_json)
					end
					return
				elsif msg_data["name"] != nil
					b_user = @user_manager.get_user_info(msg_data["name"])
					if b_user == nil
						ws.send({type: "BlockError", message: "Couldn't find user with display name #{msg_data["name"]}"}.to_json)
					elsif user.blocked?(b_user.id)
						ws.send({type: "BlockReply", message: "User #{b_user.display_name} is already blocked"}.to_json)
					else
						user.block_user(b_user.id, @db)
						user.unfriend_user(b_user.id, @db)
						if @user_manager.user?(b_user.id)
							@user_manager.get_user(b_user.id).unfriend_user(user.id, @db)
						else
							b_user.unfriend_user(user.id, @db)
						end
						ws.send({type: "BlockReply", message: "User #{b_user.display_name} has been blocked"}.to_json)
					end
					return
				else
					ws.send({type: "BlockError", message: "Error blocking user"}.to_json)
				end
			rescue User::Error
				ws.send({type: "BlockError", message: "Error blocking user"}.to_json)
			end
		when "unblock_user"
			begin
				b_user = nil
				if msg_data["id"] != nil
					b_user = @user_manager.get_user_info(msg_data["id"])
					if b_user == nil
						ws.send({type: "UnblockError", message: "Couldn't find user with id #{msg_data["id"]}"}.to_json)
						return
					end
					if !user.blocked?(b_user.id)
						ws.send({type: "UnblockReply", message: "User #{b_user.display_name} is not blocked"}.to_json)
					else
						user.block_user(b_user.id, @db)
						ws.send({type: "UnblockReply", message: "User #{b_user.display_name} has been blocked"}.to_json)
					end
					return
				elsif msg_data["name"] != nil
					b_user = @user_manager.get_user_info(msg_data["name"])
					if b_user == nil
						ws.send({type: "UnblockError", message: "Couldn't find user with display name #{msg_data["name"]}"}.to_json)
						return
					end
					if !user.blocked?(b_user.id)
						ws.send({type: "UnblockReply", message: "User #{b_user.display_name} is not blocked"}.to_json)
					else
						user.unblock_user(b_user.id, @db)
						ws.send({type: "UnblockReply", message: "User #{b_user.display_name} has been unblocked"}.to_json)
					end
				else
					ws.send({type: "UnblockError", message: "Error unblocking user"}.to_json)
				end
			rescue User::Error
				ws.send({type: "UnblockError", message: "Error unblocking user"}.to_json)
			end
		when "friend_user"
			begin
				f_user = nil
				if msg_data["id"] != nil
					f_user = @user_manager.get_user_info(msg_data["id"])
					if f_user == nil
						ws.send({type: "FriendError", message: "Couldn't find user with id #{msg_data["id"]}"}.to_json)
					elsif user.friend?(f_user.id)
						ws.send({type: "FriendReply", message: "User #{f_user.display_name} is already your friend"}.to_json)
					else
						@alert_manager.create_friend(user, f_user)
						ws.send({type: "FriendReply", message: "User #{f_user.display_name} friend request sent"}.to_json)
					end
					return
				elsif msg_data["name"] != nil
					f_user = @user_manager.get_user_info(msg_data["name"])
					if f_user == nil
						ws.send({type: "FriendError", message: "Couldn't find user with display name #{msg_data["name"]}"}.to_json)
					elsif user.friend?(f_user.id)
						ws.send({type: "FriendReply", message: "User #{f_user.display_name} is already your friend"}.to_json)
					else
						@alert_manager.create_friend(user, f_user)
						ws.send({type: "FriendReply", message: "User #{f_user.display_name} friend request sent"}.to_json)
					end
					return
				else
					ws.send({type: "FriendError", message: "Error adding friend"}.to_json)
				end
			rescue User::Error
				ws.send({type: "FriendError", message: "Error adding friend"}.to_json)
			end
		when "unfriend_user"
			begin
				f_user = nil
				if msg_data["id"] != nil
					f_user = @user_manager.get_user_info(msg_data["id"])
					if f_user == nil
						ws.send({type: "UnfriendError", message: "Couldn't find user with id #{msg_data["id"]}"}.to_json)
						return
					end
					if !user.friend?(f_user.id)
						ws.send({type: "UnfriendReply", message: "User #{f_user.display_name} is not your friend"}.to_json)
					else
						user.unfriend_user(f_user.id, @db)
						if @user_manager.user?(f_user.id)
							@user_manager.get_user(f_user.id).unfriend_user(user.id, @db)
						else
							f_user.unfriend_user(user.id, @db)
						end
						ws.send({type: "UnfriendReply", message: "User #{f_user.display_name} is no longer your friend"}.to_json)
					end
					return
				elsif msg_data["name"] != nil
					f_user = @user_manager.get_user_info(msg_data["name"])
					if f_user == nil
						ws.send({type: "UnfriendError", message: "Couldn't find user with display name #{msg_data["name"]}"}.to_json)
						return
					end
					if !user.friend?(f_user.id)
						ws.send({type: "UnfriendReply", message: "User #{f_user.display_name} is not your friend"}.to_json)
					else
						user.unfriend_user(f_user.id, @db)
						if @user_manager.user?(f_user.id)
							@user_manager.get_user(f_user.id).unfriend_user(user.id, @db)
						else
							f_user.unfriend_user(user.id, @db)
						end
						ws.send({type: "UnfriendReply", message: "User #{f_user.display_name} is no longer your friend"}.to_json)
					end
				else
					ws.send({type: "UnfriendError", message: "Error unfriending user"}.to_json)
				end
			rescue User::Error
				ws.send({type: "UnfriendError", message: "Error unfriending user"}.to_json)
			end
		when "accept_friend"
			if msg["name"] == nil
				ws.send({type: "AcceptFriendError", message: "No display name provided"}.to_json)
				return
			end
			f_user = @user_manager.get_user_from_display_name(msg_data["name"])
			if f_user == nil
				f_user = @user_manager.get_user_info(msg_data["name"])
			end
			if f_user == nil
				ws.send({type: "AcceptFriendError", message: "Could not user #{msg["name"]}"}.to_json)
				return
			end
			begin
				if @alert_manager.accept_friend(user, f_user)
					ws.send({type: "AcceptFriendReply", message: "User #{msg["name"]} is now your friend"}.to_json)
				else
					ws.send({type: "AcceptFriendError", message: "Could not find friend request from #{msg["name"]}"}.to_json)
				end
			return
			rescue User::Error
				ws.send({type: "AcceptFriendError", message: "Internal"}.to_json)
			end
		when "accept_invite"
			if msg_data["user_from"] == nil
				ws.send({type: "ChatMessageError", error: "NoUser", message: "No user provided to accept invite"}.to_json)
				return
			end
			user_from = @user_manager.get_user_from_display_name(msg_data["user_from"])
			if !user_from
				ws.send({type: "ChatMessageError", error: "UserNotFound", message: "Could not find user #{msg_data["user_from"]}"}.to_json)
				return
			end
			@alert_manager.accept_invite(user, user_from)
		when "leave_tournament"
			@alert_manager.leave_tournament(user)
			return
		when "get_game_status"
			if user.tournament != nil && msg_data["game"] == user.tournament.game
				user.tournament.handle_status(user)
				return
			else
				@alert_manager.handle_status(user)
				return
			end
		when "get_tournament_info"
			if user.tournament == nil
				ws.send({type: "NoTournament"}.to_json)
			else
				t_info = user.tournament.get_tournament_info(user)
				#if user.tournament.match_ready?(user)
				#	t_info[:in_game] = true
				#else
				#	t_info[:in_game] = false
				#end
				ws.send({type: "game_status", data: t_info, info: true}.to_json)
			end
		when "join_tournament_id"
			if user.tournament != nil
				ws.send({type: "ChatMessageError", error: "AlreadyInTournament", message: "You are already in a tournament"}.to_json);
				return
			end
			if @alert_manager.join_tournament_by_id(user, msg_data["id"])
				ws.send({type: "JoinTournamentSuccess"}.to_json)
			else
				ws.send({type: "ChatMessageError", error: "TournamentUnavailable", message: "Tournament unavailable"}.to_json)
			end
			return
		when "change_settings"
			begin
				if msg_data["password"] == nil
					ws.send({type: "ChangeSettingsError", message: "no password provided"}.to_json)
				end
				if msg_data["display_name"] == nil && msg_data["new_password"] == nil && 
					msg_data["username"] == nil && msg_data["profile_picture"] == nil
					ws.send({type: "ChangeSettingsError", message: "No settings provided"}.to_json)
					return
				end
				user.verify_password(msg_data["password"])
				if msg_data["display_name"] != nil
					user.change_display_name(msg_data["display_name"], @db)
				end
				if msg_data["new_password"] != nil
					user.change_password(msg_data["new_password"], @db)
				end
				if msg_data["username"] != nil
					user.change_username(msg_data["username"], @db)
				end
				if msg_data["profile_picture"] != nil
					user.change_profile_picture(msg_data["profile_picture"], @db)
				end
				ws.send({type: "ChangeSettingsSuccess"}.to_json)
			rescue User::Error => e
				ws.send({type: "ChangeSettingsError", message: e.message}.to_json)
			end
		when "get_profile_picture"
			begin
				if msg_data["display_name"] == nil || msg_data["timestamp"] == nil
					ws.send({type: "GetProfilePictureError", message: "No display_name or timestamp provided"}.to_json)
					return
				end
				if msg_data["display_name"] == "my profile"
					picture = user.get_profile_picture(msg_data["timestamp"], @db);
					picture[:name] = "my profile"
					ws.send({type: "ProfilePicture", data: picture}.to_json)
				else
					profile_user = @user_manager.get_user_info(msg_data["display_name"])
					if !profile_user
						ws.send({type: "GetProfilePictureError", message: "Cannot find user #{msg_data["display_name"]}"}.to_json)
						return
					end
					ws.send({type: "ProfilePicture", data: profile_user.get_profile_picture(msg_data["timestamp"], @db)}.to_json)
				end
				return
			rescue User::Error
				puts "Get profile picture error"
				return
			end
		end
		rescue JSON::ParserError => e
			puts "Error parsing JSON: #{e.message}"
		end
	end

	def handle_close(ws, code, reason)
		client = @connections[ws]
		user = @user_manager.get_user(client.user_id)
		if (client.in_game && client.partner != nil)
			partner = @connections[client.partner]
			if (partner != nil)
				partner.game = nil
				partner.in_game = false
				puts "client disconnected"
				client.partner.send({type: "partner_disconnected"}.to_json)
				if user.tournament_ws == ws
					winner_user = @user_manager.get_user(partner.user_id)
					loser_user = user
					loser_user.tournament.match_finished(winner_user, loser_user)
					@user_manager.save_match(client.game_selected, winner_user.id, loser_user.id, "tournament")
				elsif user.invite_ws == ws
					@user_manager.save_match(client.game_selected, partner.user_id, client.user_id, "friendly")
				else
					@user_manager.save_match(client.game_selected, partner.user_id, client.user_id, "casual")
				end
			end
		end
		if user != nil && user.tournament_ws == ws
			user.tournament_ws = nil
		elsif user != nil && user.invite_ws == ws
			user.invite_ws = nil
		end
		puts "WebSocket connection closed"
    	@connections.delete(ws)
		#@connections.each_value do |other_client|
		#	if client.user_id == other_client.user_id
		#		return
		#	end
		#end
		#@user_manager.delete_user(client.user_id)
	end

	def find_partner(ws, game)
		client = @connections[ws]
		@connections.each {|partner_ws, partner|
			if partner_ws == ws
				next
			end
			partner = @connections[partner_ws]
			if partner.game_selected == game && partner.matchmaking && !partner.in_game && partner.user_id != client.user_id
				return partner_ws
			end
		}
		return nil
	end
	
	def start_game(player1_ws, player2_ws, game_name)
		puts "starting game #{game_name}"
		player1 = @connections[player1_ws]
		player2 = @connections[player2_ws]
	
		player1.id = 0
		player1.matchmaking = false
		player1.in_game = true
		player1.game_selected = game_name
		player1.partner = player2_ws
	
		player2.id = 1
		player2.matchmaking = false
		player2.in_game = true
		player2.game_selected = game_name
		player2.partner = player1_ws
	
		if game_name == "pong"
			player1.game = PongGame.new
			player2.game = @connections[player1_ws].game
			timer = EM.add_periodic_timer(0.04) {game_loop(player1_ws, timer)}
		elsif game_name == "snake"
			player1.game = SnakeGame.new
			player2.game = @connections[player1_ws].game
			timer = EM.add_periodic_timer(0.1) {game_loop(player1_ws, timer)}
		end
		player1_ws.send({type: "game_found", data: {player_id: player1.id, game: game_name, opponent: @user_manager.get_user(player2.user_id).display_name}}.to_json);
		player2_ws.send({type: "game_found", data: {player_id: player2.id, game: game_name, opponent: @user_manager.get_user(player1.user_id).display_name}}.to_json);
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
		if game.state_as_json[:winner] != nil && game.state_as_json[:winner] > -1
			puts "match finished"
			player_user = @user_manager.get_user(player.user_id)
			winner_id = player.user_id
			loser_id = partner.user_id
			if game.state_as_json[:winner] != player.id
				winner_id = partner.user_id
				loser_id = player.user_id
			end
			if player_ws == player_user.tournament_ws
				winner_user = @user_manager.get_user(winner_id)
				loser_user = @user_manager.get_user(loser_id)
				player_user.tournament.match_finished(winner_user, loser_user)
				@user_manager.save_match(player.game_selected, winner_id, loser_id, "tournament")
			elsif player_ws == player_user.invite_ws
				player_user.invite_ws = nil
				@user_manager.get_user(partner.user_id).invite_ws = nil
				@user_manager.save_match(player.game_selected, winner_id, loser_id, "friendly")
			else
				@user_manager.save_match(player.game_selected, winner_id, loser_id, "casual")
			end
			player.in_game = false
			player.game = nil
			partner.in_game = false
			partner.game = nil
			timer.cancel
		end
	end
end