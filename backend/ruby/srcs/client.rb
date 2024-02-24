class Client
	attr_accessor :game, :game_selected, :matchmaking, :in_game, :id, :partner, :ws, :user_id
	def initialize (ws)
		@game_selected = "pong"
		@matchmaking = false
		@in_game = false
		@game = nil
		@partner = nil
		@id = 0
		@user_id = nil
		@ws = ws
	end
end