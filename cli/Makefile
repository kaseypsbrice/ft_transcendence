NAME = cli

INCLUDES = includes

SRCS = srcs/main.cpp \
srcs/websocket.cpp \
srcs/state.cpp \
srcs/snake.cpp \
srcs/utils.cpp \
srcs/message.cpp \
srcs/pong.cpp

CERTS = temp.key temp.crt

OBJS = $(SRCS:.cpp=.o)

CC = c++
FLAGS = -Wall -Wextra -Werror
LIBS = -lncurses -lwebsockets -lcrypto -lssl

all: $(NAME)

$(NAME): $(OBJS) $(CERTS)
		$(CC) $(FLAGS) -I $(INCLUDES) $(OBJS) $(LIBS) -o $(NAME)
		@printf "$(GREEN)Executable created$(RESET)\n"

$(OBJS): %.o: %.cpp
		$(CC) -c -I $(INCLUDES) $< $(FLAGS) $(LIBS) -o $@

$(CERTS):
		@openssl req -nodes -x509 -newkey rsa:4096 -keyout temp.key \
-out temp.crt -days 365 -subj "/C=AU/ST=SA/L=Adelaide/O=42"

clean:
		@rm -f $(OBJS)
		@rm -f $(CERTS)
		@printf "$(CYAN)Cleaning objects...$(RESET)\n"

fclean: clean
		@rm -rf $(NAME)
		@printf "$(CYAN)Cleaning all...$(RESET)\n"

re: fclean all

.PHONY: all clean fclean re