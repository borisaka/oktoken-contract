FROM debian:bookworm
EXPOSE 8545
# install foundry
RUN apt-get update -y
RUN apt-get install -y curl git tini
RUN curl -L https://foundry.paradigm.xyz | bash
RUN /root/.foundry/bin/foundryup
# install tini
# ENV TINI_VERSION v0.19.0
# ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
# RUN chmod +x /tini
# install app
ADD ./anvilup.sh /root/.foundry/bin/anvilup.sh
COPY . /app
WORKDIR /app
RUN /root/.foundry/bin/forge install
RUN /root/.foundry/bin/forge build



ENTRYPOINT ["tini", "--"]
CMD ["/root/.foundry/bin/anvilup.sh"]