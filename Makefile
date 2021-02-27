.DELETE_ON_ERROR:

STAGING:=.build
NPM_BIN:=$(shell npm bin)
BASH_ROLLUP:=$(NPM_BIN)/rollup-bash
PKG_FILES:=package.json package-lock.json
LIQ_SRC:=$(shell find src/liq -name "*.sh" -not -name "cli.sh")
TEST_SRC:=$(shell find src/test -name "*.bats")
DIST_FILES:=dist/completion.sh dist/install.sh dist/liq.sh dist/liq-shell.sh

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

# The @bats-core/bats NPM package is hosted on github, so we check to make sure that we (at least try) to have access
# setup.
NPMRC_BATS_MARKER:=$(STAGING)/checks/npmrc-bats
NPMRC_BATS_CHECK:=src/build-support/npmrc-bats-config.check.sh
$(NPMRC_BATS_MARKER): $(NPMRC_BATS_CHECK) ${HOME}/.npmrc
	$<
	mkdir -p $(dir $@)
	touch $@

# This has the effect of printing out advice on how to set up the file. So, it's a cure, just not an automated one.
# TODO: We could try to generate this token programatically if they've set up general account access.
${HOME}/.npmrc:
	$(NPMRC_BATS_CHECK)

.docker-test-img-marker: .docker-distro-img-marker $(TEST_SRC) $(NPMRC_BATS_MARKER)
	# SENSITIVE DATA -----------------------------------------
	# TODO: https://github.com/Liquid-Labs/liq-cli/issues/250
	[ -e "$${HOME}/.npmrc" ] && cp "$${HOME}"/.npmrc ./npmrc.tmp # not possible to follow symlinks from Dockerfile :(
	docker build . --target test --file src/docker/Dockerfile -t liq-test || { rm npmrc.tmp; exit 1; }
	rm npmrc.tmp
	# END SENSITIVE DATA -------------------------------------
	touch $@

docker-test: .docker-test-img-marker
	docker run --tty liq-test

docker-debug: .docker-test-img-marker
	mkdir -p docker-tmp
	docker run --interactive --tty --mount type=bind,source="${PWD}/docker-tmp",target=/home/liq/docker-tmp --entrypoint /bin/bash liq-test
