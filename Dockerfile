FROM registry.octogroup.io/devops/dockerbase:foundry

COPY . .

RUN forge build
