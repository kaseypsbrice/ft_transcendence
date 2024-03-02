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
# define GAME_SNAKE "\"game\":\"pong\""
# define AUTHENTICATION "\"type\":\"authentication\""
# define TOKEN "\"token\":\""

# define FIND_SNAKE(token) ("{\"token\":\"" + token + "\",\"type\":\"find_snake\"}")

# define LOGIN(username, password) ("{\"type\": \"login\", \"data\": {\"username\":\"" + username + \
"\", \"password\":\"" + password + "\"}}")

# define REGISTER(username, display_name, password) ("{\"type\": \"register\", \"data\": {\"username\":\"" + username + \
"\", \"display_name\":\"" + display_name + "\",\"password\":\"" + password + "\"}}")

# define CHANGE_DIRECTION(token, dir) ("{\"token\":\"" + token + "\",\"type\":\"change_direction\",\"direction\":\"" + dir + "\"}")
