# define GAME_FOUND "\"type\":\"game_found\""
# define INVALID_TOKEN "\"type\":\"InvalidToken\""
# define WINNER "\"winner\":"
# define PARTNER_DISCONNECTED "\"type\":\"partner_disconnected\""
# define PLAYER_ID "\"player_id\":"
# define GET_SNAKES "\"snakes\":"
# define GET_FOOD "\"food\":"
# define TYPE_STATE "\"type\":\"state\""
# define STATE "\"type\":\"state\""
# define LOGIN_ERROR "\"type\":\"LoginError\""
# define REGISTER_ERROR "\"type\":\"RegisterError\""
# define LOGIN_FORMAT_ERROR "\"type\":\"LoginFormatError\""
# define REGISTER_FORMAT_ERROR "\"type\":\"RegisterFormatError\""
# define PONG "\"type\":\"pong\""
# define GAME_PONG "\"game\":\"pong\""
# define GAME_SNAKE "\"game\":\"snake\""
# define AUTHENTICATION "\"type\":\"authentication\""
# define TOKEN "\"token\":\""
# define LEFT_PADDLE_Y "\"left_paddle\":{\"y\":"
# define RIGHT_PADDLE_Y "\"right_paddle\":{\"y\":"
# define BALL_POS "\"ball_position\":{"
# define BALL_X "\"x\":"
# define BALL_Y "\"y\":"
# define SCORE_LEFT "\"score_left\":"
# define SCORE_RIGHT "\"score_right\":"

# define FIND_SNAKE(token) ("{\"token\":\"" + token + "\",\"type\":\"find_snake\"}")
# define FIND_PONG(token) ("{\"token\":\"" + token + "\",\"type\":\"find_pong\"}")

# define LOGIN(username, password) ("{\"type\": \"login\", \"data\": {\"username\":\"" + username + \
"\", \"password\":\"" + password + "\"}}")

# define REGISTER(username, display_name, password) ("{\"type\": \"register\", \"data\": {\"username\":\"" + username + \
"\", \"display_name\":\"" + display_name + "\",\"password\":\"" + password + "\"}}")

# define CHANGE_DIRECTION(token, dir) ("{\"token\":\"" + token + "\",\"type\":\"change_direction\",\"direction\":\"" + dir + "\"}")
# define GET_CHAT_HISTORY(token) ("{\"token\":\"" + token + "\",\"type\":\"get_chat_history\"}")
# define GET_GAME_STATUS(token, game) ("{\"token\":\"" + token + "\",\"type\":\"get_game_status\",\"game\":\"" + game + "\"}")
# define FIND_TOURNAMENT(token, game) ("{\"token\":\"" + token + "\",\"type\":\"find_tournament\",\"game\":\"" + game + "\"}")