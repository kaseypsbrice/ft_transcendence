#include "cli.hpp"

void handle_message(t_game *game, char *msg)
{
	game->msg = msg;
	if (game->msg.find(STATE) != std::string::npos)
	{
		if (game->msg.find(GAME_PONG) != std::string::npos)
		{
			handle_pong_state(game);
		}
		else if (game->msg.find(GAME_SNAKE) != std::string::npos)
		{
			handle_snake_state(game);
		}
	}
	else if (game->msg.find(GAME_FOUND) != std::string::npos)
	{
		size_t i = game->msg.find(PLAYER_ID);
		if (i != std::string::npos)
		{
			i += strlen(PLAYER_ID);
			change_state(game, game->searching_for);
			game->player_id = game->msg[i] - '0';
		}
	}
	else if (game->msg.find(PONG) != std::string::npos)
	{
		change_state(game, menu);
	}
	else if (game->msg.find(LOGIN_ERROR) != std::string::npos)
	{
		game->awaiting_auth = false;
		game->menu_message = "Login Error: " + extract_json_string(game->msg, "message") + "\n";
		change_state(game, menu);
	}
	else if (game->msg.find(REGISTER_ERROR) != std::string::npos)
	{
		game->awaiting_auth = false;
		game->menu_message = "Register Error: " + extract_json_string(game->msg, "message") + "\n";
		change_state(game, menu);
	}
	else if (game->msg.find(LOGIN_FORMAT_ERROR) != std::string::npos)
	{
		game->awaiting_auth = false;
		game->menu_message = "Login Format Error\n";
		change_state(game, menu);
	}
	else if (game->msg.find(REGISTER_FORMAT_ERROR) != std::string::npos)
	{
		game->awaiting_auth = false;
		game->menu_message = "Register Format Error\n";
		change_state(game, menu);
	}
	else if (game->msg.find(AUTHENTICATION) != std::string::npos)
	{
		size_t len = 1;
		size_t pos = game->msg.find(TOKEN) + strlen(TOKEN);
		while (game->msg[pos] == '"')
			pos++;
		while (game->msg[pos + len] != '"')
			len++;
		game->token = game->msg.substr(pos, len);
		game->awaiting_auth = false;
		change_state(game, menu);
	}
	game->msg.clear();
}
