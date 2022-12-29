FROM golang:alpine AS builder

ENV CGO_ENABLED 0
ENV GOPROXY https://goproxy.cn,direct

WORKDIR /build
COPY . .
RUN go build -ldflags="-s -w" -o hello hello.go


FROM alpine
WORKDIR /build
COPY --from=builder /build/hello /build/hello
CMD ["./hello"]