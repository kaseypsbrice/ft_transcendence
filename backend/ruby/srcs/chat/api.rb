require 'sinatra'
require 'json'
require 'sinatra/cross_origin'

require_relative 'db_init'
require_relative 'models/chat_message'

register Sinatra::CrossOrigin

configure do
	enable :cross_origin # enable cross_origin
end




# Endpoint for chat history
get '/chat-history' do
	content_type :json
  
	# Fetch messages from the database
	messages = ChatMessage.order(created_at: :asc).limit(50) 
  
	# Convert the message objects to a hash format for JSON response
	messages.map { |message| 
	  {
		id: message.id,
		sender_id: message.sender_id,
		receiver_id: message.receiver_id,
		content: message.content,
		created_at: message.created_at
	  }
	}.to_json
  end


  options "*" do
	response.headers["Allow"] = "GET, POST, OPTIONS"
	response.headers["Access-Control-Allow-Headers"] = "Content-Type"
	response.headers["Access-Control-Allow-Origin"] = "https://127.0.0.1:9001" # remember to change this to the domain of website
	response.headers["Access-Conrtol-Allow-Methods"] = "POST, GET, OPTIONS"
	200
end