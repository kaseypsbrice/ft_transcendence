cd /var/server/chat
rake db:migrate
nohup bundle exec ruby api.rb -o 0.0.0.0 &
ruby /var/server/websocket_server.rb 


