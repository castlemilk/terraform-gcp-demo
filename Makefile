.PHONY: init deploy destroy
SHELL := /bin/bash
#❌⚠️✅
# COLORS
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RED		 := $(shell tput -Txterm setaf 1)
CYAN	 := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)
GOOGLE_PROJECT=terraform-gcp-demo-242908
## install dependencies
install:
	@if ! command -v terraform > /dev/null | brew ls --versions $1 > /dev/null; then \
		brew install terraform@0.12; \
	else  \
		echo " ✅  terraform already installed"; \
	fi
	@if ! command -v make > /dev/null; then \
		xcode-select --install; \
	else  \
		echo " ✅ make already installed"; \
	fi
## login to GCP and get default credentials
login:
	@gcloud config set project ${GOOGLE_PROJECT}
	@gcloud auth login
	@gcloud auth application-default login
terraform.init:
	@terraform init

## initialise environment
init: install login terraform.init

apply:
	@GOOGLE_PROJECT=${GOOGLE_PROJECT} terraform apply -auto-approve;

## deploy nginx
deploy: apply
	$(eval ADDRESS=$(shell sh -c "GOOGLE_PROJECT=${GOOGLE_PROJECT} terraform output public_address"))
	@echo " 🌀  waiting for nginx [$(ADDRESS)] to become available..."
	@while [ $$(curl -sL -o /dev/null -w ''%{http_code}'' http://$(ADDRESS) 2>&1) != "200" ]; do printf "."; sleep 5; done
	@read -p "❔  nginx node ready, open (Y/N): " confirm && echo $$confirm | grep -iq "^[yY]" || exit 1
	@open http://$(ADDRESS)

## destroy nginx deployment
destroy:
	GOOGLE_PROJECT=${GOOGLE_PROJECT} terraform destroy -auto-approve

## open nginx endpoint
open:
	$(eval ADDRESS=$(shell sh -c "terraform output public_address"))
	open http://$(ADDRESS)

###Help
## Show help
help:
	@echo ''
	@echo '######################### TERRAFORM-GCP-DEMO #########################'
	@echo ''
	@echo 'Usage:'
	@echo ''
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/(^[a-zA-Z\-\.\_0-9]+:)|(^###[a-zA-Z]+)/ { \
		header = match($$1, /^###(.*)/); \
		if (header) { \
			title = substr($$1, 4, length($$1)); \
			printf "${CYAN}%s${RESET}\n", title; \
		} \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
