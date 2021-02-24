FROM ubuntu

RUN apt-get update
# RUN apt-get install bash-completion -y
RUN apt-get install make wget -y # build-essential -y

RUN wget https://ftp.gnu.org/gnu/bash/bash-5.1.tar.gz
RUN tar xf bash-5.1.tar.gz
RUN echo $PWD
WORKDIR ./bash-5.1
RUN apt-get install gcc -y
RUN ./configure
RUN make
RUN make install

ADD ./dist/liq.sh /usr/bin/liq
ADD ./src/liq-shell.sh /usr/bin/liq-shell

RUN chmod +x /usr/bin/liq
RUN chmod +x /usr/bin/liq-shell

RUN useradd -ms /bin/bash liq
USER liq
WORKDIR /home/liq

RUN mkdir src playground .liq
ADD ./bash-preexec.sh /home/liq/bash-preexec.sh
ADD ./src/completion.sh /home/liq/src/completion.sh

ENTRYPOINT ["/usr/bin/liq-shell"]
