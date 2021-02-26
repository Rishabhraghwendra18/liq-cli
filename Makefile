NPM_BIN:=$(shell npm bin)
BASH_ROLLUP:=$(NPM_BIN)/rollup-bash
PKG_FILES:=package.json package-lock.json
LIQ_SRC:=$(shell find src/liq -name "*.sh" -not -name "cli.sh")
DIST_FILES:=dist/completion.sh dist/install.sh dist/liq.sh dist/liq-shell.sh
DOCKER_DISTRO_FILE:=src/docker-distro/Dockerfile

.DELETE_ON_ERROR:

all: $(DIST_FILES)

clean:
	rm liquid-labs-liq-cli-*.tgz
	rm dist/*

.PHONY: all docker-img docker-run clean

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

.docker-img-marker: $(DIST_FILES) $(DOCKER_DISTRO_FILE) .ver-cache
	npm pack
	# TODO: change Dockerfile to a template and inject the version in .ver-cache
	docker build . --file "$(DOCKER_DISTRO_FILE)" -t liq
	touch $@

docker-img: .docker-img-marker

docker-run: .docker-img-marker
	docker run --interactive --tty --mount type=bind,source="${HOME}"/.liq,target=/home/liq/.liq liq
