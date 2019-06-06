.PHONY: bootstrap build cluster-create cluster-delete
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
# install dependencies
install:
	brew install terraform
	xcode-select --install &>/dev/null
# login to GCP
login:
	gcloud config set project ${GOOGLE_PROJECT}
	gcloud auth login
	gcloud auth application-default login

# deploy nginx
deploy:
	GOOGLE_PROJECT=${GOOGLE_PROJECT} terraform apply -auto-approve

# destroy nginx deployment
destroy:
	GOOGLE_PROJECT=${GOOGLE_PROJECT} terraform destroy -auto-approve

get.public_addres:
	ADDRESS=`terraform output public_address`
# open nginx endpoint
open: get.public_addres
	open http://$(ADDRESSS)



###Help
## Show help
help:
	@echo ''
	@echo '######################### TERRAFORM-GCP-DEMO #########################'
	@echo ''
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
