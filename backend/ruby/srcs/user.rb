require 'pg'
require 'bcrypt'

class User
	attr_accessor :id, :username, :password, :error

	def initialize(id:, username:, password:, error: nil)
		@id = id
		@username = username
		@password = password
		@error = error
	end

	def self.err(error)
		new(
			id: nil,
			username: nil,
			password: nil,
			error: error
		)
	end

	def self.register(username, password, db)

		if password.size < 8
			puts "Password too short"
			return err("PasswordTooShort")
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
			return err("UsernameInUse")
		rescue PG::Error => e
			puts "An error occured while inserting into db: #{e.message}"
			return err("Unknown")
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
			return err("UserNotFound")
		end
		#puts result[0]['username']
		#puts result[0]['id']
		#puts result[0]['password']
		encrypted_password = BCrypt::Password.new(result[0]['password'])
		#puts encrypted_password == password
		if encrypted_password != password
			puts "Incorrect password"
			return err("PasswordIncorrect")
		end
		new(
			id: result[0]['id'],
			username: result[0]['username'],
			password: result[0]['password']
		)
		rescue PG::Error => e
			puts "An error occured while querying db: #{e.message}"
			return err("Unknown")
		end
	end
end
