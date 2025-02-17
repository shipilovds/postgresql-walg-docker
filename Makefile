.PHONY: all deb deb-clean docker docker-build docker-retag docker-pushclean
.EXPORT_ALL_VARIABLES:


REGISTRY_USER          ?= shipilovds
REGISTRY_ADDR          ?= ghcr.io/$(REGISTRY_USER)
#POSTGRES_VERSION       ?= 14.16
#POSTGRES_VERSION       ?= 15.11
#POSTGRES_VERSION       ?= 16.7
POSTGRES_VERSION       ?= 17.3
BASE_DIST              ?= bookworm
REVISION               ?= 1.1
POSTGRES_IMAGE_NAME    ?= $(REGISTRY_ADDR)/postgres-walg
POSTGRES_IMAGE_TAG     ?= $(POSTGRES_VERSION)-$(REVISION)
WALG_WORKER_IMAGE_NAME ?= $(REGISTRY_ADDR)/wal-g-worker
WALG_WORKER_IMAGE_TAG  ?= $(REVISION)
WALG_UTILS_RELEASE     ?= 1.0.1

#============================================================================#
#============================| General Targets |=============================#
#============================================================================#
all: docker deb

clean: deb-clean

#============================================================================#
#=============================| Docker Targets |=============================#
#============================================================================#
docker: docker-build docker-retag docker-push

docker-build:
	docker compose build --parallel --pull

docker-retag: docker-build
	docker tag $(POSTGRES_IMAGE_NAME):$(POSTGRES_IMAGE_TAG) $(POSTGRES_IMAGE_NAME):latest
	docker tag $(WALG_WORKER_IMAGE_NAME):$(WALG_WORKER_IMAGE_TAG) $(WALG_WORKER_IMAGE_NAME):latest

docker-push: docker-retag
	docker push $(POSTGRES_IMAGE_NAME):$(POSTGRES_IMAGE_TAG)
	docker push $(POSTGRES_IMAGE_NAME):latest
	docker push $(WALG_WORKER_IMAGE_NAME):$(WALG_WORKER_IMAGE_TAG)
	docker push $(WALG_WORKER_IMAGE_NAME):latest

#============================================================================#
#==============================| Deb Targets |===============================#
#============================================================================#
deb: wal-g-utils_$(WALG_UTILS_RELEASE)-1_all.deb

wal-g-utils_$(WALG_UTILS_RELEASE)-1_all.deb:
	$(eval _CONTANER_ID := $(shell docker create deb))
	docker cp $(_CONTANER_ID):/build/wal-g-utils_$(WALG_UTILS_RELEASE)-1_all.deb .
	docker rm $(_CONTANER_ID)

deb-clean:
	rm -f wal-g-utils_$(WALG_UTILS_RELEASE)-1_all.deb
