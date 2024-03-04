require 'pg'
require 'bcrypt'

class User
	attr_accessor :id, :username, :password, :display_name

	MAX_USERNAME = 50
	MAX_DISPLAY_NAME = 30

	def initialize(id:, username:, password:, display_name:, friends:, blocked:,\
		pong_wins:, pong_losses:, snake_wins:, snake_losses:, pong_tournament_wins:,\
		snake_tournament_wins:)
		@id = id
		@username = username
		@password = password
		@display_name = display_name
		@friends = friends
		@blocked = blocked
		@pong_wins = pong_wins
		@pong_losses = pong_losses
		@snake_wins = snake_wins
		@snake_losses = snake_losses
		@pong_tournament_wins = pong_tournament_wins
		@snake_tournament_wins = snake_tournament_wins
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
		def initialize(message = "Error accessing database")
			super(message)
		end
	end

	def self.from_db_query(result)
		new(
			id: result[0]['id'],
			username: result[0]['username'],
			password: result[0]['password'],
			display_name: result[0]['display_name'],
			friends: result[0]['friends'],
			blocked: result[0]['blocked'],
			snake_wins: result[0]['snake_wins'],
			snake_losses: result[0]['snake_losses'],
			pong_wins: result[0]['pong_wins'],
			pong_losses: result[0]['pong_losses'],
			snake_tournament_wins: result[0]['snake_tournament_wins'],
			pong_tournament_wins: result[0]['pong_tournament_wins']
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
		#puts result[0]['username']
		#puts result[0]['id']
		#puts result[0]['password']
		encrypted_password = BCrypt::Password.new(result[0]['password'])
		#puts encrypted_password == password
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

	def get_match_history(db)
		begin
		result = db.exec_params(
			'SELECT * FROM matches
			WHERE player1=$1 OR player2=$1',
			[@id]
		)
		ret = []
		result.each do |match|
			player1_id = match["player1"]
			player2_id = match["player2"]
			p1_lookup = db.exec_params(
				'SELECT display_name FROM users
				WHERE id=$1',
				[player1_id]
			)
			p2_lookup = db.exec_params(
				'SELECT display_name FROM users
				WHERE id=$1',
				[player2_id]
			)
			match["player1"] = p1_lookup[0]['display_name']
			match["player2"] = p2_lookup[0]['display_name']
			if match["winner"] == player1_id
				match["winner"] = p1_lookup[0]['display_name']
			else
				match["winner"] = p2_lookup[0]['display_name']
			end
			ret.push(match)
		end
		return ret
		rescue PG::Error => e
			puts "An error occured while querying matches: #{e.message}"
			raise DatabaseError
		end
	end
end
