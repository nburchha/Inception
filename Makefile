COMPOSE_PATH = srcs/docker-compose.yml

all:
	docker compose -f $(COMPOSE_PATH) up --build

clean:
	rm -rf web
	rm -rf db

