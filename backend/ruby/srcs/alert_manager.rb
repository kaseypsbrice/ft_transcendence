require_relative 'tournament'

class AlertManager

	def initialize(websocket_manager)
		@websocket_manager = websocket_manager
		@alerts = []
		@tournaments = []
		@t_id = 0
	end

	def alert_json(alert)
		to_send = {
			game: alert[:game],
			type: alert[:type]
		}
		puts alert
		if alert.key?(:user_from)
			puts "adding user from"
			to_send[:user_from] = alert[:user_from].display_name
		end
		return {type: "Alert", data: to_send}.to_json
	end

	def send_client_alerts(client)
		@alerts.delete_if { |alert| alert[:expires] <= Time.now.to_i }
		@alerts.each do |alert|
			if alert[:user_to].id == client.user_id
				client.ws.send(alert_json(alert))
			end
		end	
	end

	def send_user_alerts(user)
		alert_sent = false
		@alerts.delete_if { |alert| alert[:expires] <= Time.now.to_i }
		@alerts.each do |alert|
			if alert[:user_to].id == user.id
				@websocket_manager.connections.each_value do |client|
					if client.user_id == user.id
						client.ws.send(alert_json(alert))
						alert_sent = true
					end
				end
			end
		end
		return alert_sent
	end

	def create_invite(user_inviting, user_invited, game)
		@alerts.delete_if { |alert| alert[:user_from].id == user_inviting.id}
		new_alert = {
			user_from: user_inviting,
			user_to: user_invited,
			type: "invite",
			game: game,
			expires: Time.now.to_i + 60
		}
		@alerts.push(new_alert)
		@websocket_manager.connections.each_value do |client|
			puts client
			if client.user_id == user_invited.id
				client.ws.send(alert_json(new_alert))
			end
		end
	end

	def create_tournament(user, game)
		puts "create_tournament #{game}"
		if game != "pong" && game != "snake"
			return false
		end
		new_tournmanent = Tournament.new(@websocket_manager, game, user, @t_id)
		@tournaments.push(new_tournmanent)
		@t_id += 1
		return true
	end

	def join_or_create_tournament(user, game)
		puts "join_or_create #{game}"
		if user.tournament != nil
			return false
		end
		@tournaments.each do |t|
			if t.game == game && !t.full? && !t.player?(user)
				t.add_player(user)
				return true
			end
		end
		return create_tournament(user, game)
	end

	def join_tournament_by_id(user, id)
		if user.tournament != nil
			return false
		end
		selected = @tournaments.select { |t| t.id == id }
		if selected.size == 0
			return false
		end
		if selected[0].full?
			return false
		end
		selected[0].add_player(user)
		return true
	end

end