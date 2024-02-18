
class SnakeGame
	GAME_WIDTH = 40
	GAME_HEIGHT = 20
	RIGHT = 0
	DOWN = 1
	LEFT = 2
	UP = 3

	class Snake

		attr_accessor :x, :y, :next, :dir, :add_segment_next_move, :last_dir
		def initialize(x, y)
			@x = x
			@y = y
			@dir = RIGHT
			@last_dir = RIGHT
			@add_segment_next_move = false
			@next = nil
		end

		def move_to(x, y)
			if x >= GAME_WIDTH
				x = 0
			elsif x < 0
				x = GAME_WIDTH - 1
			end
			if y >= GAME_HEIGHT
				y = 0
			elsif y < 0
				y = GAME_HEIGHT - 1
			end

			tail = self
			new_x = 0
			new_y = 0
			if add_segment_next_move
				while tail.next != nil
					tail = tail.next
				end
				new_x = tail.x
				new_y = tail.y
			end
			if @next != nil
				@next.move_to(@x, @y)
			end
			@x = x
			@y = y
			if add_segment_next_move
				tail.next = Snake.new(new_x, new_y)
				@add_segment_next_move = false
			end
		end
	end

	def initialize
		@snakes = [Snake.new(4, GAME_HEIGHT / 2), Snake.new(GAME_WIDTH - 4, GAME_HEIGHT / 2)]
		@food = []
		@rng = Random.new
		@winner = -1
		make_food
	end
	
	def change_direction(id, direction)
		snake = @snakes[id]
		if direction == RIGHT && snake.last_dir == LEFT
			return
		elsif direction == LEFT && snake.last_dir == RIGHT
			return
		elsif direction == DOWN && snake.last_dir == UP
			return
		elsif direction == UP && snake.last_dir == DOWN
			return
		end
		snake.dir = direction
	end

	def make_food
		food_x = @rng.rand(GAME_WIDTH)
		food_y = @rng.rand(GAME_HEIGHT)
		@food << food_x 
		@food << food_y
	end

	def snake_on_food(snake)
		for snake in @snakes
			i = 0
			while i < @food.size - 1
				if snake.x == @food[i] && snake.y == @food[i + 1]
					return i
				end
				i += 2
			end
		end
		return -1
	end

	def handle_collision(head1, head2, body1, body2)
		player1 = @snakes.find_index(head1)
		player2 = @snakes.find_index(head2)

		if player1 == nil || player2 == nil
			puts "snake collision error: could not locate head in @snakes"
			return
		end

		if head1 == body1 && head2 != body2 #player 1's head hit player 2's body
			@winner = player2
		elsif head2 == body2 && head1 != body1 #player 2's head hit player 1's body
			@winner = player1
		else #head on collision award win to longest snake or random
			s1_len = 0
			s2_len = 0
			while head1 != nil
				s1_len++
				head1 = head1.next
			end
			while head2 != nil
				s2_len++
				head2 = head2.next
			end
			if s1_len == s2_len
				@winner = @rng.rand(2)
			else
				@winner = s1_len > s2_len ? player1 : player2
			end
		end
	end

	def update_game_state
		for snake in @snakes
			snake.last_dir = snake.dir
			if snake.dir == RIGHT
				snake.move_to(snake.x + 1, snake.y)
			elsif snake.dir == DOWN
				snake.move_to(snake.x, snake.y + 1)
			elsif snake.dir == LEFT
				snake.move_to(snake.x - 1, snake.y)
			elsif snake.dir == UP
				snake.move_to(snake.x, snake.y - 1)
			end
			food_index = snake_on_food(snake)
			if food_index >= 0
				@food.delete_at(food_index)
				@food.delete_at(food_index)
				make_food
				snake.add_segment_next_move = true
			end
		end
		# O(n^2) i think oh well just dont add more snakes :P
		# single headed snakes can also phase through each other
		for snake in @snakes
			snake_head = snake
			for other_snake in @snakes
				other_snake_head = other_snake
				if snake == other_snake
					next
				end
				while snake != nil
					while other_snake != nil
						if snake.x == other_snake.x && snake.y == other_snake.y
							handle_collision(snake_head, other_snake_head, snake, other_snake)
							return
						end
						other_snake = other_snake.next
					end
					snake = snake.next
				end
			end
		end
	end

	def state_as_json
		data = {}
		data["snakes"] = []
		data["food"] = @food
		if (@winner != -1)
			data["winner"] = @winner
		end
		for i in 0..@snakes.size() - 1
			snake = @snakes[i]
			data["snakes"] << []
			while snake != nil
				data["snakes"][i] << snake.x
				data["snakes"][i] << snake.y
				snake = snake.next
			end
		end
		return data
	end
end
