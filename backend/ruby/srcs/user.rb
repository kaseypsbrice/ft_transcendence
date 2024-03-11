require 'pg'
require 'bcrypt'

class User
	attr_accessor :id, :username, :password, :display_name, :tournament, :current_ws, :tournament_ws, :blocked, :invite_ws, :friends, 
	:pong_wins, :pong_losses, :snake_wins, :snake_losses, :pong_tournament_wins, :snake_tournament_wins

	MAX_USERNAME = 50
	MAX_DISPLAY_NAME = 30

	def initialize(id:, username:, password:, display_name:, friends:, blocked:,\
		pong_wins:, pong_losses:, snake_wins:, snake_losses:, pong_tournament_wins:,\
		snake_tournament_wins:)
		@id = id
		@username = username
		@password = password
		@display_name = display_name
		@friends = friends || []
		@blocked = blocked || []
		@pong_wins = pong_wins
		@pong_losses = pong_losses
		@snake_wins = snake_wins
		@snake_losses = snake_losses
		@pong_tournament_wins = pong_tournament_wins
		@snake_tournament_wins = snake_tournament_wins
		@tournament = nil
		@tournament_ws = nil
		@invite_ws = nil
		@current_ws = nil
	end

	class Error < StandardError
	end
	class UsernameTaken < Error
		def initialize(message = "Username taken")
			super(message)
		end
	end

	class UsernameTooLong < Error
		def initialize(message = "Username too long")
			super(message)
		end
	end

	class DisplayNameTaken < Error
		def initialize(message = "Display name taken")
			super(message)
		end
	end

	class DisplayNameTooLong < Error
		def initialize(message = "Display name too long")
			super(message)
		end
	end

	class DisplayNameInvalid < Error
		def initialize(message = "Display name invalid")
			super(message)
		end
	end

	class UserNotFound < Error
		def initialize(message = "User not found")
			super(message)
		end
	end

	class PasswordIncorrect < Error
		def initialize(message = "Password incorrect")
			super(message)
		end
	end

	class PasswordTooShort < Error
		def initialize(message = "Password too short")
			super(message)
		end
	end

	class DatabaseError < Error
		def initialize(message = "Internal error")
			super(message)
		end
	end

	def self.from_db_query(result)
		_blocked_values = []
		_friends_values = []
		if result[0]['blocked'] != nil
			_blocked_values = result[0]['blocked'].scan(/\d+/)
		end
		if result[0]['friends'] != nil
			_friends_values = result[0]['friends'].scan(/\d+/)
		end
		new(
			id: result[0]['id'].to_i,
			username: result[0]['username'],
			password: result[0]['password'],
			display_name: result[0]['display_name'],
			friends: _friends_values.map(&:to_i),
			blocked: _blocked_values.map(&:to_i),
			snake_wins: result[0]['snake_wins'].to_i,
			snake_losses: result[0]['snake_losses'].to_i,
			pong_wins: result[0]['pong_wins'].to_i,
			pong_losses: result[0]['pong_losses'].to_i,
			snake_tournament_wins: result[0]['snake_tournament_wins'].to_i,
			pong_tournament_wins: result[0]['pong_tournament_wins'].to_i
		)
	end

	def self.register(username, password, display_name, db)

		if password.size < 8
			puts "Password too short"
			raise PasswordTooShort
		end

		if username.size >= MAX_USERNAME
			puts "Username too long"
			raise UsernameTooLong
		end

		if display_name.size >= MAX_DISPLAY_NAME
			puts "Display name too long"
			raise DisplayNameTooLong
		end

		if display_name.include?(" ")
			puts "Display name invalid"
			raise DisplayNameInvalid
		end

		encrypted_password = BCrypt::Password.create(password)
		begin
		result = db.exec_params(
			'INSERT INTO users (username, password, display_name) VALUES ($1, $2, $3) RETURNING id',
			[username, encrypted_password, display_name]
		)

		return from_db_query(result)
		rescue PG::UniqueViolation => e
			if e.message.include?("(username)=")
				puts "Username taken"
				raise UsernameTaken
			else
				puts "Display Name taken"
				raise DisplayNameTaken
			end
		rescue PG::Error => e
			puts "An error occured while inserting into db: #{e.message}"
			raise DatabaseError
		end
	end

	def self.login(username, password, db)
		begin
		result = db.exec_params(
			'SELECT * FROM users
			WHERE username=$1',
			[username]
		)
		if result.num_tuples < 1
			puts "Could not find user in database"
			raise UserNotFound
		end
		encrypted_password = BCrypt::Password.new(result[0]['password'])
		if encrypted_password != password
			puts "Incorrect password"
			raise PasswordIncorrect
		end
		return from_db_query(result)
		rescue PG::Error => e
			puts "An error occured while querying users: #{e.message}"
			raise DatabaseError
		end
	end

	def verify_password(password)
		encrypted_password = BCrypt::Password.new(@password)
		if encrypted_password != password
			raise PasswordIncorrect
		end
	end

	def change_display_name(new_display_name, db)
		if display_name.size >= MAX_DISPLAY_NAME
			puts "Display name too long"
			raise DisplayNameTooLong
		end

		if display_name.include?(" ")
			puts "Display name invalid"
			raise DisplayNameInvalid
		end

		begin
			db.exec_params(
				'UPDATE users
				SET display_name=$1
				WHERE id=$2;',
				[new_display_name, @id]
			)
			@display_name = new_display_name
		rescue PG::UniqueViolation => e
			puts "Display Name taken"
			raise DisplayNameTaken
		rescue PG::Error => e
			puts "An error occured while inserting into db: #{e.message}"
			raise DatabaseError
		end
	end

	def change_username(new_username, db)
		if new_username.size >= MAX_USERNAME
			puts "Username too long"
			raise UsernameTooLong
		end

		begin
			db.exec_params(
				'UPDATE users
				SET username=$1
				WHERE id=$2;',
				[new_username, @id]
			)
			@username = new_username
		rescue PG::UniqueViolation => e
			puts "Username taken"
			raise UsernameTaken
		rescue PG::Error => e
			puts "An error occured while inserting into db: #{e.message}"
			raise DatabaseError
		end
	end

	def change_password(new_password, db)
		if new_password.size < 8
			puts "Password too short"
			raise PasswordTooShort
		end
		encrypted_password = BCrypt::Password.create(new_password)

		begin
			db.exec_params(
				'UPDATE users
				SET password=$1
				WHERE id=$2',
				[encrypted_password, @id]
			)
			@password = encrypted_password
		rescue PG::Error => e
			puts "An error occured while changing password #{e.message}"
			raise User::DatabaseError
		end
	end

	def change_profile_picture(new_profile_picture, db)
		#TODO: this
	end

	def self.from_id(id, db)
		begin
		result = db.exec_params(
			'SELECT * FROM users
			WHERE id=$1',
			[id]
		)
		if result.num_tuples < 1
			puts "Could not find user in database"
			raise UserNotFound
		end
		from_db_query(result)
		rescue PG::Error => e
			puts "An error occured while querying users: #{e.message}"
			raise DatabaseError
		end
	end

	def self.from_display_name(display_name, db)
		begin
		result = db.exec_params(
			'SELECT * FROM users
			WHERE display_name=$1',
			[display_name]
		)
		if result.num_tuples < 1
			puts "Could not find user in database"
			raise UserNotFound
		end
		from_db_query(result)
		rescue PG::Error => e
			puts "An error occured while querying users: #{e.message}"
			raise DatabaseError
		end
	end

	def get_chat_history(db)
		begin
			puts "blocked #{@blocked} #{@blocked.size}"
			result = []
			if @blocked.size > 0
				result =  db.exec(
					'SELECT * FROM chat_messages
					WHERE sender_id NOT IN (' + @blocked.join(',') + ')
					ORDER BY created_at DESC
					LIMIT 50;'
				)
			else
				result = db.exec(
					'SELECT * FROM chat_messages
					ORDER BY created_at DESC
					LIMIT 50;'
				)
			end
			return result
		rescue PG::Error => e
			puts "An error occured while querying chat history: #{e.message}"
			raise DatabaseError
		end
	end

	def get_match_history(db)
		begin
			result = db.exec_params(
				'SELECT * FROM matches
				WHERE winner=$1 OR loser=$1
				ORDER BY time DESC
				LIMIT 50;',
				[@id]
			)
			ret = []
			result.each do |match|
				winner_id = match["winner"]
				loser_id = match["loser"]
				winner_lookup = db.exec_params(
					'SELECT display_name FROM users
					WHERE id=$1',
					[winner_id]
				)
				loser_lookup = db.exec_params(
					'SELECT display_name FROM users
					WHERE id=$1',
					[loser_id]
				)
				match["winner"] = winner_lookup[0]['display_name']
				match["loser"] = loser_lookup[0]['display_name']
				puts match
				ret.push(match)
			end
			return ret
		rescue PG::Error => e
			puts "An error occured while querying matches: #{e.message}"
			raise DatabaseError
		end
	end

	def blocked?(id)
		if @blocked.include?(id)
			return true
		end
		return false
	end

	def block_user(id, db)
		if blocked?(id)
			return
		end
		begin
			db.exec_params(
				'UPDATE users
				SET blocked = array_append(blocked, $1)
				WHERE id=$2;',
				[id, @id]
			)
			blocked.push(id)
		rescue PG::Error => e
			puts "An error occured while blocking user: #{e.message}"
			raise DatabaseError
		end
	end

	def unblock_user(id, db)
		if !blocked?(id)
			return
		end
		begin
			db.exec_params(
				'UPDATE users
				SET blocked = array_remove(blocked, $1)
				WHERE id=$2;',
				[id, @id]
			)
			blocked.delete(id)
		rescue PG::Error => e
			puts "An error occured while unblocking user: #{e.message}"
			raise DatabaseError
		end
	end

	def friend?(id)
		if @friends.include?(id)
			return true
		end
		return false
	end

	def friend_user(id, db)
		if friend?(id)
			return
		end
		begin
			db.exec_params(
				'UPDATE users
				SET friends = array_append(friends, $1)
				WHERE id=$2;',
				[id, @id]
			)
			friends.push(id)
		rescue PG::Error => e
			puts "An error occured while friending user: #{e.message}"
			raise DatabaseError
		end
	end

	def unfriend_user(id, db)
		if !friend?(id)
			return
		end
		begin
			db.exec_params(
				'UPDATE users
				SET friends = array_remove(friends, $1)
				WHERE id=$2;',
				[id, @id]
			)
			friends.delete(id)
		rescue PG::Error => e
			puts "An error occured while unfriending user: #{e.message}"
			raise DatabaseError
		end
	end

	def add_tournament_win(game, db)
		begin
			if (game != "pong" && game != "snake")
				return
			end
			db.exec_params(
				"UPDATE users
				SET #{game}_tournament_wins = #{game}_tournament_wins + 1
				WHERE id=$1",
				[@id]
			)
		rescue PG::Error => e
			puts "An error occured while adding tournament win #{game}: #{e.message}"
		end
	end
end
