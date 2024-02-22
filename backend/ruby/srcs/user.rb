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

	def self.create(username, password, db)

		if password.size < 8
			puts "Password too short"
			return err("PasswordTooShort")
		end

		encrypted_password = BCrypt::Password.create(password)
		puts username
		puts password
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
			err("UsernameInUse")
		rescue PG::Error => e
			puts "An error occured while inserting into db: #{e.message}"
			err("Unknown")
		end
	end
end
