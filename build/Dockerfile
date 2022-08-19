

FROM golang:1.18 AS builder

RUN mkdir -p -m 0700 ~/.ssh
RUN ssh-keyscan github.com > /root/.ssh/known_hosts
RUN git config --add --global url."ssh://git@github.com/".insteadOf https://github.com/

WORKDIR /app

ENV GOPRIVATE=github.com/dlpco/*

COPY go.mod .
COPY go.sum .

RUN --mount=type=ssh go mod download

COPY cmd ./cmd
COPY docs ./docs
COPY auto-test-1 ./auto-test-1

ARG BUILD_TIME
ARG GIT_COMMIT
ARG GO_CMD

RUN bash -c 'for var in \
        GO_CMD \
        ; do \
        if test -z "${!var}"; then \
            echo "Please provide build arg [${var}] (--build-arg ${var}=xxx)"; \
            exit 1; \
        fi \
    done'

RUN go build -v -o build/bin \
    -ldflags "-X main.BuildGitCommit=$GIT_COMMIT -X main.BuildTime=$BUILD_TIME" \
    ./cmd/$GO_CMD

FROM ubuntu:20.04 AS runner

RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install locales tzdata openssl ca-certificates -y \
    && /usr/sbin/update-ca-certificates \
    && locale-gen en_US.UTF-8 pt_BR.UTF-8

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 DEBIAN_FRONTEND=noninteractive

# rootless
RUN useradd --create-home --uid 1000 gopher
USER 1000

COPY --from=builder /app/build/bin /bin/

ENTRYPOINT ["/bin/bin"]