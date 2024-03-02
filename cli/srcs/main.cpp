#include "cli.hpp"

int main(void)
{
	t_game game;
 	websocket_init(&game);
	initscr();
	while(1)
	{
		if (!game.web_socket)
			websocket_connect(&game);
		update_game(&game);
		lws_service(game.context, -1); // timeout = -1 returns if there are no events, undocumented :)))) spent hours here
	}
	endwin();
	lws_context_destroy(game.context);

	return 0;
}