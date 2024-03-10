#include "cli.hpp"

void draw_paddle(int xpos, int ypos)
{
	for (int i = 0; i < 4; i++)
	{
		move(ypos + i, xpos);
		printw("|");
	}
}

void draw_paddles(t_game *game)
{
	int lpaddle_index = game->msg.find(LEFT_PADDLE_Y);
	lpaddle_index += strlen(LEFT_PADDLE_Y);
	double lpaddle_y = 8.0 - atof(game->msg.c_str() + lpaddle_index);
	int rpaddle_index = game->msg.find(RIGHT_PADDLE_Y);
	rpaddle_index += strlen(RIGHT_PADDLE_Y);
	double rpaddle_y = 8.0 - atof(game->msg.c_str() + rpaddle_index);
	
	draw_paddle(1, static_cast<int>(lpaddle_y));
	draw_paddle(30, static_cast<int>(rpaddle_y));
}

void draw_ball(t_game *game)
{
	int ball_pos_index = game->msg.find(BALL_POS);
	ball_pos_index += strlen(BALL_POS);
	int ball_x_index = game->msg.find(BALL_X, ball_pos_index);
	ball_x_index += strlen(BALL_X);
	double ball_x = 3.0 * atof(game->msg.c_str() + ball_x_index);
	int ball_y_index = game->msg.find(BALL_Y, ball_pos_index);
	ball_y_index += strlen(BALL_Y);
	double ball_y = 12.0 - atof(game->msg.c_str() + ball_y_index);
	
	move(static_cast<int>(ball_y), static_cast<int>(ball_x));
	printw("O");
}

void draw_score(t_game *game)
{
	int score_left_index = game->msg.find(SCORE_LEFT);
	score_left_index += strlen(SCORE_LEFT);
	char score_left = game->msg[score_left_index];
	int score_right_index = game->msg.find(SCORE_RIGHT);
	score_right_index += strlen(SCORE_RIGHT);
	char score_right = game->msg[score_right_index];

	move(0, 2);
	printw("%c", score_left);
	move(0, 28);
	printw("%c", score_right);
}

void handle_pong_state(t_game *game)
{
	if (game->msg.find(WINNER) != std::string::npos)
	{
		int i = game->msg.find(WINNER);
		i += strlen(WINNER);
		int winner = atoi(game->msg.c_str() + i);
		if (game->msg[i] >= '0' && game->msg[i] <= '9')
		{
			if (winner == game->player_id)
				change_state(game, victory);
			else
				change_state(game, defeat);
			game->msg.clear();
			return;
		}
	}
	if (game->msg.find(PARTNER_DISCONNECTED) != std::string::npos)
	{
		change_state(game, victory);
		game->msg.clear();
		return;
	}
	if (game->msg.find(TYPE_STATE) != std::string::npos)
	{
		clear();
		curs_set(0);
		draw_paddles(game);
		draw_ball(game);
		draw_score(game);
	}
}