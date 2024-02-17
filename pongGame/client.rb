class Client
	attr_accessor :game, :game_selected, :matchmaking, :in_game, :id, :partner
	def initialize
		@game_selected = "pong"
		@matchmaking = false
		@in_game = false
		@game = nil
		@partner = nil
		@id = 0
	end
end