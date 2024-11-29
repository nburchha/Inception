SRC_DIR = srcs
COMPOSE_FILE=$(SRC_DIR)/docker-compose.yml

all:
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose  -f $(COMPOSE_FILE) down

reset:
	docker volume rm web database

re: down
	docker compose -f $(COMPOSE_FILE) build --no-cache
	docker compose -f $(COMPOSE_FILE) up -d


status:
	docker compose  -f $(COMPOSE_FILE) ps
	docker volume inspect web database

logs:
	docker compose  -f $(COMPOSE_FILE) logs -f --tail 10

.PHONY: all down reset status logs