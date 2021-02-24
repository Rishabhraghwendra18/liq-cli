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
FROM ubuntu

# install bash 5.1
COPY --from=build /tmp/bash-5.1 /tmp/bash-5.1
WORKDIR /tmp/bash-5.1
RUN make install

# install necessary system packages
RUN apt-get update && apt-get install -y \
  jq \
  git \
  nodjs \
  npm \
  && rm -rf /var/lib/apt/lists/*

# setup liq user
RUN useradd -ms /bin/bash liq
USER liq

# install liq and liq-shell
WORKDIR /home/liq
RUN npm -i @liquid-labs/liq-cli

ENTRYPOINT ["/usr/bin/liq-shell"]
