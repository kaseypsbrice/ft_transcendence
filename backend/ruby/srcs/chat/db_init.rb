require 'active_record'
require_relative 'models/chat_message'

# Set up database connection
ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'pong',
  username: 'postgres',
  password: 'password',
  host: 'db'
)

# Test the database connection
# begin
#   puts "Testing database connection..."
#   ActiveRecord::Base.connection

#   if ActiveRecord::Base.connected?
#     puts "Successfully connected to the database."
#     puts "Trying to fetch the first chat message..."

#     first_message = ChatMessage.first
#     if first_message
#       puts "First chat message content: #{first_message.content}"
#     else
#       puts "No chat messages found."
#     end
#   else
#     puts "Failed to connect to the database."
#   end
# rescue ActiveRecord::NoDatabaseError => e
#   puts "Database does not exist: #{e.message}"
# rescue ActiveRecord::ActiveRecordError => e
#   puts "Error connecting to the database: #{e.message}"
# end
