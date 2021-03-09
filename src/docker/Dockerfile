###
# build image
###
FROM ubuntu:latest AS build

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# install necessary packages for build
RUN apt-get update && apt-get install -y \
  gcc \
  make \
  wget \
  && rm -rf /var/lib/apt/lists/*

# build and install bash 5; needed for 'initial word completion' support to make the shell magic work.
WORKDIR /tmp
RUN wget https://ftp.gnu.org/gnu/bash/bash-5.1.tar.gz \
  && tar xf bash-5.1.tar.gz
WORKDIR /tmp/bash-5.1
RUN ./configure \
  && make


###
# distro image
###
FROM ubuntu:latest AS distro

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# install necessary system packages
RUN apt-get update && apt-get install -y \
  curl \
  git \
  hub \
  jq \
  make \
  npm \
\
# bsdmainutils is where we get 'column' \
  bsdmainutils \
  uuid-runtime
# To get node 14 (instead of 10)
# TODO: for production builds, force user to review script and/or compare file hash against list of reviewed hashes
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs
RUN apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
# Use NPM to update npm.
RUN npm install -g npm
# The yalc install can take awhile, so we stage it here
RUN npm install -g yalc

# install bash 5.1
COPY --from=build /tmp/bash-5.1 /root/bash-5.1
WORKDIR /root/bash-5.1
RUN make install

# install liq and liq-shell
WORKDIR /root
# TODO: in the next step, we'll make the Dockerfile ephemerally generated from a template and insert the current version here, using make to create a local pack file
COPY ./liquid-labs-liq-cli-1.0.0-prototype.15.tgz /root/liquid-labs-liq-cli-1.0.0-prototype.15.tgz
RUN npm install -g --unsafe-perm ./liquid-labs-liq-cli-1.0.0-prototype.15.tgz
# RUN npm install @liquid-labs/liq-cli

# we could remove 'make' here... yes?

# setup liq user
RUN useradd -ms /bin/bash liq
USER liq
WORKDIR /home/liq

ENTRYPOINT ["/usr/bin/liq-shell"]

###
# test image
###
FROM distro AS test

USER root
RUN apt-get update && apt-get install -y \
  parallel \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

# When trying to get bash test coverage support, we installed ruby and bashconv here:
#  ruby # part of apt-get install
# RUN gem install bashcov

# nmprc reference: https://docs.npmjs.com/cli/v7/configuring-npm/npmrc
# SENSITIVE DATA ---------------------------------
# Note npmrc.tmp is staged by the Makefile prior to the test image build.
# TODO: https://github.com/liquid-labs/liq-cli/issues/250

COPY npmrc.tmp /root/.npmrc
COPY --chown=liq:liq ./npmrc.tmp /home/liq/.npmrc
RUN npm install -g @bats-core/bats
RUN rm /root/.npmrc /home/liq/.npmrc

# END SENSITIVE DATA -----------------------------

USER liq
WORKDIR /home/liq
RUN mkdir -p ./lib \
  && git clone https://github.com/bats-core/bats-support.git lib/bats-support \
  && git clone https://github.com/bats-core/bats-assert.git lib/bats-assert

# Copy tests last as they are mast likely to change
COPY --chown=liq:liq ./src/test/* ./test/


ENTRYPOINT ["/usr/bin/bats", "--jobs", "2", "--report-formatter", "junit", "--output" , ".", "test"]
