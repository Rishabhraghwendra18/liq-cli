NPM_BIN:=$(shell npm bin)
BASH_ROLLUP:=$(NPM_BIN)/rollup-bash
PKG_FILES:=package.json package-lock.json
LIQ_SRC:=$(shell find src/ -name "*.sh" -not -name "liq-shell.sh" -not -name "install.sh" -not -name "completion.sh" -not -name "cli.sh")
DIST_FILES:=dist/completion.sh dist/install.sh dist/liq.sh dist/liq-shell.sh

.DELETE_ON_ERROR:

all: $(DIST_FILES)

clean:
	rm liquid-labs-liq-cli-*.tgz
	rm dist/*

.PHONY: all docker-img docker-run clean

dist/completion.sh: src/completion.sh $(PKG_FILES)
	mkdir -p dist
	$(BASH_ROLLUP) $< $@

dist/install.sh: src/install.sh src/lib/_utils.sh $(PKG_FILES)
	mkdir -p dist
	$(BASH_ROLLUP) $< $@

dist/liq-shell.sh: src/liq-shell.sh $(PKG_FILES)
	mkdir -p dist
	$(BASH_ROLLUP) $< $@

dist/liq.sh: src/cli.sh $(PKG_FILES)
	mkdir -p dist
	$(BASH_ROLLUP) $< $@

.ver-cache: package.json
	cat $< | jq -r .version > $@

.docker-img-marker: $(DIST_FILES) Dockerfile .ver-cache
	npm pack
	# TODO: change Dockerfile to a template and inject the version in .ver-cache
	docker build . -t liq
	touch $@

docker-img: .docker-img-marker

docker-run: .docker-img-marker
	docker run --interactive --tty --mount type=bind,source="${HOME}"/.liq,target=/home/liq/.liq liq
