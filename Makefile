.PHONY: help build up down restart logs status clean deploy ansible-deploy test

# Variables
COMPOSE_FILE := docker-compose.yml
ANSIBLE_INVENTORY := ansible/inventory.ini
ANSIBLE_PLAYBOOK := ansible/playbook.yml

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Initial setup - create .env file from template
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file. Please edit it to customize your settings."; \
	else \
		echo ".env file already exists."; \
	fi

build: setup ## Build Docker images
	docker compose -f $(COMPOSE_FILE) build

up: setup ## Start containers in detached mode
	docker compose -f $(COMPOSE_FILE) up -d

down: ## Stop and remove containers
	docker compose -f $(COMPOSE_FILE) down

restart: ## Restart containers
	docker compose -f $(COMPOSE_FILE) restart

logs: ## Show container logs (follow mode)
	docker compose -f $(COMPOSE_FILE) logs -f

status: ## Show container status
	docker compose -f $(COMPOSE_FILE) ps

clean: ## Remove containers and volumes
	docker compose -f $(COMPOSE_FILE) down -v

deploy: build up ## Full deployment - build and start
	@echo "Deployment complete!"
	@echo "Access CUPS at: http://localhost:631"

ansible-check: ## Check Ansible connectivity
	ansible -i $(ANSIBLE_INVENTORY) print_servers -m ping

ansible-deploy: ## Deploy using Ansible
	ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_PLAYBOOK)

ansible-deploy-tags: ## Deploy specific Ansible tags (usage: make ansible-deploy-tags TAGS=docker)
	ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_PLAYBOOK) --tags $(TAGS)

shell: ## Open shell in the CUPS container
	docker compose -f $(COMPOSE_FILE) exec cups /bin/bash

pull: ## Pull latest images
	docker compose -f $(COMPOSE_FILE) pull

test: ## Run basic tests
	@echo "Testing Docker Compose configuration..."
	docker compose -f $(COMPOSE_FILE) config
	@echo "Docker Compose configuration is valid!"

validate-ansible: ## Validate Ansible playbook syntax
	ansible-playbook $(ANSIBLE_PLAYBOOK) --syntax-check

prune: ## Clean up unused Docker resources
	docker system prune -af --volumes

backup: ## Backup CUPS configuration
	@mkdir -p backups
	@timestamp=$$(date +%Y%m%d_%H%M%S); \
	docker compose -f $(COMPOSE_FILE) exec -T cups tar czf - /etc/cups > backups/cups_config_$$timestamp.tar.gz; \
	echo "Backup created: backups/cups_config_$$timestamp.tar.gz"

restore: ## Restore CUPS configuration (usage: make restore FILE=backups/cups_config_YYYYMMDD_HHMMSS.tar.gz)
	@if [ -z "$(FILE)" ]; then \
		echo "Please specify FILE: make restore FILE=backups/cups_config_YYYYMMDD_HHMMSS.tar.gz"; \
		exit 1; \
	fi
	docker compose -f $(COMPOSE_FILE) exec -T cups tar xzf - -C / < $(FILE)
	docker compose -f $(COMPOSE_FILE) restart cups
	@echo "Configuration restored from $(FILE)"
