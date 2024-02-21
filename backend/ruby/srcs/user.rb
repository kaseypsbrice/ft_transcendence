require 'pg'
require 'bcrypt'

class User
	attr_accessor :id, :email, :password, :error

	def initialize(id:, email:, password:, error: nil)
		@id = id
		@email = email
		@password = password
		@error = error
	end

	def self.err(error)
		new(
			id: nil,
			email: nil,
			password: nil,
			error: error
		)
	end

	def self.create(email, password, db)

		if password.size < 8
			puts "Password too short"
			return err("PasswordTooShort")
		end

		encrypted_password = BCrypt::Password.create(password)
		puts email
		puts password
		begin
		result = db.exec_params(
			'INSERT INTO users (email, password) VALUES ($1, $2) RETURNING id',
			[email, encrypted_password]
		)

		new(
			id: result[0]['id'],
			email: email,
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
