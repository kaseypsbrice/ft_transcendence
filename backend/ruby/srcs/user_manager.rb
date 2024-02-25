require 'em-websocket'
require 'json'
require 'jwt'
require 'openssl'
require_relative 'user'

class UserManager
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

	def save_match(game, player1_id, player2_id, winner, info)
		begin
			@db.exec_params(
			'INSERT INTO matches (game, player1, player2, winner, info) VALUES ($1, $2, $3, $4, $5)',
			[game, player1_id, player2_id, winner, info]
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
end