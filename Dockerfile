FROM golang:alpine as builder
# To make it even more secure we could use sha256 hash above in FROM

ENV GOPATH=/go
ENV PATH=${GOPATH}/bin:/usr/local/go/bin:$PATH
ENV DELVE_VERSION=1.4.1
ENV GOOS=linux
ENV GOARCH=amd64
#  This will show some "loadinternal: cannot find runtime/cgo", for most part it is fine
ENV CGO_ENABLED=0

ENV APP_NAME="debugger"
ENV APP_PATH=${GOPATH}/src/${APP_NAME}

# installing few dependencies for gomod
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        curl \
        git \
        dpkg \
        gcc \
        git \
        musl-dev

# statically compiling dlv for the debug target
RUN cd /tmp && curl --silent --output delve-${DELVE_VERSION}.tar.gz \
        --location  https://github.com/go-delve/delve/archive/v${DELVE_VERSION}.tar.gz && \
  tar xzf delve-${DELVE_VERSION}.tar.gz && \
  cd delve-${DELVE_VERSION} && \
  go build -o /dlv -ldflags='-w -s -linkmode external -extldflags "-static"' -a ./cmd/dlv/

COPY ./src ${APP_PATH}
WORKDIR ${APP_PATH}

#ENV GO111MODULE=on
#RUN go mod tidy && \
#   go mod download && \
#   go mod verify

# .debug.app: Compile with disable compiler optimization,code function inlining
#    could also disable compressed dwarf; delve doesn't need it though
RUN go build -gcflags "all=-N -l" -ldflags='-linkmode external -extldflags "-static"' -o /${APP_NAME}.debug.app

# .app: Compiling with removing debug information while disabling cross compilation
RUN go build -ldflags='-w -s -linkmode external -extldflags "-static"' -a -o /${APP_NAME}.app

########### DEBUG IMAGE ###################
# https://github.com/GoogleContainerTools/distroless/blob/master/base/README.md
FROM gcr.io/distroless/base:debug as debug

COPY --from=builder /debugger.debug.app /
COPY --from=builder /dlv /

EXPOSE 2345
ENTRYPOINT ["/dlv", "--headless=true", "--listen=:2345", "--api-version=2", "--accept-multiclient", "--log", "exec", "/debugger.debug.app"]

########### PROD IMAGE ###################
FROM gcr.io/distroless/static as prod

# Import the binary
COPY --from=builder /debugger.app /

# Google's distroless uses nobody:nobody
ENTRYPOINT ["/debugger.app"]