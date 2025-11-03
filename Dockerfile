### stage: get nats exporter
FROM curlimages/curl:latest AS metrics

WORKDIR /metrics/
USER root
RUN mkdir -p /metrics/
RUN curl -o nats-exporter.tar.gz -L https://github.com/nats-io/prometheus-nats-exporter/releases/download/v0.17.3/prometheus-nats-exporter-v0.17.3-linux-x86_64.tar.gz
RUN tar zxvf nats-exporter.tar.gz

### stage: build flyutil
FROM golang:1.25 AS flyutil
ARG VERSION

WORKDIR /go/src/github.com/fly-apps/nats-cluster
COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -v -buildvcs=false -o /fly/bin/start ./cmd/start

# stage: final image
FROM nats:2.12.1-scratch AS nats-server

FROM debian:bullseye-slim

COPY --from=nats-server /nats-server /usr/local/bin/
COPY --from=metrics /metrics/prometheus-nats-exporter /usr/local/bin/nats-exporter
COPY --from=flyutil /fly/bin/start /usr/local/bin/

CMD ["start"]
