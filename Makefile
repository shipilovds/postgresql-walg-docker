.PHONY: all login build retag push cleanup
.EXPORT_ALL_VARIABLES:


REGISTRY_USER         ?= shipilovds
REGISTRY_PASSWORD     ?= CHANGE_ME
REGISTRY_ADDR         ?= ghcr.io/$(REGISTRY_USER)
POSTGRES_VERSION      ?= 12.7-buster
POSTGRES_IMAGE_NAME   ?= $(REGISTRY_ADDR)/postgres
POSTGRES_IMAGE_TAG    ?= 12-walg
WALG_RELEASE          ?= v1.1 # TODO: v2.0.1
YACRON_RELEASE        ?= 0.16.0 # TODO: 0.19.0

all: push

login:
	@echo $(REGISTRY_PASSWORD) | docker login -u $(REGISTRY_USER) --password-stdin $(REGISTRY_ADDR)

build: login
	docker-compose build --force-rm --parallel --pull

retag: build
	docker tag postgres:$(POSTGRES_IMAGE_TAG) $(POSTGRES_IMAGE_NAME):$(POSTGRES_IMAGE_TAG)
	docker tag postgres:$(POSTGRES_IMAGE_TAG) $(POSTGRES_IMAGE_NAME):latest

push: retag
	docker push $(POSTGRES_IMAGE_NAME):$(POSTGRES_IMAGE_TAG)
	docker push $(POSTGRES_IMAGE_NAME):latest

cleanup:
	docker logout $(REGISTRY_ADDR)
