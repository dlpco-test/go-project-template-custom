############################
# Build and Deploy targets #
############################

#change to the actual project name
PROJECT = projeto-template
#change to the actual project name
RELEASE = projeto-template

VCS_REF = $(if $(CIRCLE_SHA1),$(CIRCLE_SHA1),$(shell git rev-parse HEAD))
TAG ?= $(subst  /,-,$(if $(CIRCLE_TAG),$(CIRCLE_TAG),$(if $(CIRCLE_BRANCH),$(CIRCLE_BRANCH),$(shell git rev-parse --abbrev-ref HEAD))))
TRIGGER_KIND ?= $(if $(CIRCLE_TAG),PRODUCTION,HOMOLOG)
REGISTRY_PREFIX ?= stonebankingregistry347.azurecr.io/
IMAGE = $(REGISTRY_PREFIX)dlpco/$(RELEASE)

#For Elixir's projects
HEX_STONE_URL ?= $(if $(CIRCLECI),https://$(HEX_STONE_USER):$(HEX_STONE_PASS)@$(HEX_STONE_HOST),https://hex-stone.sandbox.stone.credit)

.PHONY: deploy
deploy: 
	@cd deploy; helmfile -e $(ENVIRONMENT) apply

.PHONY: diff
diff: 
	@cd deploy; helmfile -e $(ENVIRONMENT) diff

# For ELixir-s projects add the flag "--build-arg HEX_STONE_URL=$(HEX_STONE_URL)" to the 'docker image build' command:
# .PHONY: docker-image
# docker-image:
# 	docker image build \
# 		--pull \
# 		--tag $(IMAGE):$(TAG) \
# 		--label "stone.banking.vcs-ref=$(VCS_REF)" \
# 		--build-arg HEX_STONE_URL=$(HEX_STONE_URL) \
# 		.

.PHONY: docker-image
docker-image:
	docker image build \
		--pull \
		--tag $(IMAGE):$(TAG) \
		--label "stone.banking.vcs-ref=$(VCS_REF)" \
		.

.PHONY: docker-push
docker-push:
	docker image push $(IMAGE):$(TAG)

.PHONY: docker-build-and-push-image
docker-build-and-push-image: docker-image docker-push

.PHONY: trigger-deploy
trigger-deploy:
	curl -H "Accept: application/vnd.github.everest-preview+json" \
	-H "Authorization: token $(BANKING_BOT_GITHUB_TOKEN)" \
	--request POST \
	--data '{"event_type": "$(PROJECT):$(TRIGGER_KIND)", "client_payload": {"tag": "$(TAG)"}' \
	https://api.github.com/repos/dlpco/$(PROJECT)/dispatches
