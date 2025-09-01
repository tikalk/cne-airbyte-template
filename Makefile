# Makefile for Terraform Airbyte Template

# Variables
BACKEND_CONFIG = backend-config/config.k8s.tfbackend
TFVARS_FILE = terraform.tfvars
TF_LOG_LEVEL = INFO

# Default environment - can be overridden with make command ENV=prod
ENV ?= dev
WORKSPACE = cne-airbyte-template-$(ENV)

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

.PHONY: help init plan apply destroy workspace-list workspace-select workspace-new validate fmt clean test check-vars

# Default target
help: ## Show this help message
	@echo "$(BLUE)Terraform Airbyte Template Makefile$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@echo "  make <target> [ENV=<env>]"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Environment:$(NC)"
	@echo "  Current ENV: $(ENV)"
	@echo "  Workspace: $(WORKSPACE)"

check-vars: ## Check if required variables are set
	@echo "$(BLUE)Checking required variables...$(NC)"
	@if [ ! -f "$(TFVARS_FILE)" ]; then \
		echo "$(RED)Error: $(TFVARS_FILE) not found!$(NC)"; \
		echo "$(YELLOW)Please copy terraform.tfvars.example to terraform.tfvars and fill in the values$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ terraform.tfvars found$(NC)"

init: check-vars ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	terraform init -backend-config=$(BACKEND_CONFIG)
	@echo "$(GREEN)✓ Terraform initialized$(NC)"

workspace-list: ## List all workspaces
	@echo "$(BLUE)Listing workspaces...$(NC)"
	terraform workspace list

workspace-new: ## Create new workspace for environment
	@echo "$(BLUE)Creating workspace $(WORKSPACE)...$(NC)"
	terraform workspace new $(WORKSPACE) || echo "$(YELLOW)Workspace $(WORKSPACE) already exists$(NC)"

workspace-select: ## Select workspace for environment
	@echo "$(BLUE)Selecting workspace $(WORKSPACE)...$(NC)"
	terraform workspace select $(WORKSPACE)
	@echo "$(GREEN)✓ Selected workspace $(WORKSPACE)$(NC)"

validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	terraform validate
	@echo "$(GREEN)✓ Configuration is valid$(NC)"

fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)✓ Files formatted$(NC)"

plan: workspace-select validate ## Generate Terraform execution plan
	@echo "$(BLUE)Generating plan for $(WORKSPACE)...$(NC)"
	TF_LOG=$(TF_LOG_LEVEL) terraform plan -var-file=$(TFVARS_FILE) -out=tfplan-$(ENV)
	@echo "$(GREEN)✓ Plan generated: tfplan-$(ENV)$(NC)"

apply: workspace-select ## Apply Terraform changes
	@echo "$(YELLOW)Applying changes for $(WORKSPACE)...$(NC)"
	@if [ -f "tfplan-$(ENV)" ]; then \
		terraform apply tfplan-$(ENV); \
	else \
		echo "$(YELLOW)No plan file found, running interactive apply...$(NC)"; \
		terraform apply -var-file=$(TFVARS_FILE); \
	fi
	@echo "$(GREEN)✓ Changes applied$(NC)"

destroy: workspace-select ## Destroy Terraform infrastructure
	@echo "$(RED)WARNING: This will destroy infrastructure for $(WORKSPACE)!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		terraform destroy -var-file=$(TFVARS_FILE); \
		echo "$(GREEN)✓ Infrastructure destroyed$(NC)"; \
	else \
		echo "$(YELLOW)Destroy cancelled$(NC)"; \
	fi

# Target-specific commands
plan-sources: workspace-select validate ## Plan only data sources
	@echo "$(BLUE)Planning S3 sources for $(WORKSPACE)...$(NC)"
	terraform plan -var-file=$(TFVARS_FILE) -target=module.s3_source

apply-sources: workspace-select ## Apply only data sources
	@echo "$(BLUE)Applying S3 sources for $(WORKSPACE)...$(NC)"
	terraform apply -var-file=$(TFVARS_FILE) -target=module.s3_source

plan-destinations: workspace-select validate ## Plan only destinations
	@echo "$(BLUE)Planning BigQuery destination for $(WORKSPACE)...$(NC)"
	terraform plan -var-file=$(TFVARS_FILE) -target=module.bigquery_destination

apply-destinations: workspace-select ## Apply only destinations
	@echo "$(BLUE)Applying BigQuery destination for $(WORKSPACE)...$(NC)"
	terraform apply -var-file=$(TFVARS_FILE) -target=module.bigquery_destination

plan-connections: workspace-select validate ## Plan only connections
	@echo "$(BLUE)Planning connections for $(WORKSPACE)...$(NC)"
	terraform plan -var-file=$(TFVARS_FILE) -target=module.connections

apply-connections: workspace-select ## Apply only connections
	@echo "$(BLUE)Applying connections for $(WORKSPACE)...$(NC)"
	terraform apply -var-file=$(TFVARS_FILE) -target=module.connections

# State management
state-list: workspace-select ## List Terraform state
	@echo "$(BLUE)Listing Terraform state for $(WORKSPACE)...$(NC)"
	terraform state list

state-show: workspace-select ## Show specific resource (usage: make state-show RESOURCE=<resource>)
	@echo "$(BLUE)Showing state for $(RESOURCE)...$(NC)"
	terraform state show $(RESOURCE)

# Utility commands
clean: ## Clean up plan files
	@echo "$(BLUE)Cleaning up plan files...$(NC)"
	rm -f tfplan-*
	@echo "$(GREEN)✓ Plan files cleaned$(NC)"

refresh: workspace-select ## Refresh Terraform state
	@echo "$(BLUE)Refreshing state for $(WORKSPACE)...$(NC)"
	terraform refresh -var-file=$(TFVARS_FILE)
	@echo "$(GREEN)✓ State refreshed$(NC)"

output: workspace-select ## Show Terraform outputs
	@echo "$(BLUE)Showing outputs for $(WORKSPACE)...$(NC)"
	terraform output

# Test commands
test-validate: ## Run validation tests
	@echo "$(BLUE)Running validation tests...$(NC)"
	@$(MAKE) validate
	@$(MAKE) fmt -s
	@if git diff --quiet; then \
		echo "$(GREEN)✓ All files are properly formatted$(NC)"; \
	else \
		echo "$(RED)✗ Some files need formatting$(NC)"; \
		git diff --name-only; \
		exit 1; \
	fi

test-plan: ## Test plan generation for all environments
	@echo "$(BLUE)Testing plan generation for all environments...$(NC)"
	@for env in dev stage prod; do \
		echo "$(YELLOW)Testing $$env environment...$(NC)"; \
		$(MAKE) ENV=$$env workspace-new; \
		$(MAKE) ENV=$$env plan || exit 1; \
	done
	@echo "$(GREEN)✓ All environment plans generated successfully$(NC)"

test: test-validate test-plan ## Run all tests

# Quick deploy commands
quick-dev: ## Quick deploy to dev environment
	@$(MAKE) ENV=dev workspace-new
	@$(MAKE) ENV=dev plan
	@$(MAKE) ENV=dev apply

quick-stage: ## Quick deploy to stage environment
	@$(MAKE) ENV=stage workspace-new  
	@$(MAKE) ENV=stage plan
	@$(MAKE) ENV=stage apply

quick-prod: ## Quick deploy to prod environment
	@$(MAKE) ENV=prod workspace-new
	@$(MAKE) ENV=prod plan
	@$(MAKE) ENV=prod apply

# Development helpers
dev-setup: ## Setup development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@$(MAKE) init
	@$(MAKE) ENV=dev workspace-new
	@$(MAKE) ENV=dev workspace-select
	@echo "$(GREEN)✓ Development environment ready$(NC)"

# Documentation
docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	@echo "# Terraform Resources" > TERRAFORM_RESOURCES.md
	@echo "" >> TERRAFORM_RESOURCES.md
	@echo "This file lists all Terraform resources in the current workspace." >> TERRAFORM_RESOURCES.md
	@echo "" >> TERRAFORM_RESOURCES.md
	@echo "\`\`\`" >> TERRAFORM_RESOURCES.md
	@terraform state list >> TERRAFORM_RESOURCES.md 2>/dev/null || echo "No state found" >> TERRAFORM_RESOURCES.md
	@echo "\`\`\`" >> TERRAFORM_RESOURCES.md
	@echo "$(GREEN)✓ Documentation generated: TERRAFORM_RESOURCES.md$(NC)"