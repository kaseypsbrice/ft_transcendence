require 'em-websocket'
require 'json'
require 'jwt'
require 'openssl'
require_relative 'user'

class UserManager
	attr_accessor :users
	
	def initialize (db, rsa_private, rsa_public)
		@users = {}
		@db = db
		@rsa_public = rsa_public
		@rsa_private = rsa_private
	end

	def get_token(payload)
		return JWT.encode(payload, @rsa_private, 'RS256')
	end
	
	def get_auth_token(user)
		payload = {
			data: {
				username: user.username,
				id: user.id
			},
			exp: Time.now.to_i + 3600
		}
		return get_token(payload)
	end
	
	def token_valid?(token)
		begin
			decoded = JWT.decode token, @rsa_public, true, { :algorithm => 'RS256'}
			return true
		rescue JWT::DecodeError
			return false
		end
	end

	def login(client, username, password)
		begin
			user = User.login(username, password, @db)
			client.user_id = user.id
			add_user(user)
			client.ws.send({type: "authentication", token: get_auth_token(user)}.to_json)
		rescue User::UserNotFound => e
			client.ws.send({"type": "LoginError", "message": "User not found"}.to_json);
		rescue User::PasswordIncorrect => e
			client.ws.send({"type": "LoginError", "message": "Password incorrect"}.to_json);
		rescue User::Error => e
			client.ws.send({"type": "LoginError", "message": "Internal"}.to_json);
		end
	end

	def register(client, username, password, display_name)
		begin
			user = User.register(username, password, display_name, @db)
			client.user_id = user.id
			add_user(user)
			client.ws.send({type: "authentication", token: get_auth_token(user)}.to_json)
		rescue User::PasswordTooShort => e
			client.ws.send({"type": "RegisterError", "message": "Password too short"}.to_json);
		rescue User::UsernameTaken => e
			client.ws.send({"type": "RegisterError", "message": "Username taken"}.to_json);
		rescue User::DisplayNameTaken => e
			client.ws.send({"type": "RegisterError", "message": "Display name taken"}.to_json);
		rescue User::UsernameTooLong => e
			client.ws.send({"type": "RegisterError", "message": "Username too long"}.to_json);
		rescue User::DisplayNameTooLong => e
			client.ws.send({"type": "RegisterError", "message": "Display name too long"}.to_json);
		rescue User::DisplayNameInvalid => e
			client.ws.send({"type": "RegisterError", "message": "Display name contains invalid characters"}.to_json);
		rescue User::Error => e
			client.ws.send({"type": "RegisterError", "message": "Internal"}.to_json);
		end
	end

	def get_match_history(client, token)
		begin
			decoded = JWT.decode token, @rsa_public, true, { :algorithm => 'RS256'}
			if decoded.size < 1 || !decoded[0].key?("data") || !decoded[0]["data"].key?("id")
				puts "ERROR: trying to get user history from invalid token, did you forget to use 'token_valid?'"
			else
				user = get_user(decoded[0]["data"]["id"])
				if user == nil
					user = new_user_from_id(client, decoded[0]["data"]["id"])
				end
				return user.get_match_history(@db)
			end
		rescue User::DatabaseError => e
			puts "ERROR: get_match_history: #{e.message}"
			return []
		rescue User::Error => e
			puts "ERROR: get_match_history: could not create new user from token id: #{e.message}"
			return []
		rescue JWT::DecodeError
			puts "ERROR: trying to get user history from invalid token, did you forget to use 'token_valid?'"
			return []
		end
	end

	def get_leaderboard()
		begin
			result = @db.exec(
				'SELECT display_name, pong_wins, snake_wins, pong_losses, snake_losses, \
				pong_tournament_wins, snake_tournament_wins FROM users;'
			)
			result = result.sort_by {|user|
				(user.snake_wins + user.pong_wins) /\
				(user.snake_losses + user.pong_losses)
			}
			return result
		rescue PG::Error
			puts "Error while querying database for leaderboard"
			return []
		end
	end

	def save_match(game, winner_id, loser_id, info)
		begin
			if game != "pong" && game != "snake"
				return
			end
			@db.exec_params(
			'INSERT INTO matches (game, winner, loser, info) VALUES ($1, $2, $3, $4)',
			[game, winner_id, loser_id, info]
		)
		@db.exec_params(
			"UPDATE users
			SET #{game}_wins = #{game}_wins + 1
			WHERE id = $1",
			[winner_id]
		)
		@db.exec_params(
			"UPDATE users
			SET #{game}_losses = #{game}_losses + 1
			WHERE id = $1",
			[loser_id]
		)

		rescue PG::Error => e
			puts "An error occured while saving match: #{e.message}"
		end
	end

	def new_user_from_id(client, id)
		begin
			user = User.from_id(id, @db)
			client.user_id = user.id
			add_user(user)
		rescue User::Error => e
			puts "Could not find user with id #{id}"
			client.ws.send({"type": "InvalidToken"}.to_json);
		end
	end

	def new_user_from_token(client, token)
		begin
			decoded = JWT.decode token, @rsa_public, true, { :algorithm => 'RS256'}
			if decoded.size < 1 || !decoded[0].key?("data") || !decoded[0]["data"].key?("id")
				puts "ERROR: trying to create user from invalid token, did you forget to use 'token_valid?'"
			else
				new_user_from_id(client, decoded[0]["data"]["id"])
			end
		rescue JWT::DecodeError
			puts "ERROR: trying to create user from invalid token, did you forget to use 'token_valid?'"
		end
	end

	def user?(id)
		return @users.key?(id)
	end

	def get_user(id)
		return @users[id]
	end

	def get_user_info(id_or_display) # id or display_name
		begin
			if id_or_display.is_a?(Integer)
				puts "get_user_info integer"
				if user?(id_or_display)
					return get_user(id_or_display)
				end
				return User.from_id(id_or_display, @db)
			else
				puts "get_user_info NOT integer"
				matches = users.select { |k, v| v.display_name == id_or_display }
				if matches.size > 0
					return matches.values[0]
				end
				return User.from_display_name(id_or_display, @db)
			end
		rescue User::Error => e
			return nil
		end
	end

	def get_user_from_display_name(display_name)
		searched = @users.select { |key, value| value.display_name == display_name }
		if searched.size > 0
			return @users[searched.keys[0]]
		end
		return nil
	end

	def add_user(user)
		if !user?(user.id)
			@users[user.id] = user
			puts "User #{user.id} added, new user count #{@users.size}"
		end
	end

	def delete_user(id)
		if user?(id)
			@users.delete(id)
			puts "User #{id} deleted, new user count #{@users.size}"
		end
	end

	def handle_status(invite)

	end

	def get_profile(display_name, user_requesting)
		begin
			user = get_user_info(display_name)
			if !user
				return nil
			end
			profile_data = {
				username: user.username,
				display_name: user.display_name,
				matches: user.get_match_history(@db),
				you: false,
				online: false,
				id: user.id,
				friends: user.friends,
				pong_wins: user.pong_wins,
				pong_losses: user.pong_losses,
				snake_wins: user.snake_wins,
				snake_losses: user.snake_losses,
				pong_tournament_wins: user.pong_tournament_wins,
				snake_tournament_wins: user.snake_tournament_wins,
				is_blocked: user_requesting.blocked?(user.id),
				is_friend: user_requesting.friend?(user.id)
			}
			puts "profile data"
			puts profile_data
			return profile_data
		rescue User::Error
			puts "failed to fetch match history for get_profile"
			return nil
		end
	end
end