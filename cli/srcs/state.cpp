#include "cli.hpp"

void change_state(t_game *game, int state)
{
	game->previous_state = game->state;
	game->state = state;
	game->first_update = true;
}

void update_game(t_game *game)
{
	if (game->msg.find(INVALID_TOKEN) != std::string::npos)
	{
		game->token.clear();
		change_state(game, menu);
	}
	switch(game->state)
	{
		case connecting:
		{
			if (game->first_update)
			{
				clear();
				noecho();
				nodelay(stdscr, true);
				game->first_update = false;
				printw("Connecting to server...");
				refresh();
			}
			if (game->msg.find("pong") != std::string::npos)
			{
				game->msg.clear();
				change_state(game, menu);
			}
			break;
		}
		case menu:
		{
			cbreak();
			noecho();
			nodelay(stdscr, true);
			game->awaiting_auth = false;
			if (game->token.empty())
			{
				if (game->first_update)
				{
					clear();
					if (!game->menu_message.empty())
					{
						printw("%s", game->menu_message.c_str());
						game->menu_message.clear();
					}
					printw("You are not logged in\n1 to Login\n2 to Register\n3 to Exit\n");
					refresh();
					game->first_update = false;
				}
				int c = getch();
				if (c == '1')
					change_state(game, login);
				if (c == '2')
					change_state(game, registering);
				if (c == '3')
					exit (0);
				break;
			}
			if (game->first_update)
			{
				clear();

				printw("Press 0 to search for a game of snake\n");
				printw("Press 1 to search for a game of pong\n");
				refresh();
				game->first_update = false;
			}
			int c = getch();
			if (c == '0')
			{
				change_state(game, searching);
				game->write_buf = FIND_SNAKE(game->token);
				game->searching_for = snake;
				lws_callback_on_writable(game->web_socket);
			}
			else if (c == '1')
			{
				change_state(game, searching);
				game->write_buf = FIND_PONG(game->token);
				game->searching_for = pong;
				lws_callback_on_writable(game->web_socket);
			}
			break;
		}
		case snake:
		{

			int c = getch();
			switch (c)
			{
			case 'w':
				game->write_buf = CHANGE_DIRECTION(game->token, std::string(MOVE_UP));
				lws_callback_on_writable(game->web_socket);
				break;

			case 'a':
				game->write_buf = CHANGE_DIRECTION(game->token, std::string(MOVE_LEFT));
				lws_callback_on_writable(game->web_socket);
				break;

			case 's':
				game->write_buf = CHANGE_DIRECTION(game->token, std::string(MOVE_DOWN));
				lws_callback_on_writable(game->web_socket);
				break;

			case 'd':
				game->write_buf = CHANGE_DIRECTION(game->token, std::string(MOVE_RIGHT));
				lws_callback_on_writable(game->web_socket);
				break;
			}
			break;
		}
		case pong:
		{

		}
		case victory:
		{
			if (game->first_update)
			{
				move(0, 0);
				clear();
				printw("Victory!\nPress Enter to return to menu");
				refresh();
				game->first_update = false;
			}
			cbreak();
			noecho();
			nodelay(stdscr, 1);
			int c = getch();
			if (c == K_ENTER)
				change_state(game, menu);
			break;
		}
		case defeat:
		{
			if (game->first_update)
			{
				move(0, 0);
				clear();
				printw("Defeat!\nPress Enter to return to menu");
				refresh();
				game->first_update = false;
			}
			cbreak();
			noecho();
			nodelay(stdscr, 1);
			int c = getch();
			if (c == K_ENTER)
				change_state(game, menu);
			break;
		}
		case searching:
		{
			if (game->first_update)
			{
				clear();
				printw("Searching for opponent...\n");
				refresh();
				game->first_update = false;
			}
			cbreak();
			noecho();
			nodelay(stdscr, 1);
			break;
		}
		case login:
		{
			if (game->awaiting_auth)
			{
				cbreak();
				nodelay(stdscr, true);
				int c = getch();
				if (c == K_ENTER)
					change_state(game, menu);
				break;
			}
			nodelay(stdscr, false);
			if (game->first_update)
			{
				game->first_update = false;
				clear();
				printw("Please login\n");
			}

			printw("Username:\n");
			nocbreak();
			echo();
			char username[INPUT_BUFFER];
			bzero(username, INPUT_BUFFER);
			username[0] = 0;
			while (strlen(username) < 1)
				getnstr(username, INPUT_BUFFER);
			
			printw("\nPassword:\n");
			noecho();
			char password[INPUT_BUFFER];
			bzero(password, INPUT_BUFFER);
			password[0] = 0;
			while (strlen(password) < 1)
				getnstr(password, INPUT_BUFFER);
		
			game->write_buf = LOGIN(std::string(username), std::string(password));
			lws_callback_on_writable(game->web_socket);
			game->awaiting_auth = true;
			clear();
			printw("Waiting for server to respond to login request...\n");
			printw("Press enter to return to menu");
			refresh();
			break;
		}
		case registering:
		{
			if (game->awaiting_auth)
			{
				cbreak();
				nodelay(stdscr, true);
				int c = getch();
				if (c == K_ENTER)
					change_state(game, menu);
				break;
			}
			nodelay(stdscr, false);
			if (game->first_update)
			{
				game->first_update = false;
				clear();
				printw("Please register\n");
			}

			printw("Username:\n");
			nocbreak();
			echo();
			char username[INPUT_BUFFER];
			bzero(username, INPUT_BUFFER);
			while (strlen(username) < 1)
				getnstr(username, INPUT_BUFFER);

			printw("\nDisplay Name:\n");
			char display_name[INPUT_BUFFER];
			bzero(display_name, INPUT_BUFFER);
			while (strlen(display_name) < 1)
				getnstr(display_name, INPUT_BUFFER);

			printw("\nPassword:\n");
			noecho();
			char password[INPUT_BUFFER];
			bzero(password, INPUT_BUFFER);
			while (strlen(password) < 1)
				getnstr(password, INPUT_BUFFER);
			
			game->write_buf = REGISTER(std::string(username), std::string(display_name), std::string(password));
			lws_callback_on_writable(game->web_socket);
			game->awaiting_auth = true;
			clear();
			printw("Waiting for server to respond to register request...\n");
			printw("Press enter to return to menu");
			break;
		}
	}
}