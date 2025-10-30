.PHONY: help init plan apply destroy fmt validate clean

help: ## Pokazuje pomoc
	@echo "Dostępne komendy:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Inicjalizuje Terraform
	cd terraform && terraform init

plan: ## Wykonuje terraform plan
	cd terraform && terraform plan

apply: ## Wdraża infrastrukturę
	cd terraform && terraform apply

destroy: ## Usuwa całą infrastrukturę
	cd terraform && terraform destroy

fmt: ## Formatuje kod Terraform
	cd terraform && terraform fmt -recursive

validate: ## Waliduje konfigurację Terraform
	cd terraform && terraform validate

clean: ## Czyści lokalne pliki Terraform
	find . -type d -name ".terraform" -exec rm -rf {} +
	find . -type f -name "*.tfstate*" -delete
	find . -type f -name ".terraform.lock.hcl" -delete

output: ## Pokazuje outputy
	cd terraform && terraform output

ssh: ## Łączy się z EC2 przez SSH
	@cd terraform && ssh -i ~/.ssh/$$(terraform output -raw key_name).pem ubuntu@$$(terraform output -raw ec2_public_ip)

logs: ## Pokazuje logi user-data z EC2
	@cd terraform && ssh -i ~/.ssh/$$(terraform output -raw key_name).pem ubuntu@$$(terraform output -raw ec2_public_ip) "sudo cat /var/log/user-data.log"

cost: ## Szacuje koszty infrastruktury (wymaga infracost)
	cd terraform && infracost breakdown --path .

security-scan: ## Skanuje bezpieczeństwo (wymaga tfsec)
	cd terraform && tfsec .

docs: ## Generuje dokumentację (wymaga terraform-docs)
	cd terraform && terraform-docs markdown table --output-file README.md .