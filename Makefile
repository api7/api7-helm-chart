KIND_CLUSTER_NAME ?= api7-test
KUBECONFIG ?= /tmp/$(KIND_CLUSTER_NAME).kubeconfig

IMAGE_REGISTRY ?= "api7ee.azurecr.io"
DASHBOARD_IMAGE_REPOSITORY ?= "api7-dashboard"
DASHBOARD_IMAGE_TAG ?= "2.13.2302"
GATEWAY_IMAGE_REPOSITORY ?= "api7-gateway"
GATEWAY_IMAGE_TAG ?= "2.13.2302"

.PHONY: kind-up
kind-up: ## Create the Kubernetes cluster by kind
	@KIND_CLUSTER_NAME=$(KIND_CLUSTER_NAME) ./test/scripts/kind.sh
	@kind get kubeconfig --name ${KIND_CLUSTER_NAME} > ${KUBECONFIG}

.PHONY: e2e-test
e2e-test: kind-up ## Run e2e test cases
	@kind load docker-image --nodes $(KIND_CLUSTER_NAME)-worker --name $(KIND_CLUSTER_NAME) $(IMAGE_REGISTRY)/$(DASHBOARD_IMAGE_REPOSITORY):$(DASHBOARD_IMAGE_TAG)
	@kind load docker-image --nodes $(KIND_CLUSTER_NAME)-worker --name $(KIND_CLUSTER_NAME) $(IMAGE_REGISTRY)/$(GATEWAY_IMAGE_REPOSITORY):$(GATEWAY_IMAGE_TAG)
	@cd test/e2e && go env -w GOFLAGS="-mod=mod" && ginkgo -r $(CLI_TEST_TAGS)
