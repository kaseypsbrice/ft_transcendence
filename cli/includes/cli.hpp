#ifndef CLI_HPP
# define CLI_HPP

# include <ncurses.h>
# include <libwebsockets.h>
# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <iostream>
# include <unistd.h>

# define K_ENTER 10
# define FIND_SNAKE "{\"type\":\"find_snake\"}"
# define GAME_FOUND "\"type\":\"game_found\""
# define WINNER "\"winner\":"
# define PARTNER_DISCONNECTED "\"type\":\"partner_disconnected\""
# define PLAYER_ID "\"player_id\":"
# define GET_SNAKES "\"snakes\":"
# define GET_FOOD "\"food\":"
# define TYPE_STATE "\"type\":\"state\""
# define CHANGE_DIRECTION(dir) ("{\"type\":\"change_direction\",\"direction\":\"" + dir + "\"}")
# define READ_BUFFER 4096
# define SNAKE_WIDTH 40
# define SNAKE_HEIGHT 20
# define MOVE_RIGHT "0"
# define MOVE_DOWN "1"
# define MOVE_LEFT "2"
# define MOVE_UP "3"

enum states {
	menu,
	snake,
	victory,
	defeat
};

typedef struct s_game
{
	int state;
	int player_id;
	std::string msg;
}	t_game;

#endif