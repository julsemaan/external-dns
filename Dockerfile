FROM golang as prepare
COPY go.mod go.sum /goapp/
WORKDIR /goapp/
RUN go mod download

FROM golang as build
ENV CGO_ENABLED=0
ARG REVISION=${REVISION:-""}
ENV REVISION=${REVISION}
COPY --from=prepare /go/pkg/mod /go/pkg/mod
COPY . /goapp
WORKDIR /goapp/
RUN go mod vendor
RUN go build -o external-dns \
      -mod=vendor \
      -trimpath \
      -ldflags "-X main.gitVersion=$REVISION -X main.buildTime=`TZ=UTC date "+%Y-%m-%dT%H:%MZ"`" \
      -v

FROM ubuntu:22.04
COPY --from=build /goapp/external-dns /external-dns
RUN apt-get update && apt-get install ca-certificates -yqq
ENTRYPOINT ["/external-dns"]

