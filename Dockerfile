FROM debian:bookworm
EXPOSE 8545
RUN apt update -y
RUN apt install -y curl git
RUN curl -L https://foundry.paradigm.xyz | bash
RUN /root/.foundry/bin/foundryup
ADD ./anvilup.sh /root/.foundry/bin/anvilup.sh
COPY . /app
WORKDIR /app
RUN /root/.foundry/bin/forge install
RUN /root/.foundry/bin/forge build
ENTRYPOINT ["/root/.foundry/bin/anvilup.sh"]