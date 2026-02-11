.PHONY: build up down test clean

NGINX_CONF_DIR := nginx

# Default user and password for htpasswd
DEFAULT_USER := user1
DEFAULT_PASS := pass

build: $(NGINX_CONF_DIR)
	@echo "Building Docker image..."
	docker-compose build

$(NGINX_CONF_DIR):
	@echo "Generating default dir..."
	mkdir -p $(NGINX_CONF_DIR)

up:
	@echo "Starting proxy service..."
	docker-compose up -d

down:
	@echo "Stopping and removing proxy service..."
	docker-compose down

test:
	@echo "Running tests..."
	./tests/test.sh

clean:
	@echo "Cleaning up Docker resources..."
	docker-compose down --rmi all -v --remove-orphans
	docker volume prune -f
	docker network prune -f
	docker builder prune -f
	@echo "Removing generated htpasswd file..."
	rm -f $(AUTH_FILE)
