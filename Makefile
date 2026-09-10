KEYCLOAK_HTTP_PORT=8080
KEYCLOAK_HEALTH_PORT=9000
COMPOSE_PROJECT_NAME=moc-keycloak

export KEYCLOAK_HTTP_PORT KEYCLOAK_HEALTH_PORT COMPOSE_PROJECT_NAME

all:
	@echo "Run one of `make init-local` or `make init-remote`"

define BACKEND_LOCAL
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
endef

define VARS_LOCAL
KEYCLOAK_URL="http://localhost:$(KEYCLOAK_HTTP_PORT)"
KEYCLOAK_USER_NAME="admin"
KEYCLOAK_PASSWORD="admin"
KEYCLOAK_CLIENT_ID="admin-cli"
use_secrets_manager=false
endef

init-local:
	$(file >backend_override.tf,$(BACKEND_LOCAL))
	$(file >local_test.auto.tfvars,$(VARS_LOCAL))
	test -f imports.tf && mv imports.tf imports.tf.disabled || :
	tofu init -reconfigure

init-remote:
	@rm -f backend_override.tf
	@rm -f local_test.auto.tfvars
	test -f imports.tf.disabled && mv imports.tf.disabled imports.tf || :
	echo no | tofu init -reconfigure

setup:
	docker compose up -d

wait:
	@echo "Waiting for keycloak..."; \
		until curl -o /dev/null -sf http://localhost:$(KEYCLOAK_HEALTH_PORT)/health; do sleep 1; done; \
		echo "Keycloak is ready."

teardown:
	docker compose down -v
	rm -f terraform.tfstate*

reset: teardown setup

bootstrap: teardown setup init-local apply

apply: wait validate
	@rm -f stage1.log stage2.log stage3.log
	@echo "Applying configuration..."
	@echo "  stage 1..."
	tofu apply -no-color -auto-approve -var first_broker_login_flow='first broker login' -target keycloak_realm.moc > stage1.log 2>&1
	@echo "  stage 2..."
	tofu apply -no-color -auto-approve -var first_broker_login_flow='first broker login' > stage2.log 2>&1
	@echo "  stage 3..."
	tofu apply -no-color -auto-approve > stage3.log 2>&1
	@echo "All done."

validate:
	tofu validate

.PHONY: init-local init-remote all setup teardown apply wait validate
