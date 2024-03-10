
class PongGame
	# Constants for game dimensions and speed factors
	GAME_WIDTH = 10
	GAME_HEIGHT = 10
	BALL_SPEED_FACTOR = 0.2
	BALL_ACCELERATION = 0.001
	PADDLE_SPEED = 0.6
	MAX_VERTICAL_SPEED = 1.0
	attr_accessor :score_left, :score_right, :ball_position, :ball_direction, :left_paddle, :right_paddle, :paddle_height, :prev_ball_position

	def initialize
		@score_left = 0
		@score_right = 0
		@ball_position = {x: 0, y: 0} #assuming centre of the board
		@ball_direction = {x: 1, y:1} #Random initial direction
		@left_paddle = {y: 5} #Assuming a vertical middle position
		@right_paddle = {y: 5} #Assuming a vertical middle position
		@paddle_height = 4
		@prev_ball_position = {x: 0, y: 0}
		@left_paddle_direction = 0
		@right_paddle_direction = 0
		@ball_speed = BALL_SPEED_FACTOR
		@winner = nil
	end

	def set_left_paddle(direction)
		if direction > 0.0
			@left_paddle_direction = 1.0
		elsif direction < 0.0
			@left_paddle_direction = -1.0
		else
			@left_paddle_direction = 0.0
		end
	end

	def set_right_paddle(direction)
		if direction > 0.0
			@right_paddle_direction = 1.0
		elsif direction < 0.0
			@right_paddle_direction = -1.0
		else
			@right_paddle_direction = 0.0
		end
	end

	# Add methods to move paddles
	def move_left_paddle(amount)
		@left_paddle[:y] += amount
		# Ensure the paddle stays within the top and bottom boundaries of the game area
		@left_paddle[:y] = [[@left_paddle[:y], 0].max, GAME_HEIGHT - @paddle_height].min
	  end
	  
	  def move_right_paddle(amount)
		@right_paddle[:y] += amount
		# Ensure the paddle stays within the top and bottom boundaries of the game area
		@right_paddle[:y] = [[@right_paddle[:y], 0].max, GAME_HEIGHT - @paddle_height].min
	  end
	  

	def reset_ball
		@ball_position = {x:5, y:5}
		@ball_direction = {x: [-1,1].sample, y: [-1,1].sample}
	end


	def check_paddle_collision
		# Define paddle bounds
		left_paddle_bounds = (@left_paddle[:y]..(@left_paddle[:y] + @paddle_height))
		right_paddle_bounds = (@right_paddle[:y]..(@right_paddle[:y] + @paddle_height))

		# # Log for verification
		# puts "Left Paddle Bounds: #{left_paddle_bounds}"
		# puts "Right Paddle Bounds: #{right_paddle_bounds}"
		# puts "Ball Y Position: #{@ball_position[:y]}"
	  
		# Predict the ball's next position based on its current trajectory
		predicted_ball_position_y = @ball_position[:y] + @ball_direction[:y] * @ball_speed
		
		# Check for collision with left paddle
		if (@ball_position[:x] <= 1 && left_paddle_bounds.include?(predicted_ball_position_y)) ||
		   (@prev_ball_position[:x] > 1 && @ball_position[:x] <= 1 && left_paddle_bounds.cover?(@prev_ball_position[:y]..@ball_position[:y]))
		  @ball_position[:x] = 1  # Reset the position to ensure it's in front of the paddle
		  @ball_direction[:x] = @ball_direction[:x].abs  # Ensure the ball moves to the right
		end
		
		# Check for collision with right paddle
		if (@ball_position[:x] >= 9 && right_paddle_bounds.include?(predicted_ball_position_y)) ||
		   (@prev_ball_position[:x] < 9 && @ball_position[:x] >= 9 && right_paddle_bounds.cover?(@prev_ball_position[:y]..@ball_position[:y]))
		  @ball_position[:x] = 9  # Reset the position to ensure it's in front of the paddle
		  @ball_direction[:x] = -@ball_direction[:x].abs  # Ensure the ball moves to the left
		end
	  end
	  

	def update_game_state
		# Store the ball's previous position before updating
		@prev_ball_position = @ball_position.dup

		# Update ball position with speed factor
		@ball_position[:x] += @ball_direction[:x] * @ball_speed
		@ball_position[:y] += @ball_direction[:y] * @ball_speed

		# Check for collision with top and bottom walls
		if @ball_position[:y] <= 0 || @ball_position[:y] >= GAME_HEIGHT
			@ball_direction[:y] *= -1
		end

		# Check for collision with left and right walls i.e., scoring
		if @ball_position[:x] <= 0
			@score_right += 1
			reset_ball
		elsif @ball_position[:x] >= GAME_WIDTH
			@score_left += 1
			reset_ball
		end

		if score_left >= 5
			@winner = 0
		elsif score_right >= 5
			@winner = 1
		end

		move_left_paddle(@left_paddle_direction * PADDLE_SPEED)
		move_right_paddle(@right_paddle_direction * PADDLE_SPEED)

		# Paddle collision detection logic
		check_paddle_collision
		@ball_speed += BALL_ACCELERATION
	end

	def reset_ball
		# Reset position to the center
		@ball_speed = BALL_SPEED_FACTOR
		@ball_position = {x: GAME_WIDTH / 2, y: GAME_HEIGHT / 2}
		# Ensure the ball's vertical speed is limited
		@ball_direction = {
			x: [-1,1].sample,
			y: rand(-MAX_VERTICAL_SPEED..MAX_VERTICAL_SPEED)
	}
	end
	  
	  

	def to_s
		"Score: Left - #{@score_left}, Right - #{@score_right} | Ball Position: #{@ball_position}"
	  end

	def state_as_json
	{
		score_left: @score_left,
		score_right: @score_right,
		ball_position: @ball_position,
		left_paddle: @left_paddle,
		right_paddle: @right_paddle,
		winner: @winner,
		game: "pong"
	}
	end

	

	end



# # Example usage
# game = PongGame.new
# 10.times do
# 	game.update_game_state
# 	puts game.to_s
# end



