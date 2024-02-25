require 'pg'
require 'bcrypt'

class User
	attr_accessor :id, :username, :password

	def initialize(id:, username:, password:)
		@id = id
		@username = username
		@password = password
	end

	class Error < StandardError
	end
	class UsernameTaken < Error
		def initialize(message = "Username taken")
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

	def self.register(username, password, db)

		if password.size < 8
			puts "Password too short"
			raise PasswordTooShort
		end

		encrypted_password = BCrypt::Password.create(password)
		begin
		result = db.exec_params(
			'INSERT INTO users (username, password) VALUES ($1, $2) RETURNING id',
			[username, encrypted_password]
		)

		new(
			id: result[0]['id'],
			username: username,
			password: encrypted_password
		)
		rescue PG::UniqueViolation
			puts "Username already in use"
			raise UsernameTaken
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
		new(
			id: result[0]['id'],
			username: result[0]['username'],
			password: result[0]['password']
		)
		rescue PG::Error => e
			puts "An error occured while querying db: #{e.message}"
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
		new(
			id: result[0]['id'],
			username: result[0]['username'],
			password: result[0]['password']
		)
		rescue PG::Error => e
			puts "An error occured while querying db: #{e.message}"
			raise DatabaseError
		end
	end
end
