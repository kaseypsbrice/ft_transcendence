require 'em-websocket'
require 'eventmachine'
require 'json'
require 'pg'
require_relative 'websocket_manager'

$stdout.sync = true

Signal.trap("INT") do
	puts "Shutting down server..."
	EM.stop if EM.reactor_running?
  	exit
end

EM.run do
	manager = WebSocketManager.new

	EM::WebSocket.run(:host => '0.0.0.0', :port => 8080, :secure => true, :tls_options => {
		:private_key_file => "/var/ssl/pong.key",
		:cert_chain_file => "/var/ssl/pong.crt",
		:verify_peer => false
  	}) do |ws|
		ws.onopen { |handshake| manager.handle_open(ws, handshake) }
		ws.onmessage { |msg| manager.handle_message(ws, msg) }
		ws.onclose { |code, reason| manager.handle_close(ws, code, reason) }
	end
end