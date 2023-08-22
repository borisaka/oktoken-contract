FROM anyday/foundry

COPY . .

RUN forge build
