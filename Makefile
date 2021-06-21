.DELETE_ON_ERROR:

STAGING:=.build
NPM_BIN:=$(shell npm bin)
BASH_ROLLUP:=$(NPM_BIN)/bash-rollup
CATALYST_SCRIPTS:=$(NPM_BIN)/catalyst-scripts
PKG_FILES:=package.json package-lock.json
LIQ_SRC:=$(shell find src/liq -name "*.sh" -not -name "cli.sh")
TEST_SRC:=$(shell find src/test -name "*.bats")
LIB_CHANGELOG_SRC:=src/liq/actions/work/changelog/index.js $(shell find src/liq/actions/work/changelog/ -name "*.js" -not -name "index.js")
DIST_CHANGELOG_JS:=dist/manage-changelog.js
DIST_FILES:=dist/completion.sh dist/install.sh dist/liq.sh dist/liq-shell.sh dist/liq-source.sh $(DIST_CHANGELOG_JS)

all: $(DIST_FILES)

clean:
	rm -f liquid-labs-liq-cli-*.tgz
	rm -f dist/*
	rm -f npmrc.tmp

.PHONY: all test clean docker-build docker-run docker-debug docker-debug-root docker-publish

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

dist/liq-source.sh: src/liq/source.sh $(LIQ_SRC) $(PKG_FILES)
	mkdir -p dist
	$(BASH_ROLLUP) $< $@

$(DIST_CHANGELOG_JS): $(LIB_CHANGELOG_SRC)
	JS_FILE="$<" JS_OUT="$@" $(CATALYST_SCRIPTS) build

.ver-cache: package.json
	cat $< | jq -r .version > $@

.docker-distro-img-marker: $(DIST_FILES) src/docker/Dockerfile .ver-cache
	@# TODO: Do a version marker with the image pull so we can tell whether we need to go through a whole rebuild or not.
	docker pull ubuntu:latest
	npm pack
	@# TODO: change Dockerfile to a template and inject the version in .ver-cache
	docker build . --target distro --file src/docker/Dockerfile -t liq
	touch $@

docker-build: .docker-distro-img-marker

LIQ_BIND:=--mount type=bind,source="${HOME}"/.liq,target=/home/liq/.liq
SSH_BIND:=--mount type=bind,source="${HOME}"/.ssh,target=/home/liq/.ssh
CONFIG_BIND:=--mount type=bind,source="${HOME}"/.config,target=/home/liq/.config
docker-run: .docker-distro-img-marker
	docker run --interactive --tty  $(LIQ_BIND) $(SSH_BIND) $(CONFIG_BIND) liq

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

# See docker-build for further details
.docker-test-img-marker: .docker-distro-img-marker $(TEST_SRC) $(NPMRC_BATS_MARKER)
	# SENSITIVE DATA -----------------------------------------
	# TODO: https://github.com/liquid-labs/liq-cli/issues/250
	[ -e "$${HOME}/.npmrc" ] && cp "$${HOME}"/.npmrc ./npmrc.tmp # not possible to follow symlinks from Dockerfile :(
	docker build . --target test --file src/docker/Dockerfile -t liq-test \
		|| { rm npmrc.tmp; exit 1; }
	rm npmrc.tmp
	# END SENSITIVE DATA -------------------------------------
	touch $@

test: .docker-test-img-marker
	docker run --tty liq-test

DOCKER_DEBUG_CMD_BASE:=docker run --interactive --tty --mount type=bind,source="$${PWD}/docker-tmp",target=/home/liq/docker-tmp --entrypoint /bin/bash
docker-debug: .docker-test-img-marker
	mkdir -p docker-tmp
	$(DOCKER_DEBUG_CMD_BASE) liq-test

docker-debug-root: .docker-test-img-marker
	mkdir -p docker-tmp
	$(DOCKER_DEBUG_CMD_BASE) -u root liq-test

docker-publish:
	@cat "$${HOME}/.docker/config.json" | jq '.auths["https://index.docker.io/v1/"]' | grep -q '{}' || { echo -e "It does not appear that you're logged into docker.io. Try:\ndocker login --username=<your user name>"; exit 1; }
	@echo "Login confirmed..."
