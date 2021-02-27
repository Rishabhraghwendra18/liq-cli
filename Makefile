NPM_BIN:=$(shell npm bin)
BASH_ROLLUP:=$(NPM_BIN)/rollup-bash
PKG_FILES:=package.json package-lock.json
LIQ_SRC:=$(shell find src/liq -name "*.sh" -not -name "cli.sh")
TEST_SRC:=$(shell find src/test -name "*.bats")
DIST_FILES:=dist/completion.sh dist/install.sh dist/liq.sh dist/liq-shell.sh

.DELETE_ON_ERROR:

all: $(DIST_FILES)

clean:
	rm liquid-labs-liq-cli-*.tgz
	rm dist/*
	rm npmrc.tmp

.PHONY: all docker-img docker-run docker-test docker-debug clean

dist/completion.sh: src/completion/completion.sh $(PKG_FILES)
	mkdir -p dist
	$(BASH_ROLLUP) $< $@

dist/install.sh: src/install/install.sh src/liq/lib/_utils.sh $(PKG_FILES)
	mkdir -p dist
	$(BASH_ROLLUP) $< $@

dist/liq-shell.sh: src/liq-shell/liq-shell.sh src/liq-shell/bash-preexec.sh $(PKG_FILES)
	mkdir -p dist
	$(BASH_ROLLUP) $< $@

dist/liq.sh: src/liq/cli.sh $(LIQ_SRC) $(PKG_FILES)
	mkdir -p dist
	$(BASH_ROLLUP) $< $@

.ver-cache: package.json
	cat $< | jq -r .version > $@

.docker-distro-img-marker: $(DIST_FILES) src/docker/Dockerfile .ver-cache
	npm pack
	# TODO: change Dockerfile to a template and inject the version in .ver-cache
	docker build . --target distro --file src/docker/Dockerfile -t liq
	touch $@

docker-img: .docker-distro-img-marker

docker-run: .docker-distro-img-marker
	docker run --interactive --tty --mount type=bind,source="${HOME}"/.liq,target=/home/liq/.liq liq

.docker-test-img-marker: .docker-distro-img-marker $(TEST_SRC)
	cp "${HOME}"/.npmrc npmrc.tmp
	docker build . --target test --file src/docker/Dockerfile -t liq-test
	# rm npmrc.tmp
	touch $@

docker-test: .docker-test-img-marker
	docker run --tty liq-test

docker-debug: .docker-test-img-marker
	docker run --interactive --tty --entrypoint /bin/bash liq-test
