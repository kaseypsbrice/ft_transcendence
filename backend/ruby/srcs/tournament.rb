class Tournament
	MAX_PLAYERS = 4

	attr_accessor :game, :users

	def initialize(websocket_manager, game, user)
		@websocket_manager = websocket_manager
		@game = game
		@users_remaining = {} # user id: user
		@users_registered = {} # user id: user
		@matches = []
		add_player(user)
	end
	
	def tournament_hash()
		to_send = {
			game: @game,
			status: "null",
			matches: []
		}
		@matches.each do |m|
			data = {
				player1: @users_registered[m[:player1]].display_name,
				player2: @users_registered[m[:player2]].display_name,
				status: m[:status],
				winner: m[:winner]
			}
			to_send[:matches].push(data)
		end
		return to_send
	end

	def full?()
		puts "registered players #{@users_registered.size}"
		if @users_registered.size >= MAX_PLAYERS
			return true
		end
		return false
	end

	def player?(user)
		if @users_remaining.key?(user.id)
			return true
		end
		return false
	end

	def get_match(user)
		selected = @matches.select { |m| m[:status] != "finished" && (m[:player1] == user.id || m[:player2] == user.id) }
		if selected.size > 0
			return selected[0]
		end
		return nil
	end

	def create_match(player1, player2)
		new_match = {
			player1: player1,
			player2: player2,
			p1ready: false,
			p2ready: false,
			status: "preparing",
			winner: nil
		}
		@matches.push(new_match)
		@users_registered[player1].current_ws.send({type: "TournamentMatchStarted", game: @game}.to_json)
		@users_registered[player2].current_ws.send({type: "TournamentMatchStarted", game: @game}.to_json)
	end

	def start()
		@users_registered.each do |user_id, user|
			user.tournament = self
		end
		shuffled = @users_remaining.keys.shuffle
		create_match(shuffled[0], shuffled[1])
		create_match(shuffled[2], shuffled[3])
	end

	def match_finished(winner, loser) # users not clients
		if !@users_remaining.include?(winner.id) || !@users_remaining.include?(loser.id) 
			puts "Error #{winner.display_name} or #{loser.display_name} not in remaining users"
			return
		end
		puts "tournament match finished #{winner.display_name} beat #{loser.display_name}"
		@users_remaining.delete(loser.id)
		loser.tournament_ws = nil
		loser.tournament = nil

		@matches.each do |match|
			if match[:player1] == winner.id
				match[:winner] = match[:player1]
				match[:status] = "finished"
			elsif match[:player2] == winner.id
				match[:winner] = match[:player2]
				match[:status] = "finished"
			end
		end

		if @users_remaining.size == 2
			puts "tournament final match"
			users_remaining = @users_remaining.keys
			create_match(users_remaining[0], users_remaining[1])
		end

		if @users_remaining.size == 1
			winner.tournament = nil
			winner.tournament_ws = nil
			@users_remaining.delete(winner.id)
			winner.add_tournament_win(@game, @websocket_manager.db)
		end
	end

	def start_match(match)
		puts "starting match #{match}"
		p1 = @users_registered[match[:player1]]
		p2 = @users_registered[match[:player2]]
		if p1.tournament_ws == nil || p2.tournament_ws == nil
			return false
		end
		@websocket_manager.start_game(p1.tournament_ws, p2.tournament_ws, @game)
		match[:status] = "started"
		return true
	end

	def handle_status(user)
		puts "handle_status #{user.display_name}"
		if full?
			puts "full"
			match = get_match(user)
			if match == nil
				user.current_ws.send({type: "game_status", data: {status: "error"}}.to_json)
				return
			end
			if match[:status] == "preparing"
				puts "preparing"
				if user.tournament_ws != user.current_ws
					puts "setting tournament ws"
					user.tournament_ws = user.current_ws
				end
				if match[:player1] == user.id
					match[:p1ready] = true
				else
					match[:p2ready] = true
				end
				if match[:p1ready] && match[:p2ready]
					if !start_match(match)
						puts "failed to start match, ws probably not set"
						t_hash = tournament_hash
						t_hash[:status] = "WaitingPartner"
						user.current_ws.send({type: "game_status", data: t_hash}.to_json)
					end
				else
					puts "partner not ready"
					t_hash = tournament_hash
					t_hash[:status] = "WaitingPartner"
					user.current_ws.send({type: "game_status", data: t_hash}.to_json)
				end
			end
		else
			puts "not full"
			t_hash = tournament_hash
			t_hash[:status] = "FoundTournament"
			user.current_ws.send({type: "game_status", data: t_hash}.to_json)
		end
	end

	def add_player(user)
		if full? || player?(user) || user.tournament != nil
			return
		end
		@users_registered[user.id] = user
		@users_remaining[user.id] = user
		user.current_ws.send({type: "TournamentJoined", data: tournament_hash}.to_json)
		user.tournament = self
		#user.tournament_ws = user.current_ws
		if @users_registered.size == MAX_PLAYERS
			start()
		end
	end
end