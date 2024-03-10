#ifndef CLI_HPP
# define CLI_HPP

# include <ncurses.h>
# include <libwebsockets.h>
# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <iostream>
# include <unistd.h>
# include <openssl/ssl.h>
# include "json_defines.hpp"

# define K_ENTER 10
# define READ_BUFFER 4096
# define SNAKE_WIDTH 40
# define SNAKE_HEIGHT 20
# define MOVE_RIGHT "0"
# define MOVE_DOWN "1"
# define MOVE_LEFT "2"
# define MOVE_UP "3"

#define TX_BUFFER_BYTES 1024
#define INPUT_BUFFER 100

enum states {
	none,
	menu,
	snake,
	pong,
	victory,
	defeat,
	searching,
	login,
	registering,
	connecting
};

typedef struct s_game
{
	struct lws *web_socket;
	struct lws_context *context;
	int state;
	int previous_state;
	int player_id;
	int	searching_for;
	bool first_update;
	bool awaiting_auth;
	std::string	moving_dir;
	std::string msg;
	std::string login_status;
	std::string register_status;
	std::string write_buf;
	std::string token;
	std::string menu_message;
}	t_game;

void 		handle_message(t_game *game, char *msg);
int 		websocket_init(t_game *game);
void 		websocket_connect(t_game *game);
void		handle_snake_state(t_game *game);
void		handle_pong_state(t_game *game);
void		update_game(t_game *game);
void 		change_state(t_game *game, int state);
std::string extract_json_string(std::string msg, std::string field);

#endif