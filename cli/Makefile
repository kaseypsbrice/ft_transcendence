NAME = cli

INCLUDES = includes

SRCS = srcs/main.cpp \


OBJS = $(SRCS:.cpp=.o)

CC = c++
FLAGS = -Wall -Wextra -Werror
LIBS = -lncurses -lwebsockets

all: $(NAME)

$(NAME): $(OBJS)
		$(CC) $(FLAGS) -I $(INCLUDES) $(OBJS) $(LIBS) -o $(NAME)
		@printf "$(GREEN)Executable created$(RESET)\n"

$(OBJS): %.o: %.cpp
		$(CC) -c -I $(INCLUDES) $< $(FLAGS) $(LIBS) -o $@

clean:
		@rm -f $(OBJS)
		@printf "$(CYAN)Cleaning objects...$(RESET)\n"

fclean: clean
		@rm -rf $(NAME)
		@printf "$(CYAN)Cleaning all...$(RESET)\n"

re: fclean all

.PHONY: all clean fclean re