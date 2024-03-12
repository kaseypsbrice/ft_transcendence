require_relative 'tournament'

class AlertManager

	def initialize(websocket_manager)
		@websocket_manager = websocket_manager
		@alerts = []
		@tournaments = []
		@t_id = 0
	end

	def alert_json(alert)
		to_send = alert.clone
		if to_send.key?(:user_from)
			puts "adding user from"
			to_send[:user_from] = to_send[:user_from].display_name
		end
		if to_send.key?(:user_to)
			puts "adding user from"
			to_send[:user_to] = to_send[:user_to].display_name
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

	def accept_invite(user_to, user_from)
		@alerts.delete_if { |alert| alert[:expires] <= Time.now.to_i }
		alert_found = nil
		@alerts.each do |alert|
			if alert[:user_from].id == user_from.id && alert[:user_to].id == user_to.id && alert[:type] == "invite"
				alert_found = alert
				break
			end
		end
		if alert_found == nil
			return nil
		end
		@websocket_manager.connections.each do |c_ws, c|
			if c.user_id == user_to.id
				c_ws.send({type: "InviteAccepted", user: user_from.display_name, game: alert_found[:game]}.to_json)
			elsif c.user_id == user_from.id
				c_ws.send({type: "InviteAccepted", user: user_from.display_name, game: alert_found[:game]}.to_json)
			end
		end
		alert_found[:accepted] = true
	end

	def pending_friend(user_to, user_from)
		selected = @alerts.select { |a| a[:user_to].id == user_to.id && a[:user_from].id == user_from.id && a[:type] == "friend"}
		if selected.size == 0
			return false
		end
		return true
	end

	def accept_friend(user_to, user_from)
		selected = @alerts.select { |a| a[:user_to].id == user_to.id && a[:user_from].id == user_from.id && a[:type] == "friend"}
		if selected.size == 0
			return false
		end
		user_to.friend_user(user_from.id, @websocket_manager.db)
		user_from.friend_user(user_to.id, @websocket_manager.db)
		@alerts.delete_if { |a| a[:user_to].id == user_to.id && a[:user_from].id == user_from.id && a[:type] == "friend"}
		return true
	end

	def create_invite(user_inviting, user_invited, game)
		@alerts.delete_if { |alert| alert[:user_from].id == user_inviting.id && alert[:type] == "invite"}
		new_alert = {
			user_from: user_inviting,
			user_to: user_invited,
			user_from_ready: false,
			user_to_ready: false,
			accepted: false,
			type: "invite",
			game: game,
			expires: Time.now.to_i + 600
		}
		@alerts.push(new_alert)
		@websocket_manager.connections.each_value do |client|
			if client.user_id == user_invited.id
				client.ws.send(alert_json(new_alert))
			end
		end
	end

	def create_friend(user_inviting, user_invited)
		@alerts.delete_if { |alert| alert[:user_from] == user_inviting.id && alert[:user_to] == user_invited.id && alert[:type] == "friend"}
		new_alert = {
			user_from: user_inviting,
			user_to: user_invited,
			type: "friend",
			expires: Time.now.to_i + 604800 # one week
		}
		@alerts.push(new_alert)
		@websocket_manager.connections.each_value do |client|
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

	def handle_status(user)
		puts "handle_status invite #{user.display_name}"
		alert_found = nil
		@alerts.each do |alert|
			if alert[:user_from].id == user.id || alert[:user_to].id == user.id \
				&& alert[:type] == "invite" && (alert[:accepted] == true)
				alert_found = alert
				break
			end
		end
		if alert_found == nil
			user.current_ws.send({type: "game_status", data: {status: "error"}}.to_json)
			return
		end
		user.invite_ws = user.current_ws
		if user.id == alert_found[:user_from].id
			alert_found[:user_from_ready] = true
		else
			alert_found[:user_to_ready] = true
		end
		if alert_found[:user_from_ready] == true && alert_found[:user_to_ready] == true
			if alert_found[:user_from].invite_ws == nil || alert_found[:user_to].invite_ws == nil
				user.current_ws.send({type: "game_status", data: {status: "WaitingPartner"}}.to_json)
				return
			end
			@websocket_manager.start_game(alert_found[:user_from].invite_ws, alert_found[:user_to].invite_ws, alert_found[:game])
			@alerts.delete(alert_found)
		else
			user.current_ws.send({type: "game_status", data: {status: "WaitingPartner"}}.to_json)
		end
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

	def leave_tournament(user)
		if user.tournament == nil
			user.current_ws.send({type: "game_status", data: {status: "error"}}.to_json)
			return
		elsif user.tournament.full?
			return
		end
		user.tournament.remove_player(user)
		user.current_ws.send({type: "game_status", data: {status: "none"}}.to_json)
	end

end