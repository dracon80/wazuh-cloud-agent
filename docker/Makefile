DOCKER_USERNAME ?= liquiddragon
APPLICATION_NAME ?= wazuh-cloud-agent
GIT_HASH ?= $(shell git log --format="%h" -n 1)

_BUILD_ARGS_TAG ?= ${GIT_HASH}
_BUILD_ARGS_RELEASE_TAG ?= 4.7.3-1.x86_64
_BUILD_ARGS_DOCKERFILE ?= Dockerfile
_BUILD_ENVIRONMENT ?= production

_builder:
	docker build --tag ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG} --build-arg ENVIRONMENT=${_BUILD_ENVIRONMENT} --build-arg AGENT_VERSION=${_BUILD_ARGS_RELEASE_TAG} -f ${_BUILD_ARGS_DOCKERFILE} ${LOCAL_WORKSPACE_FOLDER}/

_pusher:
	docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG}

_releaser:
	docker pull ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG}
	docker tag  ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG} ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_RELEASE_TAG}
	docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_RELEASE_TAG}

_debuger:
	docker run -it --rm --entrypoint="/bin/bash" \
		--mount type=bind,source=${LOCAL_WORKSPACE_FOLDER}/docker/.secrets/client.keys,target=/var/ossec/etc/client.keys,readonly \
		--mount type=bind,source=${LOCAL_WORKSPACE_FOLDER}/docker/.secrets/config,target=/wazuh-agent/config,readonly \
		--mount type=bind,source=${LOCAL_WORKSPACE_FOLDER}/wazuh-agent/update_ossec.sh,target=/wazuh-agent/update_ossec.sh,readonly \
		${DOCKER_USERNAME}/${APPLICATION_NAME}:development

_run:
	docker run -it --rm \
		--mount type=bind,source=${LOCAL_WORKSPACE_FOLDER}/docker/.secrets/client.keys,target=/var/ossec/etc/client.keys,readonly \
		--mount type=bind,source=${LOCAL_WORKSPACE_FOLDER}/docker/.secrets/config,target=/wazuh-agent/config,readonly \
		${DOCKER_USERNAME}/${APPLICATION_NAME}:development

build:
	$(MAKE) _builder \
		-e _BUILD_ENVIRONMENT="production"

build_debug:
	$(MAKE) _builder \
		-e _BUILD_ENVIRONMENT="development"\
		-e _BUILD_ARGS_TAG="development"
debug:
	$(MAKE) build_debug
	$(MAKE) _debuger

run:
	$(MAKE) build_debug
	$(MAKE) _run

push:
	$(MAKE) _pusher

release:
	$(MAKE) _releaser

build_%:
	$(MAKE) _builder \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}" \
		-e _BUILD_ARGS_DOCKERFILE="Dockerfile.$*" \
		-e _DOCKER_BUILD_ARGS="production"

build_debug%:
	$(MAKE) _builder \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}" \
		-e _BUILD_ARGS_DOCKERFILE="Dockerfile.$*" \
		-e _DOCKER_BUILD_ARGS="development"

push_%:
	$(MAKE) _pusher \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}"

release_%:
	$(MAKE) _releaser \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}" \
		-e _BUILD_ARGS_RELEASE_TAG="$*-latest"