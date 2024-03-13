require 'pg'
require 'bcrypt'

class User
	attr_accessor :id, :username, :password, :display_name, :tournament, :current_ws, :tournament_ws, :blocked, :invite_ws, :friends, 
	:pong_wins, :pong_losses, :snake_wins, :snake_losses, :pong_tournament_wins, :snake_tournament_wins, :profile_picture_timestamp

	MAX_USERNAME = 50
	MAX_DISPLAY_NAME = 30

	def initialize(id:, username:, password:, display_name:, friends:, blocked:,\
		pong_wins:, pong_losses:, snake_wins:, snake_losses:, pong_tournament_wins:,\
		snake_tournament_wins:, profile_picture_timestamp:)
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
		@profile_picture_timestamp = profile_picture_timestamp
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

	def self.from_db_query(result, timestamp)
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
			pong_tournament_wins: result[0]['pong_tournament_wins'].to_i,
			profile_picture_timestamp: timestamp
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
			'INSERT INTO users (username, password, display_name) VALUES ($1, $2, $3)
			RETURNING *;',
			[username, encrypted_password, display_name]
		)
		_result = db.exec_params(
			'SELECT timestamp FROM profile_pictures
			WHERE id=$1',
			[result[0]['id']]
		)
		timestamp = "none"
		if _result.num_tuples > 0
			timestamp = _result[0]['timestamp']
		end

		return from_db_query(result, timestamp)
		rescue PG::UniqueViolation => e
			puts e.message
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
		_result = db.exec_params(
			'SELECT timestamp FROM profile_pictures
			WHERE id=$1',
			[result[0]['id']]
		)
		timestamp = "none"
		if _result.num_tuples > 0
			timestamp = _result[0]['timestamp']
		end
		return from_db_query(result, timestamp)
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

	def add_game_loss(game db)
		begin
			@db.exec_params(
			"UPDATE users
			SET #{game}_losses = #{game}_losses + 1
			WHERE id = $1",
			[@id]
		)
		if game == "snake"
			@snake_losses += 1
		else
			@pong_losses += 1
		end
		rescue PG::Error
			return
		end
	end

	def add_game_win(game db)
		begin
			@db.exec_params(
			"UPDATE users
			SET #{game}_wins = #{game}_wins + 1
			WHERE id = $1",
			[@id]
		)
		if game == "snake"
			@snake_wins += 1
		else
			@pong_wins += 1
		end
		rescue PG::Error
			return
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
		begin
			result = db.exec_params(
				'UPDATE profile_pictures
				SET image=$1, timestamp=CURRENT_TIMESTAMP
				WHERE id=$2
				RETURNING timestamp;',
				[new_profile_picture, @id]
			)
			if (result.num_tuples == 0)
				_result = db.exec_params(
					'INSERT INTO profile_pictures (id, image) VALUES ($1, $2)
					RETURNING timestamp;',
					[@id, new_profile_picture]
				)
				@profile_picture_timestamp = _result[0]['timestamp']
			else
				@profile_picture_timestamp = result[0]['timestamp']
			end
		rescue PG::Error => e
			puts "An error occured while inserting into db: #{e.message}"
			raise DatabaseError
		end
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
		_result = db.exec_params(
			'SELECT timestamp FROM profile_pictures
			WHERE id=$1',
			[result[0]['id']]
		)
		timestamp = "none"
		if _result.num_tuples > 0
			timestamp = _result[0]['timestamp']
		end
		from_db_query(result, timestamp)
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
		_result = db.exec_params(
			'SELECT timestamp FROM profile_pictures
			WHERE id=$1',
			[result[0]['id']]
		)
		timestamp = "none"
		if _result.num_tuples > 0
			timestamp = _result[0]['timestamp']
		end
		from_db_query(result, timestamp)
		rescue PG::Error => e
			puts "An error occured while querying users: #{e.message}"
			raise DatabaseError
		end
	end

	def get_profile_picture(timestamp, db)
		begin
			if (timestamp == @profile_picture_timestamp)
				return {name: @display_name, current: true}
			end
			result = db.exec_params(
				'SELECT * FROM profile_pictures
				WHERE id=$1;',
				[@id]
			)
			if result.num_tuples == 0
				return {image: "data:image/png;base64,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","token":"eyJhbGciOiJSUzI1NiJ9.eyJkYXRhIjp7InVzZXJuYW1lIjoiMSIsImlkIjoxfSwiZXhwIjoxNzEwMTY0NzYwfQ.C7VBrE5gJCR9tu0oBNJHv7qO6biMamA35hL1yii6sodhRf8z4WJbrB4SYmch-0yDLWG9u6KZ-AWAgYlw_-Rmx1pcMG2D21c15IZ8clmtkjbJdRGSv7N9gCGYoF7ItgNTiS6p9RwwFQ5bCjNmWE3UGKzPkbGCnxSgde1GERrynRR74Ykcp0qwF5OTKSNKrGt6huQH5U-VeKcur5iN4UryEwlKocdvmOUIpK-3ibnmzd1l-ppE3sSL061mkKCG1CWZIjlDDo-3JZDxt9A-knfmISmMv2s7-UrqCpHoGX1Lt0CuEnjO9Fvosvb3G7Py0xmpjm2VkgJPTAuVENsFcg3RoA", name: @display_name, timestamp: @profile_picture_timestamp}
			else
				return {image: result[0]['image'], name: @display_name, timestamp: @profile_picture_timestamp}
			end
		rescue PG::Error => e
			puts "An error occured while fetching profile picture #{e.message}"
			raise DatabaseError
		end
	end

	def get_chat_history(db)
		begin
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
			@blocked.push(id)
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
			@blocked.delete(id)
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
			@friends.push(id)
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
			@friends.delete(id)
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
			if game == "pong"
				@pong_tournament_wins += 1
			else
				@snake_tournament_wins += 1
			end
		rescue PG::Error => e
			puts "An error occured while adding tournament win #{game}: #{e.message}"
		end
	end
end
