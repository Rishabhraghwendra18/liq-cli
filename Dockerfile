FROM ubuntu AS build

# install necessary packages for build
RUN apt-get update && apt-get install -y \
  gcc \
  make \
  wget \
  && rm -rf /var/lib/apt/lists/*

# build and install bash 5
WORKDIR /tmp
RUN wget https://ftp.gnu.org/gnu/bash/bash-5.1.tar.gz \
  && tar xf bash-5.1.tar.gz
WORKDIR /tmp/bash-5.1
RUN ./configure \
  && make

# Start new, reduced layer image
FROM ubuntu:latest

# install necessary system packages
RUN apt-get update && apt-get install -y \
  curl \
  jq \
  git \
  make \
  npm \
  && rm -rf /var/lib/apt/lists/*
# To get node 12 (instead of 8)
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs

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

# we could remove 'make' here...

# setup liq user
RUN useradd -ms /bin/bash liq
USER liq

ENTRYPOINT ["/usr/bin/liq-shell"]
# ENTRYPOINT ["/bin/bash"]
