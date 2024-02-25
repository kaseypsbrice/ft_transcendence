#include <cli.hpp>

#define TX_BUFFER_BYTES 1024

static struct lws *web_socket = NULL;
std::string write_buf;
t_game game;

void handle_snake_state(t_game *game);

static int callback_example( struct lws *wsi, enum lws_callback_reasons reason, void *user, void *in, size_t len )
{
	(void) user;
	(void) in;
	(void) len;
	switch( reason )
	{
		case LWS_CALLBACK_CLIENT_ESTABLISHED:
			break;

		case LWS_CALLBACK_CLIENT_RECEIVE:
			game.msg = (char *)in;
			handle_snake_state(&game);
			break;

		case LWS_CALLBACK_CLIENT_WRITEABLE:
		{
			unsigned char buf[LWS_SEND_BUFFER_PRE_PADDING + TX_BUFFER_BYTES + LWS_SEND_BUFFER_POST_PADDING];
			unsigned char *p = &buf[LWS_SEND_BUFFER_PRE_PADDING];
			size_t n = sprintf((char *)p, "%s", write_buf.c_str());
			lws_write( wsi, p, n, LWS_WRITE_TEXT );
			write_buf.clear();
			break;
		}

		case LWS_CALLBACK_CLIENT_CLOSED:
		case LWS_CALLBACK_CLIENT_CONNECTION_ERROR:
			web_socket = NULL;
			break;

		default:
			break;
	}

	return 0;
}

enum protocols
{
	PROTOCOL_EXAMPLE = 0,
	PROTOCOL_COUNT
};

static struct lws_protocols protocols[] =
{
    {
        .name                  = "example-protocol", /* Protocol name*/
        .callback              = callback_example,   /* Protocol callback */
        .per_session_data_size = 0,                  /* Protocol callback 'userdata' size */
        .rx_buffer_size        = READ_BUFFER,                  /* Receve buffer size (0 = no restriction) */
        .id                    = 0,                  /* Protocol Id (version) (optional) */
        .user                  = NULL,               /* 'User data' ptr, to access in 'protocol callback */
        .tx_packet_size        = 0                   /* Transmission buffer size restriction (0 = no restriction) */
    },
    {NULL, NULL, 0, 0, 0, NULL, 0}
};

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

void update_game()
{
	switch(game.state)
	{
		case menu:
		{
			clear();
			cbreak();
			noecho();
			nodelay(stdscr, 1);
			printw("Press Enter to search for a game of snake!\n");
			int c = getch();
			if (c == K_ENTER)
			{
				game.state = searching;
				write_buf = FIND_SNAKE;
				lws_callback_on_writable(web_socket);
			}
			break;
		}
		case snake:
		{

			int c = getch();
			switch (c)
			{
			case 'w':
				write_buf = CHANGE_DIRECTION(std::string(MOVE_UP));
				lws_callback_on_writable(web_socket);
				break;

			case 'a':
				write_buf = CHANGE_DIRECTION(std::string(MOVE_LEFT));
				lws_callback_on_writable(web_socket);
				break;

			case 's':
				write_buf = CHANGE_DIRECTION(std::string(MOVE_DOWN));
				lws_callback_on_writable(web_socket);
				break;

			case 'd':
				write_buf = CHANGE_DIRECTION(std::string(MOVE_RIGHT));
				lws_callback_on_writable(web_socket);
				break;
			}
			break;
		}
		case victory:
		{
			clear();
			move(0, 0);
			printw("Victory!\nPress Enter to return to menu");
			int c = getch();
			if (c == K_ENTER)
				game.state = menu;
			break;
		}
		case defeat:
		{
			clear();
			move(0, 0);
			printw("Defeat!\nPress Enter to return to menu");
			int c = getch();
			if (c == K_ENTER)
				game.state = menu;
			break;
		}
		case searching:
		{
			if (!game.msg.empty())
			{
				if (game.msg.find(GAME_FOUND) != std::string::npos)
				{
					size_t i = game.msg.find(PLAYER_ID);
					if (i == std::string::npos)
					{
						std::cerr << "unable to find player id in game found response" << std::endl;
						game.msg.clear();
						break;
					}
					i += strlen(PLAYER_ID);
					game.msg.clear();
					game.state = snake;
					game.player_id = game.msg[i] - '0';
					break;
				}
				game.msg.clear();
			}
			clear();
			cbreak();
			noecho();
			nodelay(stdscr, 1);
			printw("Searching for opponent...\n");
			getch();
			break;
		}
	}
}

int main(void)
{
	game.state = menu;
	game.player_id = 0;
	game.msg.clear();
	struct lws_context_creation_info info;
	memset( &info, 0, sizeof(info) );

	info.port = CONTEXT_PORT_NO_LISTEN; /* we do not run any server */
	info.protocols = protocols;
	info.gid = -1;
	info.uid = -1;

	struct lws_context *context = lws_create_context( &info );
	initscr();
	while(1)
	{
		/* Connect if we are not connected to the server. */
		if(!web_socket)
		{
			struct lws_client_connect_info ccinfo;
			memset(&ccinfo, 0, sizeof(ccinfo));
			
			ccinfo.context = context;
			ccinfo.address = "localhost";
			ccinfo.port = 8080;
			ccinfo.path = "/";
			ccinfo.host = lws_canonical_hostname( context );
			ccinfo.origin = "origin";
			ccinfo.protocol = protocols[PROTOCOL_EXAMPLE].name;
			
			web_socket = lws_client_connect_via_info(&ccinfo);

		}
		else
		{
			update_game();
		}
		lws_service( context, -1 ); // timeout = -1 returns if there are no events, undocumented :)))) spent hours here
	}
	endwin();
	lws_context_destroy( context );

	return 0;
}