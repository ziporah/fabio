FROM golang:1.15.12-buster AS build

RUN uname -a
RUN apt-get update && apt-get install -y unzip \
  && rm -rf /var/lib/apt/lists/*

ARG iarch=armhfv6
ARG consul_version=1.9.5
ADD https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_${iarch}.zip /usr/local/bin
RUN cd /usr/local/bin && md5sum  consul_${consul_version}_linux_${iarch}.zip && ls -la consul_${consul_version}_linux_${iarch}.zip && unzip consul_${consul_version}_linux_${iarch}.zip

ARG arch=arm
ARG vault_version=1.7.1
ADD https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_${arch}.zip /usr/local/bin
RUN cd /usr/local/bin && unzip vault_${vault_version}_linux_${arch}.zip
RUN ls -la /usr/local/bin

WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${arch} GOARM=6 go test -mod=vendor -trimpath -ldflags "-s -w" ./...
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${arch} GOARM=6 go build -mod=vendor -trimpath -ldflags "-s -w"

FROM docker.io/alpine:3.13
RUN apk update && apk add --no-cache ca-certificates
COPY --from=build /src/fabio /usr/bin
ADD fabio.properties /etc/fabio/fabio.properties
RUN addgroup -S fabio && adduser -S fabio -G fabio
USER fabio
EXPOSE 9998 9999
ENTRYPOINT ["/usr/bin/fabio"]
CMD ["-cfg", "/etc/fabio/fabio.properties"]
