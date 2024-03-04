
all:
	docker-compose -f ./docker-compose.yml up -d

build:
	docker-compose -f ./docker-compose.yml up -d --build

down:
	docker-compose -f ./docker-compose.yml down --volumes

re:	down
	docker-compose -f ./docker-compose.yml up -d --build

clean: down
	docker system prune -a

fclean:
	docker stop $$(docker ps -qa)
	docker system prune --all --force --volumes
	docker network prune --force
	docker volume prune --force
	sudo rm -rf local/db/*

.PHONY	: all build down re clean fclean