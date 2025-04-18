FROM golang:1.23-alpine AS builder

ARG VERSION

WORKDIR /synctv

COPY ./ ./

# 安装必要工具，但移除 g++ 以避免 CGO 依赖
RUN apk add --no-cache bash curl git

# 自定义编译，禁用 CGO 和高级优化
RUN GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -o build/synctv -gcflags="-spectre=off" -ldflags="-w -X github.com/synctv-org/synctv/utils.AppVersion=${VERSION}"

FROM alpine:latest

ENV PUID=0 PGID=0 UMASK=022

COPY --from=builder /synctv/build/synctv /usr/local/bin/synctv

RUN apk add --no-cache bash ca-certificates su-exec tzdata && \
    rm -rf /var/cache/apk/*

COPY script/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    mkdir -p /root/.synctv

WORKDIR /root/.synctv

EXPOSE 8080/tcp

VOLUME [ "/root/.synctv" ]

ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "server" ]
