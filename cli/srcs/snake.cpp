#include "cli.hpp"

int draw_snakes(t_game *game)
{
	size_t i = game->msg.find(GET_SNAKES);
	if (i == std::string::npos)
	{
		std::cerr << "couldnt find snakes in game state" << std::endl;
		return 1;
	}
	i += strlen(GET_SNAKES) + 1;
	size_t end_of_snakes = game->msg.find("]]");
	int left = -1;
	while (i < end_of_snakes)
	{
		while (i < end_of_snakes && (game->msg[i] < '0' || game->msg[i] > '9'))
			i++;
		int j = 1;
		while (game->msg[i + j] >= '0' && game->msg[i + j] <= '9')
			j++;
		if (left == -1)
		{
			left = atoi(game->msg.substr(i, j).c_str());
		}
		else
		{
			int right = atoi(game->msg.substr(i, j).c_str());
			mvprintw(right, left, "%c", 'O');		
			left = -1;
		}
		i += j;
	}
	return 0;
}

void draw_food(t_game *game)
{
	size_t i = game->msg.find(GET_FOOD);
	i += strlen(GET_FOOD) + 1;
	size_t end_of_food = game->msg.find("]", i);
	int left = -1;
	while (i < end_of_food)
	{
		while (i < end_of_food && (game->msg[i] < '0' || game->msg[i] > '9'))
			i++;
		int j = 1;
		while (game->msg[i + j] >= '0' && game->msg[i + j] <= '9')
			j++;
		if (left == -1)
		{
			left = atoi(game->msg.substr(i, j).c_str());
		}
		else
		{
			int right = atoi(game->msg.substr(i, j).c_str());
			mvprintw(right, left, "%c", 'X');		
			left = -1;
		}
		i += j;
	}
}

void handle_snake_state(t_game *game)
{
	if (game->msg.find(WINNER) != std::string::npos)
	{
		int i = game->msg.find(WINNER);
		i += strlen(WINNER);
		if (atoi(game->msg.substr(i, 1).c_str()) == game->player_id)
			game->state = victory;
		else
			game->state = defeat;
		game->msg.clear();
		return;
	}
	else if (game->msg.find(PARTNER_DISCONNECTED) != std::string::npos)
	{
		game->state = victory;
		game->msg.clear();
		return;
	}
	if (game->msg.find(TYPE_STATE) != std::string::npos)
	{
		clear();
		curs_set(0);
		if (draw_snakes(game))
		{
			game->msg.clear();
			std::cout << "no map" << std::endl;
			return ;
		}
		draw_food(game);
	}
}