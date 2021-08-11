default: help


### build apiseven:
.PHONY: build-apiseven-rpm
build-apiseven-rpm:
	mkdir -p ${PWD}/build/rpm
	docker build -t api7/apiseven:$(version) --build-arg checkout_v=$(checkout) -f ./dockerfiles/Dockerfile.apiseven .
	docker run -d --name dockerInstance --net="host" api7/apiseven:$(version)
	docker cp dockerInstance:/tmp/build/output/ ${PWD}/build/rpm
	docker cp dockerInstance:/usr/bin/openresty ${PWD}/build/rpm/output/apisix/usr/bin
	docker cp dockerInstance:/usr/local/openresty/ ${PWD}/build/rpm/output/apisix/usr/local
	# Mapping test cases and Makefile files are used to install the rpm package test
	mkdir -p ${PWD}/build/rpm/output/apisix/t
	docker cp dockerInstance:/apisix/Makefile ${PWD}/build/rpm/output/apisix
	docker cp dockerInstance:/apisix/t/ ${PWD}/build/rpm/output/apisix
	docker system prune -a -f

ifeq ($(plugin_paths),"")
	# RPM package without custom plugins
	./utils/build.sh "$(role)" "$(version)"
else
	# RPM package with custom plugins.
	# The custom plugins are merged into the
	# "${PWD}/build/rpm/output/apisix/" directory.
	./utils/build.sh "$(role)" "$(version)" "$(plugin_paths)"
endif

### build rpm for apiseven:
.PHONY: package-apiseven-rpm
package-apiseven-rpm:
	fpm -f -s dir -t rpm \
		-n apiseven-$(role) \
		-a `uname -i` \
		-v $(version) \
		--iteration $(iteration) \
		--description 'APISEVEN is a distributed gateway for APIs and Microservices, focused on high performance and reliability.' \
		--license "ASL 2.0" \
		-C ${PWD}/build/rpm/output/apisix/ \
		-p ${PWD}/output/ \
		--url 'https://www.apiseven.com/'

### help:                 Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'
