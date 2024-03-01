cd /var/server
rake db:create
rake cd:migrate
cd chat && nohup bundle exec ruby api.rb
cd .. && ruby bundle exec ruby api.rb
ruby /var/server/websocket_server.rb