# go 的 docker 构建

## 背景

```bash
.
├── go.mod
└── hello.go
```

```go
// hello.go
package main

import "fmt"

func main() {
	fmt.Println("Hello World")
}

```

## v1： 普通构建

### 编写 Dockerfile

```xml
FROM golang:alpine

WORKDIR /build

COPY hello.go .

RUN go build -o hello hello.go

CMD ["./hello"]
```
### 构建
```shell
docker build -t hello:v1 .
docker run -it --rm hello:v1
# Hello World


docker images | grep hello
# hello  v1   c53dd69d5a2a   27 seconds ago   353MB
```

### 问题

>仅仅是1个打印输出，但是镜像竟然有 `353MB`?

看一下具体是大在哪里？

```shell
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
c53dd69d5a2a   11 minutes ago   CMD ["./hello"]                                 0B        buildkit.dockerfile.v0
<missing>      11 minutes ago   RUN /bin/sh -c go build -o hello hello.go # …   2.07MB    buildkit.dockerfile.v0
<missing>      11 minutes ago   COPY hello.go . # buildkit                      72B       buildkit.dockerfile.v0
<missing>      11 minutes ago   WORKDIR /build                                  0B        buildkit.dockerfile.v0
<missing>      3 weeks ago      /bin/sh -c #(nop) WORKDIR /go                   0B        
<missing>      3 weeks ago      /bin/sh -c mkdir -p "$GOPATH/src" "$GOPATH/b…   0B        
<missing>      3 weeks ago      /bin/sh -c #(nop)  ENV PATH=/go/bin:/usr/loc…   0B        
<missing>      3 weeks ago      /bin/sh -c #(nop)  ENV GOPATH=/go               0B        
<missing>      3 weeks ago      /bin/sh -c set -eux;  apk add --no-cache --v…   342MB     
<missing>      3 weeks ago      /bin/sh -c #(nop)  ENV GOLANG_VERSION=1.19.4    0B        
<missing>      3 weeks ago      /bin/sh -c #(nop)  ENV PATH=/usr/local/go/bi…   0B        
<missing>      3 weeks ago      /bin/sh -c apk add --no-cache ca-certificates   622kB     
<missing>      5 weeks ago      /bin/sh -c #(nop)  CMD ["/bin/sh"]              0B        
<missing>      5 weeks ago      /bin/sh -c #(nop) ADD file:685b5edadf1d5bf0a…   7.46MB  
```
重点是这句话：`apk add --no-cache --v…   342MB`，这个命令占据了绝大部分的空间
