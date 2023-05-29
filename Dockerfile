FROM node:lts-alpine AS source

RUN apk add openssl && \
    openssl req -x509\
    -nodes\
    -days 30\
    -newkey rsa:4096\
    -keyout /localhost.key\
    -out /localhost.crt\
    -subj "/C=RU/O=Slurm/OU=Slurm/CN=localhost"

WORKDIR /app
COPY . .

RUN yarn install

FROM source as test-runner
WORKDIR /app
RUN yarn run test -- --forceExit --runInBand --watchAll=false

FROM source as builder
WORKDIR /app
RUN yarn run build

FROM nginx:1.22-alpine

COPY --from=builder /app/build /app
COPY --from=builder /localhost.crt /etc/nginx/keys/server.crt
COPY --from=builder /localhost.key /etc/nginx/keys/server.key
COPY --from=test-runner /app/package.json /app/package.json
COPY nginx/nginx.conf.template /etc/nginx/templates/

EXPOSE 8080
EXPOSE 8443

ENV HTTP_PORT=8080
ENV HTTPS_PORT=8443
