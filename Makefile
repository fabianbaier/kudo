
# Image URL to use all building/pushing image targets
DOCKER_TAG ?= $(shell git rev-parse HEAD)
DOCKER_IMG ?= kudobuilder/controller
GIT_VERSION_PATH := github.com/kudobuilder/kudo/pkg/version.gitVersion
GIT_VERSION := $(shell git describe --abbrev=0 --tags)
GIT_COMMIT_PATH := github.com/kudobuilder/kudo/pkg/version.gitCommit
GIT_COMMIT := $(shell git rev-parse HEAD)
SOURCE_DATE_EPOCH := $(shell git show -s --format=format:%ct HEAD)
BUILD_DATE_PATH := github.com/kudobuilder/kudo/pkg/version.buildDate
BUILD_DATE := $(shell date -r ${SOURCE_DATE_EPOCH} '+%Y-%m-%dT%H:%M:%SZ')

all: test manager

deps:
	go install github.com/kudobuilder/kudo/vendor/github.com/golang/dep/cmd/dep
	dep check -skip-vendor
	go install github.com/kudobuilder/kudo/vendor/golang.org/x/tools/cmd/goimports
	go install github.com/kudobuilder/kudo/vendor/golang.org/x/lint/golint

# Run tests
test: generate deps fmt vet lint imports manifests
	go test ./pkg/... ./cmd/... -coverprofile cover.out

check-formatting: generate deps vet lint
	./test/formatting.sh

# Build manager binary
manager: generate fmt vet
	go build -ldflags "-X ${GIT_VERSION_PATH}=${GIT_VERSION} \
             	-X ${GIT_COMMIT_PATH}=${GIT_COMMIT} \
             	-X ${BUILD_DATE_PATH}=${BUILD_DATE}" \
             	-o bin/manager github.com/kudobuilder/kudo/cmd/manager

# Run against the configured Kubernetes cluster in ~/.kube/config
run: generate fmt vet
	go run -ldflags "-X ${GIT_VERSION_PATH}=${GIT_VERSION} \
                     -X ${GIT_COMMIT_PATH}=${GIT_COMMIT} \
                     -X ${BUILD_DATE_PATH}=${BUILD_DATE}" ./cmd/manager/main.go

# Install CRDs into a cluster
install: manifests
	kubectl apply -f config/crds

# Deploy controller in the configured Kubernetes cluster in ~/.kube/config
deploy: manifests
	kubectl apply -f config/crds
	kustomize build config/default | kubectl apply -f -

# Generate manifests e.g. CRD, RBAC etc.
manifests:
	go run vendor/sigs.k8s.io/controller-tools/cmd/controller-gen/main.go all

# Install kudoctl
cli:
	go install -ldflags "-X ${GIT_VERSION_PATH}=${GIT_VERSION} \
                         -X ${GIT_COMMIT_PATH}=${GIT_COMMIT} \
                         -X ${BUILD_DATE_PATH}=${BUILD_DATE}" ./cmd/kubectl-kudo

# Run go fmt against code
fmt:
	go fmt ./pkg/... ./cmd/...

# Run go vet against code
vet:
	go vet ./pkg/... ./cmd/...

# Run go lint against code
lint: 
	golint ./pkg/... ./cmd/...

# Run go imports against code
imports:
	goimports ./pkg/ ./cmd/

# Generate code
generate:
	go generate ./pkg/... ./cmd/...

# Build the docker image
docker-build: generate fmt vet manifests
	docker build --build-arg git_version_arg=${GIT_VERSION_PATH}=${GIT_VERSION} \
	--build-arg git_commit_arg=${GIT_COMMIT_PATH}=${GIT_COMMIT} \
	--build-arg build_date_arg=${BUILD_DATE_PATH}=${BUILD_DATE} . -t ${DOCKER_IMG}:${DOCKER_TAG}
	docker tag ${DOCKER_IMG}:${DOCKER_TAG} ${DOCKER_IMG}:${GIT_VERSION}
	docker tag ${DOCKER_IMG}:${DOCKER_TAG} ${DOCKER_IMG}:latest
	@echo "updating kustomize image patch file for manager resource"
	sed -i'' -e 's@image: .*@image: '"${DOCKER_IMG}:${GIT_VERSION}"'@' ./config/default/manager_image_patch.yaml

# Push the docker image
docker-push:
	docker push ${DOCKER_IMG}:${DOCKER_TAG}
    docker push ${DOCKER_IMG}:${GIT_VERSION}
   	docker push ${DOCKER_IMG}:latest
